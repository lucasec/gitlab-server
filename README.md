GitLab-Server Cookbook
======================

Need a GitLab installation?  This cookbook has you covered.

### Features:

- Tested on Debian/Ubuntu and Amazon, should support others
- Full installation including all necessary dependencies
- Set up default users using attributes or an encrypted data bag
- Easily customize http ports, ssl, database (use your own or let us install MySQL for you), paths, …

Installation
------------

### From GitHub Repo

1. Download the cookbook (`git clone git@github.com:lucasec/gitlab-server.git`)
2. Enter the cookbook directory (`cd gitlab-server`)
2. Run `berks install` to gather dependencies
3. Run `berks upload` to upload to your chef-server.  We do support chef-solo, no worries!

### From Opscode Community Site

1. Download the cookbook (`knife cookbook site install gitlab-server`)
2. Download the RVM cookbook (`git clone git@github.com:fnichol/chef-rvm.git`)
3. Upload the cookbook and dependencies to your server

Note that the Opscode Site version does not contain Vagrant and Berkshelf configurations. If you prefer the Vagrant/Berkshelf workflow, download the cookbook from its [official repository](https://github.com/lucasec/gitlab-server).

Usage
-----

We've tried to make this remarkably simple.

For a basic install, just add `recipe[gitlab-server]` to your run list.

Of course, you'll probably want to take a look at the various attributes that you can customize.  Jump in by loking at `attributes/default.rb`, which is well commented, or read the long form below.

Attributes
----------

### Web Server

#### Enable SSL (development)
1. Enable the HTTPS server: `node['gitlab']['http']['secure_port'] = 443`
2. Let us generate a self-signed SSL for you.
3. Force-redirect to https: `node['gitlab']['http']['force_https'] = true`

#### Enable SSL (production)
1. Enable the HTTPS server: `node['gitlab']['http']['secure_port'] = 443`
2. Use a method of your preference to install your SSL certs on the server.
3. Point `node['gitlab']['http']['ssl_cert_path']` to your certificate and `node['gitlab']['http']['ssl_key_path']` to your private key.
3. Force-redirect to https: `node['gitlab']['http']['force_https'] = true`

#### Full set of HTTP attributes and their defaults
- `node['gitlab']['http']['hostname'] = (fqdn)` - Your server's fully qualified domain name
- `node['gitlab']['http']['path'] = "/)"` - Relative URL base, for example, specify "/gitlab" and your home page will be "http://your-domain/gitlab/"
- `node['gitlab']['http']['port'] = "80"` - Bare HTTP port, set to nil to disable (i.e. you only want to run https on an obscure port)
- `node['gitlab']['http']['secure_port'] = nil` - Secure HTTPS port, set this to enable SSL
- `node['gitlab']['http']['force_https'] = false` - Immediately redirect bare HTTP requests to HTTPS
- `node['gitlab']['http']['generate_ssl'] = true` - Generate a self-signed SSL certificate if none exists
- `node['gitlab']['http']['ssl_cert_path'] = "/etc/ssl/certs/gitlab.crt"` - Path to SSL cert
- `node['gitlab']['http']['ssl_key_path'] = "/etc/ssl/private/gitlab.key"` - Path to SSL private key

### Database

GitLab uses the MySQL recipe to automatically install a database for you. If you've already got a database, you probably want to override this.

#### Use your own database server

You can use your own MySQL installation on another server, but still let us create a database and user for you.

1. Tell GitLab-Server not to install MySQL for you: `node['gitlab']['database']['manage_install'] = false`
2. Tell GitLab-Server your database host and root (or any user that can create databases) password:
	- `node['gitlab']['database']['hostname'] = "[your hostname]"`
	- Override `node['gitlab']['database']['port']` if necessary
	- Override `node['gitlab']['database']['root_user']` if your user is not named 'root'
	- `node['gitlab']['database']['root_password'] = "[your database root password]"`
3. Customize the name of the database and user the cookbook will create:
	- `node['gitlab']['database']['database'] = "gitlabhq_production"`
	- `node['gitlab']['database']['username'] = "gitlab"`

#### Use an existing database on your own server

1. Tell GitLab-Server not to install MySQL for you: `node['gitlab']['database']['manage_install'] = false`.
2. Tell GitLab-Server not to create a database for you: `node['gitlab']['database']['manage_database'] = false`.
2. Tell GitLab-Server your database host:
	- `node['gitlab']['database']['hostname'] = "[your hostname]"`
	- Override `node['gitlab']['database']['port']` if necessary
3. Provide us the database name and a user with permission to it:
	- `node['gitlab']['database']['database'] = "[database name]"`
	- `node['gitlab']['database']['username'] = "[username]"`
	- `node['gitlab']['database']['password'] = "[password]"`

### App Settings

#### Email Addresses
- `node['gitlab']['app']['system_email']` - System email address (notifications come from this)
- `node['gitlab']['app']['support_email']` - Support email address displayed to users

#### Default Users

We offer a lot of ways to set up default users.

##### Default Admin User:
- `node['gitlab']['admin']['enable'] = true` - Disable if you don't want a default admin created (i.e. you're using one of the more flexible methods below)
- `node['gitlab']['admin']['username'] = "root"` - Username
- `node['gitlab']['admin']['name'] = "Administrator"` - Full name
- `node['gitlab']['admin']['email'] = "admin@local.host"` - Email Address
- `node['gitlab']['admin']['password'] = "5iveL!fe"` - Password

