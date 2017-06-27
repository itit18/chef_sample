#
# Cookbook Name:: golang
# Recipe:: default
#

package 'golang' do
  options '--enablerepo=epel'
  action :install
end

# golang関連の環境変数設定指定
bash_profile = '/home/vagrant/.bash_profile'
bash 'add path bash_profile' do
  code <<-EOH
    echo export GOROOT=/usr/lib/golang >> #{bash_profile}
    echo export GOPATH=#{node['gopath']} >> #{bash_profile}
    echo export PATH=$PATH:$GOROOT/bin:$GOPATH/bin >> #{bash_profile}
  EOH
  not_if "grep 'GOROOT' #{bash_profile} "
  user 'root'
end

