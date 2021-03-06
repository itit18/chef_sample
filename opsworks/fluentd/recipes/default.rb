#
# Cookbook Name:: fluentd
# Recipe:: default
#

# fluentdのインストール
bash 'td-agent install' do
  code <<-EOH
    curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh
  EOH
  user 'root'
end

template 'td-agent.conf' do
  path '/etc/td-agent/td-agent.conf'
  source 'td-agent_server.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
end

service "td-agent" do
  action :restart
end