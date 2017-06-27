#
# Cookbook Name:: php
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#php5.5インストール
%w[php php-common php-mcrypt php-mbstring php-pdo php-mysqlnd php-imap php-xml php-pecl-xdebug].each do |pkg|
  package pkg do
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

#composerのインストール

bash "composer install" do
  code <<-EOH
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin
    ln -s /usr/local/bin/composer.phar /usr/local/bin/composer
  EOH
  user "root"
  not_if { ::File.exists?("/usr/local/bin/composer.phar") }
end

service "httpd" do
  action :restart
end
