#
# Cookbook Name:: gitlab-server
# Recipe:: default
#
# Copyright 2013, Lucas Christian
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ----------------------------
# Stage 1: Core Package Install
# ----------------------------

# Include make, autoconf, etc.
include_recipe 'build-essential'
include_recipe 'git'

case node['platform']
when "ubuntu","debian"
	packages = %w{ zlib1g-dev libyaml-dev libssl-dev libgdbm-dev 
		libreadline-dev libncurses5-dev libffi-dev curl 
		checkinstall libxml2-dev libxslt-dev 
		libcurl4-openssl-dev libicu-dev postfix }
else
	packages = %w{ zlib-devel libyaml-devel openssl-devel gdbm-devel
		readline-devel ncurses-devel libffi-devel curl libxml2-devel 
		libxslt-devel libcurl-devel libicu-devel }
end

if platform_family?("rhel")
	include_recipe "yum-epel"
end

packages.each do |requirement|
	package requirement
end

# ----------------------------
# Stage 2: Languages
# ----------------------------

# Set up python
include_recipe 'python'

# Set up Ruby
include_recipe 'rvm::system_install'

rvm_environment "ruby-#{node['gitlab']['ruby_version']}@gitlab"

rvm_gem 'bundler' do
	ruby_string "#{node['gitlab']['ruby_version']}@gitlab"
end

rvm_gem 'charlock_holmes' do
	ruby_string "#{node['gitlab']['ruby_version']}@gitlab"
	version '0.6.9.4'
end

# Set up Redis Server
include_recipe 'redisio::install'
include_recipe 'redisio::enable'

# ----------------------------
# Stage 3: Redis (for task queue)
# ----------------------------

# symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
link "/usr/bin/redis-cli" do
	to "/usr/local/bin/redis-cli"
end

# ----------------------------
# Stage 4: System User
# ----------------------------

# GitLab User
group node['gitlab']['system_user']['group']
user node['gitlab']['system_user']['name'] do
	comment 'GitLab'
	group node['gitlab']['system_user']['group']
	home node['gitlab']['system_user']['home_dir']
	shell node['gitlab']['system_user']['shell']
	system true
	supports :manage_home=>true
end

# Configure Git

file "#{node['gitlab']['system_user']['home_dir']}/.gitconfig" do
	user node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	content <<-EOH
[user]
        name = GitLab
        email = gitlab@localhost
EOH
	mode 00664
end

# Set gitlab ruby as default through RVM

file "#{node['gitlab']['system_user']['home_dir']}/.bashrc" do
	user node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	content <<-EOH
source #{node['rvm']['root_path'] + "/environments/" + "ruby-#{node['gitlab']['ruby_version']}@gitlab"}
EOH
	mode 00664
end

# ----------------------------
# Stage 5: Gitlab-Shell
# ----------------------------

# Clone GitLab-Shell
git "#{node['gitlab']['system_user']['home_dir']}/gitlab-shell" do
	repository "https://github.com/gitlabhq/gitlab-shell.git"
	reference node['gitlab']['shell_branch']
	user node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	action :checkout
end

template "#{node['gitlab']['system_user']['home_dir']}/gitlab-shell/config.yml" do
	source "gitlab-shell-config.yml.erb"
	owner node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	mode 00644
end

rvm_shell "gitlab-shell_install" do
	ruby_string "#{node['gitlab']['ruby_version']}@gitlab"
	user 		node['gitlab']['system_user']['name']
	group 		node['gitlab']['system_user']['group']
	cwd         "#{node['gitlab']['system_user']['home_dir']}/gitlab-shell"
	code        %{./bin/install && touch .gitlab-shell-install-done}
	creates     "#{node['gitlab']['system_user']['home_dir']}/gitlab-shell/.gitlab-shell-install-done"
end

# ----------------------------
# Stage 6: Database
# ----------------------------

if node['gitlab']['database']['manage_install']
	# Database install
	include_recipe "mysql::server"
end

if node['gitlab']['database']['manage_database']
	include_recipe "database::mysql"

	database_connection = {
	  :host     => node['gitlab']['database']['hostname'],
	  :port     => node['gitlab']['database']['port'],
	  :username => node['gitlab']['database']['root_user'],
	  :password => node['gitlab']['database']['root_password'].nil? ? 
	               node['mysql']['server_root_password'] : 
	               node['gitlab']['database']['root_password']
	}

	# Create the database
	mysql_database node['gitlab']['database']['database'] do
	  connection      database_connection
	  action          :create
	end

	# Generate a secure password
	if node['gitlab']['database']['password'].nil?
		::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
		node.set['gitlab']['database']['password'] = secure_password
		node.save unless Chef::Config[:solo]
	end

	# Create the database user
	mysql_database_user node['gitlab']['database']['username'] do
		connection      database_connection
		password        node['gitlab']['database']['password']
		database_name   node['gitlab']['database']['database']
		action          [ :create, :grant ]
	end