##### Using Default User Providers

GitLab-Server can create users from several sources.  These users are only used when initializing the database—they cannot be used to add users after the fact.

Basic format for the User object:

    {
      "id": "lucas",
      "name": "Lucas Christian",
      "email": "lucas@lucasec.com",
      "password": "SuperSecurePassword",
      "admin": true,
      "limit": 100,
      "keys": [
        { "title": "[ssh key name here]", "key": "[paste ssh key here]" },
        { "title": "[ssh key name 2 here]", "key": "[paste ssh key 2 here]" }
      ]
    }
 

###### Encrypted Data Bag (best)

Encrypted Data Bags allow you to securely store a set of default usernames, passwords, and even SSH Keys!

To get started, set the following attribute and then follow the steps below to create your data bag: `node['gitlab']['default_users'] = {:type => "data bag", :name => "gitlab_users", :encrypted => true}`

EDB Quick Start:

1. Change to your chef_repo/.chef directory.
2. Generate a secret key `openssl rand -base64 512 > encrypted_data_bag_secret`
3. Tell knife.rb about your secret so it will push it out during bootstraps: `echo "encrypted_data_bag_secret '.chef/encrypted_data_bag_scret'" > knife.rb`
4. Make your first user: `knife data bag create gitlab_users [new username here] --secret-file=encrypted_data_bag_secret`
5. Enter the user's info into your text editor (see the format spec above), save, and close
6. Done!  Start at step 4 to add additional users.

You can customize this behavior a bit:

- Use a different data bag name: `node['gitlab']['default_users'] = {:type => "data bag", :name => "[data bag name here]", :encrypted => true}`
- Use a non-default encryption key: `{:type => "data bag", :name => "data bag name", :encrypted => true, :secret_file => "path-to-secret-key"}`

###### Regular Data Bag

You can use a regular (non-encrypted) data bag as well.  Just set `:encrypted => false`.

###### JSON Attribute

You can also provide an array of default users in the attributes.  This approach can be used with chef-solo.

Here's how: `node['gitlab']['default_users'] = {:type => "json", :data => [array of users (see format above)]}`

### System Settings

#### Repository Path

You can specify a custom directory for the repositories folder.  This may be useful if you want to store the folder on a separate volume.

- `node['gitlab']['app']['repo_path'] = "(home dir)/repositories"` - Repository folder.  This folder will be created if it does not exist, and permissions will be adjusted automatically.

#### Automatic Backups

GitLab-Server can run automatic backups for you using cron.

Backups are configured by default to be saved in `(home dir)/backups` and kept for 30 days.  Of course, you can change this.

- `node['gitlab']['backup']['path'] = "(home dir)/backups"` - The folder that GitLab will store backups in.
-  `node['gitlab']['backup']['keep_for'] = '30d'` - How long backups should be kept.  Use this friendly syntax: `10d 12h 5m` would run backups every 10 days, 12 hours, and 5 minutes.  No calculator necessary.

Backups can be run at any time by running `service gitlab backup` as root.  You can also schedule this using cron.

- `node['gitlab']['backup']['run'] = "manually"` - Specify when the backup should run.  This can either be set to "manually" or a crontab-style time string (min hour day month weekday).  For example, `0 0 * * *` will run the job daily (at the zero hour and zero minute).

#### System User

You can configure the system user that GitLab runs under.  Chef will make this user if it does not exist.

- `node['gitlab']['system_user']['name'] = "git"` - System user name
- `node['gitlab']['system_user']['group'] = "git"` - System group used for all GitLab files and the user
- `node['gitlab']['system_user']['home_dir'] = "(platform specific)"` - Home Directory path
- `node['gitlab']['system_user']['shell'] = "(platform specific)"` - Shell executable

### Versions

You can change the versions of ruby, gitlab, and gitlab-shell installed by the cookbook.  As long as the installation process does not change, you can update to newer versions of Gitlab independently from this cookbook.

- `node['gitlab']['ruby_version']` - Ruby version to use (in an RVM string)
- `node['gitlab']['branch']` - Branch from the main Gitlab repository to use
- `node['gitlab']['shell_branch']` - Branch of Gitlab-Shell to use

Notes
-----

GitLab-Server uses the Nginx cookbook.  By default, it will create its own site and *disable the default site*.  If you want to override this behavior, just sepcify `node['nginx']['default_site_enabled'] = true`.

Build-essential is set to run at complie time in order to satisfy the MySQL cookbook.  If your attributes override this, the run may fail.

### Chef-Solo Usage

GitLab-Server works fine with Chef-Solo, except the recipe cannot use automatic password generation when setting up a database for you. Make sure you give us a password in your JSON:

    {
      "gitlab": {
        "database": {
          "password": "[your secure password here]"
        }
      }
    }

Roadmap
-------

We've got a few features planned:

- Spliting main recipe into smaller recipes
- GitLab CI recipe

License and Authors
-----------------

Copyright 2013, Lucas Christian

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
