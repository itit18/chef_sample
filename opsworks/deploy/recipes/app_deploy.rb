#
# Cookbook Name:: deploy
# Recipe:: app
#
# chef12前提（chef11だと動作が違うので）
#
# アプリケーションのデプロイレシピ
# appがroot/src以下に入っている想定


require 'json'

include_recipe 'php'

# init inventory
inventory_path = node[:deploy][:php][:inventory]
inventory = {}

if File.exist?(inventory_path)
  open(inventory_path) do |io|
    inventory = JSON.load(io)
  end
end

# process for each applications
search(:aws_opsworks_app).each do |app|
  name = app[:shortname]
  
  next unless app[:deploy]
  next unless node[:deploy][:php][:apps].has_key?(name)
  
  puts "Deploy application #{name}"
  
  app_dir = "#{node[:deploy][:php][:root_dir]}/#{name}"
  
  config = node[:deploy][:php][:apps][name]
  source = app[:app_source]
  deploy_user = app[:user] || node[:deploy][:user]
  deploy_group = app[:group] || node[:deploy][:group]
  
  # fetch database config
  database = {}
  
  if !app[:data_sources].empty?
    data_source = app[:data_sources].first
    
    search(:aws_opsworks_rds_db_instance).each do |rds_info|
      if rds_info[:rds_db_instance_arn] == data_source[:arn]
        database['host'] = rds_info['address']
        database['port'] = rds_info['engine'] == 'mysql' ? 3306 : nil
        database['database'] = data_source[:database_name]
        database['username'] = rds_info['db_user']
        database['password'] = rds_info['db_password']
        
        break
      end
    end
  end
  
  # create user
  group deploy_group do
    gid node[:deploy][:gid]
    action :create
  end
  
  user deploy_user do
    gid deploy_group
    uid node[:deploy][:uid]
    action :create
  end
  
  # create base dir
  directory app_dir do
    user deploy_user
    group deploy_group
    recursive true
    action :create
  end
  
  # set up ssh
  ssh_wrapper = nil
  
  if source[:type] == 'git' && source[:ssh_key]
    ssh_wrapper = "#{app_dir}/ssh_wrapper"
    
    deploy_ssh_wrapper name do
      user deploy_user
      group deploy_group
      
      ssh_key source[:ssh_key]
      key_path "#{app_dir}/id_rsa"
      script_path ssh_wrapper
    end
  end
  
  # deploy
  resource_deploy = deploy app_dir do
    user deploy_user
    group deploy_group
    
    repo source[:url]
    branch source[:revision]
    ssh_wrapper ssh_wrapper
    
    params[:deploy_data] = {
      'application' => name,
      'database' => database,
      'user' => deploy_user,
      'group' => deploy_group,
    }
    environment node[:app_param]
    
    notifies :delete, "deploy_ssh_wrapper[#{name}]", :immediate if ssh_wrapper
    
    symlinks.clear
    purge_before_symlink.clear
    create_dirs_before_symlink.clear
    symlink_before_migrate.clear
    
    # currentと紐付ける前にアプリが動く状態にする
    before_migrate do 
      Chef::Log.info("不要なデータを削除してsrc下のデータをroot下に移動")
      Dir::glob("#{release_path}/*").each do |path|
        # Fileクラスはchefのネームスペースと被っているのでグローバル指定が必要
        next if ::File.basename(path) == 'src'
        Chef::Log.info(" delete to #{path}")
        bash "delete dir" do
          code "rm -rf #{path}"
        end
      end
      # src以下の内容を引き上げる
      bash 'copy app for root' do
        code <<-EOH
          cd #{release_path}
          cp -af ./app_name/* ./
          rm -rf ./app_name
        EOH
      end

      Chef::Log.info("composer実行")
      deploy = new_resource.params[:deploy_data]
      environment = node[:app_param]
      database = deploy["database"]
      bash 'composer install' do
        code <<-EOH
        composer install --no-dev --optimize-autoloader
        EOH
        cwd release_path
      end
      
      Chef::Log.info("権限ユーザー/グループを変更")
      bash 'chown app' do
        code <<-EOH
          cd #{release_path}
          chown -R #{deploy['user']}:#{deploy['user']} ./*
        EOH
      end

      Chef::Log.info("logディレクトリをsymlinkに変更")
      release_log_dir = "#{release_path}/app/logs"
      shared_log_dir  = "#{app_dir}/shared/app/logs"
      bash 'remove log dir' do
        code <<-EOH
          rm -rf #{release_log_dir}
        EOH
      end
      directory shared_log_dir do
        group     deploy['user']
        owner     deploy['user']
        mode      0774
        recursive true
        action    :create
      end

      link release_log_dir do
        to     shared_log_dir
        group  deploy['user']
        owner  deploy['user']
        action :create
      end

      Chef::Log.info(" 環境変数の設定を書き込んだ設定ファイルを出力")
      template 'set env file' do
        source 'app_name.erb'
        path "/etc/profile.d/app_name.sh"
        mode '0644'
        variables({
          environment: environment
          })
      end
    end
  end
  
  # enable http containers if required
  if config[:enable_http]
    document_root = "#{app_dir}/current/#{app[:attributes][:document_root]}"
    socket_path = "#{app_dir}.sock"
    
    # php-fpm
    php_fpm_pool name do
      user deploy_user
      group deploy_group
      
      listen socket_path
      listen_user node[:nginx][:user]
      listen_group node[:nginx][:group]
      
      chdir "#{document_root}"
      action :install
    end
    
    service node['php']['fpm_service'] do
      action :nothing
    end
    
    resource_deploy.notifies(:restart, "service[#{node['php']['fpm_service']}]")
    
    # nginx
    include_recipe 'nginx'
    
    nginx_site name do
      template 'php/nginx.erb'
      variables({
        :name => name,
        :app_dir => app_dir,
        :fastcgi_pass => "unix:#{socket_path}",
        :document_root => document_root,
        :app => app,
        :environment => node[:app_param],
        :config => config,
      })
    end
    
    resource_deploy.notifies(:restart, 'service[nginx]')
    
    source_application name do
      template 'php/fluentd_source.conf.erb'
    end
  end
  
  # add to inventory
  inventory[name] = {
    :dir => app_dir,
    :config => config,
  }
end

# save inventory
if !inventory.empty?
  directory File.dirname(inventory_path) do
    recursive true
  end

  file inventory_path do
    content JSON.generate(inventory)
  end
end

