#
# Cookbook Name:: deploy
# Recipe:: sub
#
# chef12前提（chef11だと動作が違うので）
#
# OpsWorksのdeployインベントで処理したいとき用
# 本体のdeployレシピと切り離して有るためcurrentに切り替わったあとに動作します
#

# process for each applications
search(:aws_opsworks_app).each do |app|
  # 実行対象レイヤーかをチェック
  name = app[:shortname]
  next unless app[:deploy]
  next unless node[:deploy][:php][:apps].has_key?(name)
  
  cron_enable = false
  php = node[:deploy][:php]
  next unless cron_enable
  
  # 変数を設定
  environment = node[:app_param]
  deploy_user = app[:user] || node[:deploy][:user]
  deploy_group = app[:group] || node[:deploy][:group]
  current_path =  node[:deploy][:php][:root_dir] + '/' + app[:shortname] + '/current'
  
  Chef::Log.info("execute hogehoge...")

  # 実行したい処理をこの下に記載する
end
