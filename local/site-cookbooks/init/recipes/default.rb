#
# Cookbook Name:: init
# Recipe:: default
#

# yumの追加リポジトリ
bash "add remi epel" do
  user "root"
  not_if { ::File.exists?("/etc/yum.repos.d/remi.repo") }
  code <<-EOS
    rpm -ivh http://ftp.riken.jp/Linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
  EOS
end

# 適当なパッケージ類のインストール
%w[ vim grep git tree ntp ].each do |pkg|
  package pkg do
    action :install
  end
end

# 時間や言語を日本に設定する(bashなので冪等性確保注意)
# !! カーネルが更新されることでvboxに不具合が…
# bash "add japan" do
#   not_if 'grep "LANG="ja_JP.UTF-8" /etc/sysconfig/i18n'
#   code <<-EOC
#     yum -y groupinstall "Japanese Support"
#     sudo localedef -f UTF-8 -i ja_JP ja_JP.utf8
#   EOC
# end

# 日本時間に変更
bash "chnage time zone" do
  code <<-EOC
    cp /usr/share/zoneinfo/Japan /etc/localtime
  EOC
end

# 言語設定ファイルを置き換え
cookbook_file "i18n_jp" do
  path "/etc/sysconfig/i18n"
  action :create
end

# service登録
service "ntpd" do
  supports :restart => true
  action [ :enable, :start ]
end

# 時間変更した後にcronを再起動しないと時間が反映されない
service 'crond' do
  action :restart
end

# AWS CLIのインストール / 接続設定は都度行うこと
bash 'install AWS CLI' do
  code <<-EOS
    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
    python get-pip.py
    pip install awscli
  EOS
end
