#
# Cookbook Name:: nodejs
# Recipe:: default
#

%w[nodejs npm].each do |pkg|
  package pkg do
    options '--enablerepo=epel'
    action :install
  end
end

# npmの初期設定アップ
bash 'npm setup' do
  code <<-EOH
    npm install -g n
    n latest
    npm update -g npm
  EOH
  user 'root'
end

