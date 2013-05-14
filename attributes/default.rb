#
# Cookbook Name:: gitlab-server
# Attributes:: default
#
# Copyright 2013, Lucas Christian
#
# All rights reserved - Do Not Redistribute
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

# [--- WEB SERVER ---]

	default['gitlab']['http']['hostname'] = "localhost"
	default['gitlab']['http']['path'] = "/"
	default['gitlab']['http']['port'] = "80"
	default['gitlab']['http']['secure_port'] = nil
	default['gitlab']['http']['force_https'] = false

	default['gitlab']['http']['generate_ssl'] = true
	default['gitlab']['http']['ssl_cert_path'] = "/etc/ssl/certs/gitlab.crt"
	default['gitlab']['http']['ssl_key_path'] = "/etc/ssl/private/gitlab.key"

# [--- DATABASE ---]

	# Automatic Configuration Management
	default['gitlab']['database']['manage-install'] = true	# Install MySQL
	default['gitlab']['database']['manage-database'] = true	# Create Database

	# Database Connection
	default['gitlab']['database']['hostname'] = "localhost"
	default['gitlab']['database']['database'] = "gitlabhq_production"
	default['gitlab']['database']['username'] = "gitlab"

	# Database Root Password (only needed if using manage-database
	# without manage-install)
	# default['gitlab']['database']['root-password'] = "gitlab"

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

	# GitLab can create other users from an encrypted data bag as well
	# when using this feature, you may want to turn off the default admin
	default['gitlab']['create_users'] = true


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

