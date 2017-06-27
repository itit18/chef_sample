#
# Cookbook Name:: rbenv
# Recipe:: default
#
#

user = node["user"]
version = node["version"]
rbenv_dir = "/usr/local/rbenv"

# rubyにmysqlライブラリをインストールする際に必要
package 'mysql-devel' do
  action :install
end

git rbenv_dir do
  repository "https://github.com/sstephenson/rbenv.git"
  revision   "master"
  user       user
  group      user
  action     :export
end

directory rbenv_dir do
  owner  user
  group  user
  action :create
end

directory "#{rbenv_dir}/plugins" do
  owner  user
  group  user
  action :create
end

git "#{rbenv_dir}/plugins/ruby-build" do
  repository "https://github.com/sstephenson/ruby-build.git"
  revision   "master"
  user       user
  group      user
  action     :sync
end

bash "add profile" do
  
  code <<-EOC
echo '# add rbenv' >> /etc/profile
echo 'export RBENV_ROOT="/usr/local/rbenv"' >> /etc/profile
echo 'export PATH="${RBENV_ROOT}/bin:${PATH}"' >> /etc/profile
echo 'eval "$(rbenv init -)"' >> /etc/profile
EOC
  
  not_if 'grep "rbenv" /etc/profile'
end

# rubyインストールに必要なライブラリ
pkg_hash = %w[ntp curl curl-devel gcc gcc-c++ git openssl-devel httpd-devel readline-devel libX11-devel make zlib-devel libffi-devel ]
pkg_hash.each do |pkg|
  package pkg do
    action :install
  end
end



#普通にコマンド打つと環境変数が変更されていてrbenvが見つからないのでprofile再読み込みを挟む
bash "rbenv install #{version}" do
  user   user
  cwd    "#{node["script_dir"]}"
  code   "source /etc/profile; rbenv install #{version}"
  action :run
  not_if { ::File.exists? "#{rbenv_dir}/versions/#{version}" }
end

bash "rbenv rehash" do
  user   user
  cwd    "#{node["script_dir"]}"
  code   "source /etc/profile; rbenv rehash"
  action :run
end

bash "rbenv global #{version}" do
  user   user
  cwd    "#{node["script_dir"]}"
  code   "source /etc/profile; rbenv global #{version}"
  action :run
end

# globalで使うgemを追加
%w[bundler].each do |lib|
  bash lib do
    user   user
    cwd    "#{node["script_dir"]}"
    code   "source /etc/profile; gem install #{lib}"
    action :run
    not_if { ::File.exists? "#{rbenv_dir}/shims/#{lib}" }
  end
end
