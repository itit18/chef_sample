#
# Cookbook Name::php-fpm
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

[
"php",
"php-fpm",
"php-devel",
"php-bcmath",
"php-cli",
"php-common",
"php-dba",
"php-dbg",
"php-gd",
"php-intl",
"php-ldap",
"php-mbstring",
"php-mcrypt",
"php-mysqlnd",
"php-pdo",
"php-pecl-igbinary",
"php-pecl-memcache",
"php-pecl-memcached",
"php-pecl-oauth",
"php-pecl-ssh2",
"php-pecl-redis",
"php-process",
"php-soap",
"php-xml",
"php-xmlrpc",
# "uuid-php"
].each do |p|
  package p do
    options '--enablerepo=epel,remi-php56'
    action :install
  end
end

template 'php56.ini' do
  path '/etc/php.ini'
  owner 'root'
  group 'root'
  mode 0644
end

# install composer

bash "composer install" do
  user 'root'
  not_if { ::File.exists?("/usr/local/bin/composer.phar") }
  code <<-EOH
    curl -sS 'https://getcomposer.org/installer' | php -- --install-dir=/usr/local/bin
    ln -s /usr/local/bin/composer.phar /usr/local/bin/composer
  EOH
  notifies :run, "bash[composer install]"
end

bash "composer install" do
  action :nothing
end

# setup php-fpm

service "php-fpm" do
  supports start: true
  action :enable
end


template 'www.conf' do
  path '/etc/php-fpm.d/www.conf'
  source 'www.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :restart, "service[php-fpm]"
end
