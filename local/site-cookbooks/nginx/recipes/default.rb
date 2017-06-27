#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

package 'nginx' do
  action :install
end

template 'conf' do
  source 'default.conf.erb'
  path '/etc/nginx/conf.d/default.conf'
  owner 'root'
  group 'root'
  mode 0644
end

service 'nginx' do
  action [ :enable, :start ]
end