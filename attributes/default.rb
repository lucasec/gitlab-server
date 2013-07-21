#
# Cookbook Name:: gitlab-server
# Attributes:: default
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
# Requirements for other cookbooks
# ----------------------------

	# Required because mysql cookbook builds native extensions at compiletime
	default['build_essential']['compiletime'] = true	# DO NOT CHANGE

	# The default site can conflict with the gitlab site
	default['nginx']['default_site_enabled'] = false


# ----------------------------
# Essentials
# ----------------------------

# [--- VERSIONS ---]

	default['gitlab']['branch'] = '5-3-stable'
	default['gitlab']['shell_branch'] = 'master'
	default['gitlab']['ruby_version'] = '1.9.3-p429'

# [--- WEB SERVER ---]

	default['gitlab']['http']['hostname'] = fqdn
	default['gitlab']['http']['path'] = "/"
	default['gitlab']['http']['port'] = "80"
	default['gitlab']['http']['secure_port'] = nil
	default['gitlab']['http']['force_https'] = false

	default['gitlab']['http']['generate_ssl'] = true
	default['gitlab']['http']['ssl_cert_path'] = "/etc/ssl/certs/gitlab.crt"
	default['gitlab']['http']['ssl_key_path'] = "/etc/ssl/private/gitlab.key"

# [--- DATABASE ---]

	# Automatic Configuration Management
	default['gitlab']['database']['manage_install'] = true	# Install MySQL
	default['gitlab']['database']['manage_database'] = true	# Create Database

	# Database Connection
	default['gitlab']['database']['hostname'] = "localhost"
	default['gitlab']['database']['port'] = 3306
	default['gitlab']['database']['database'] = "gitlabhq_production"
	default['gitlab']['database']['username'] = "gitlab"

	# Database Root User (used with manage_database)
	default['gitlab']['database']['root_user'] = "root"

	# Database Root Password (only needed if using manage_database
	# without manage_install)
	# default['gitlab']['database']['root_password'] = "gitlab"

	# Database User Password (if not specified, will be generated)
	# default['gitlab']['database']['password'] = "gitlab"

# [--- APPLICATION ---]

	# Email
	default['gitlab']['app']['system_email'] = "gitlab@localhost"
	default['gitlab']['app']['support_email'] = "support@localhost"

# [--- APP USERS ---]

	# Default Admin User
	default['gitlab']['admin']['enable'] = true
	default['gitlab']['admin']['username'] = "root"
	default['gitlab']['admin']['name'] = "Administrator"
	default['gitlab']['admin']['email'] = "admin@local.host"
	default['gitlab']['admin']['password'] = "5iveL!fe"

	# GitLab can create other default users from a variety of sources
	default['gitlab']['default_users'] = {:type => "none"}

	# Default User Providers
	# none provider:	{:type => "none" }
	# json provider:	{:type => "json", :data => []}
	# databag provider	{:type => "data bag", :name => "data bag name"}
	# 					{:type => "data bag", :name => "data bag name", :encrypted => true}
	# 	more options..	{:type => "data bag", :name => "data bag name", :encrypted => true,
	# 					 :secret_file => "path-to-secret-key"}


# ----------------------------
# Further Customization
# ----------------------------

# [--- SYSTEM USER ---]

	# System User Account
	default['gitlab']['system_user']['name'] = "git"
	default['gitlab']['system_user']['group'] = "git"

	# Platform-specific properties
	case platform
	when 'debian','ubuntu','redhat','centos','amazon','scientific','fedora','freebsd','suse'
		default['gitlab']['system_user']['home_dir'] = "/home/git"
		default['gitlab']['system_user']['shell'] = "/bin/bash"
	when 'openbsd'
		default['gitlab']['system_user']['home_dir'] = "/home/git"
		default['gitlab']['system_user']['shell'] = "/bin/ksh"
	when 'mac_os_x', 'mac_os_x_server'
		default['gitlab']['system_user']['home_dir'] = "/Users/Git"
		default['gitlab']['system_user']['shell'] = "/bin/bash"
	else
		default['gitlab']['system_user']['home_dir'] = "/home/git"
		default['gitlab']['system_user']['shell'] = nil
	end

# [--- REPO PATH ---]

	# Repository directory
	default['gitlab']['app']['repo_path'] = "#{node['gitlab']['system_user']['home_dir']}/repositories"

# [--- BACKUPS ---]

	# Path in which to store backups
	default['gitlab']['backup']['path'] = "#{node['gitlab']['system_user']['home_dir']}/backups"

	# How long should the backups be kept?  Spceify a relative time string (i.e. "30d 5h" for 30 days and 5 hours)
	# You can also specify "forever"
	default['gitlab']['backup']['keep_for'] = "30d"

	# When should the backup run?
	# Specify "manually" or a cron string (min hour day month weekday)
	default['gitlab']['backup']['run'] = "manually"

