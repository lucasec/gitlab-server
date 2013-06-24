name             'gitlab-server'
maintainer       'Lucas Christian'
maintainer_email 'lucas@lucasec.com'
license          'Apache 2.0'
description      'Installs/Configures a Gitlab server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'
%w{ redisio openssl rvm python git build-essential database mysql nginx yum }.each do |dependency|
  depends dependency
end