end

# ----------------------------
# Stage 7: GitLab
# ----------------------------

# Clone GitLab
git "#{node['gitlab']['system_user']['home_dir']}/gitlab" do
	repository "https://github.com/gitlabhq/gitlabhq.git"
	reference node['gitlab']['branch']
	user node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	action :checkout
end

# Create necessary directories
[ "#{node['gitlab']['system_user']['home_dir']}/gitlab/log", "#{node['gitlab']['system_user']['home_dir']}/gitlab/tmp",
	"#{node['gitlab']['system_user']['home_dir']}/gitlab/tmp/pids",
	"#{node['gitlab']['system_user']['home_dir']}/gitlab/tmp/sockets",
	"#{node['gitlab']['system_user']['home_dir']}/gitlab/public/uploads",
	"#{node['gitlab']['system_user']['home_dir']}/gitlab-satellites",
	"#{node['gitlab']['backup']['path']}" ].each do |dir|
	directory dir do
		owner node['gitlab']['system_user']['name']
		group node['gitlab']['system_user']['group']
		mode  00755
	end
end

# Template out config.gitlab.yml and config/puma.rb
template "#{node['gitlab']['system_user']['home_dir']}/gitlab/config/gitlab.yml" do
	source "gitlab.yml.erb"
	owner node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	mode 00644
	notifies :restart, "service[gitlab]"
end

template "#{node['gitlab']['system_user']['home_dir']}/gitlab/config/puma.rb" do
	source "puma.rb.erb"
	owner node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	mode 00644
	notifies :restart, "service[gitlab]"
end

# Template out db config
template "#{node['gitlab']['system_user']['home_dir']}/gitlab/config/database.yml" do
	source "database.yml.erb"
	owner node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	mode 00644
	variables(
		:hostname => node['gitlab']['database']['hostname'],
		:database => node['gitlab']['database']['database'],
		:username => node['gitlab']['database']['username'],
		:password => node['gitlab']['database']['password']
	)
	notifies :restart, "service[gitlab]"
end

# Install gem bundles and init database
rvm_shell "bundle_install" do
	ruby_string "#{node['gitlab']['ruby_version']}@gitlab"
	user 		node['gitlab']['system_user']['name']
	group 		node['gitlab']['system_user']['group']
	cwd         "#{node['gitlab']['system_user']['home_dir']}/gitlab"
	code        %{bundle install --deployment --without development test postgres && touch .bundles-installed}
	creates     "#{node['gitlab']['system_user']['home_dir']}/gitlab/.bundles-installed"
end

# Create user database seeds
 
default_users = [];

if node['gitlab']['admin']['enable']
	default_users.push("#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/001_admin.rb")

	# Override the default admin user seed
	template "#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/001_admin.rb" do
		source "user_seed.rb.erb"
		owner node['gitlab']['system_user']['name']
		group node['gitlab']['system_user']['group']
		mode 00600
		variables(
			:user => { 
				'id' => node['gitlab']['admin']['username'],
				'password' => node['gitlab']['admin']['password'],
				'name' => node['gitlab']['admin']['name'],
				'email' => node['gitlab']['admin']['email'],
				'limit' => 10000,
				'admin' => true
			}
		)
	end
else
	# Remove the default admin seed included with gitlab
	file "#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/001_admin.rb" do
		action :delete
	end
end

case node['gitlab']['default_users']['type']
when 'data bag'

	# Load a secret key if specified
	if !!node['gitlab']['default_users']['secret_file']
		gitlab_secret = Chef::EncryptedDataBagItem.load_secret(node['gitlab']['default_users']['secret_file'])
	end

	# Search the data bag
	search(node['gitlab']['default_users']['name'], '*:*') do |user|	
		user = Chef::EncryptedDataBagItem.load(node['gitlab']['default_users']['name'], user['id'], 
			gitlab_secret) if node['gitlab']['default_users']['encrypted']

		default_users.push("#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/#{user['id']}.rb")

		template "#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/#{user['id']}.rb" do
			source "user_seed.rb.erb"
			mode 00600
			owner node['gitlab']['system_user']['name']
			group node['gitlab']['system_user']['group']
			variables(
				:user => user
			)
		end

	end
when 'json'
	node['gitlab']['default_users']['data'].each do |user|

		default_users.push("#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/#{user['id']}.rb")

		template "#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/#{user['id']}.rb" do
			source "user_seed.rb.erb"
			mode 00600
			owner node['gitlab']['system_user']['name']
			group node['gitlab']['system_user']['group']
			variables(
				:user => user
			)
		end

	end
end

# Remove any users besides the ones listed
Dir.glob("#{node['gitlab']['system_user']['home_dir']}/gitlab/db/fixtures/production/*.rb") do |rb_file|
	next if default_users.include? rb_file
	file rb_file do
		action :delete
	end
end

# Run setup

rvm_shell "gitlab_do_setup" do
	ruby_string "#{node['gitlab']['ruby_version']}@gitlab"
	user node['gitlab']['system_user']['name']
	group node['gitlab']['system_user']['group']
	cwd         "#{node['gitlab']['system_user']['home_dir']}/gitlab"
	code        %{bundle exec rake RAILS_ENV=production gitlab:setup force=yes && touch .db-setup-done}
	creates     "#{node['gitlab']['system_user']['home_dir']}/gitlab/.db-setup-done"
end

# Install init.d script
template "/etc/init.d/gitlab" do
	source "gitlab.init.erb"
	variables( :ruby_string_exact => "ruby-#{node['gitlab']['ruby_version']}@gitlab" )
	mode 00777
end

service "gitlab" do
	supports :status => true, :restart => true, :reload => true
	action [ :enable, :start ]
end

# Schedule backups with cron (if enabled)
if node['gitlab']['backup']['run'] == "manually"
	if ::File.exists?("#{node['gitlab']['system_user']['home_dir']}/gitlab/.backup_scheduled")
		# Delete any existing cron job
		cron "gitlab-backup-cron" do
			action :delete
		end
		file "#{node['gitlab']['system_user']['home_dir']}/gitlab/.backup_scheduled" do
			action :delete
		end
	end
else
	# Create logfiles and set proper perms
	[ "#{node['gitlab']['system_user']['home_dir']}/gitlab/log/backup.stdout.log",
	  "#{node['gitlab']['system_user']['home_dir']}/gitlab/log/backup.stderr.log" ].each do |logfile|
	  	file logfile do
	  		owner node['gitlab']['system_user']['name']
			group node['gitlab']['system_user']['group']
			mode 00644
		end
	end
	# Schedule the cron job
	cron "gitlab-backup-cron" do
		command		"/etc/init.d/gitlab backup 1> #{node['gitlab']['system_user']['home_dir']}/gitlab/log/backup.stdout.log 2> #{node['gitlab']['system_user']['home_dir']}/gitlab/log/backup.stderr.log"
		minute 		node['gitlab']['backup']['run'].split(' ')[0]
		hour		node['gitlab']['backup']['run'].split(' ')[1]
		day			node['gitlab']['backup']['run'].split(' ')[2]
		month		node['gitlab']['backup']['run'].split(' ')[3]
		weekday		node['gitlab']['backup']['run'].split(' ')[4]
	end
	# Create status file
	file "#{node['gitlab']['system_user']['home_dir']}/gitlab/.backup_scheduled" do
		owner node['gitlab']['system_user']['name']
		group node['gitlab']['system_user']['group']
	end
end


# ----------------------------
# Stage 8: Nginx
# ----------------------------

include_recipe "nginx"

# Template out nginx config
template "/etc/nginx/sites-available/gitlab" do
	source "gitlab.nginx.erb"
	notifies :restart, "service[nginx]"
end

# Generate an SSL Cert if necessary
bash "generate-ssl-cert" do
	only_if		{ node['gitlab']['http']['generate_ssl'] }
	not_if		{ node['gitlab']['http']['secure_port'].nil? }
	code <<-EOH
(
echo "US"
echo
echo
echo "Acme Widget Co."
echo "Security Division"
echo "#{node['gitlab']['http']['hostname']}"
echo
echo
echo
)|
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout #{node['gitlab']['http']['ssl_key_path']} -out #{node['gitlab']['http']['ssl_cert_path']}
EOH
	creates 	node['gitlab']['http']['ssl_cert_path']
end

# Enable gitlab site
execute "nginx-enable-gitlab-site" do
	command "nxensite gitlab"
	creates node['nginx']['dir'] + "/sites-enabled/gitlab"
	notifies :restart, "service[nginx]"
end
