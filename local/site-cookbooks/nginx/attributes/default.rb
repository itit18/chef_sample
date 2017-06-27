#
# Cookbook Name:: nginx
#

default["root"] = "/var/app/current"
default["index"] = "app.php"
default["socket_path"] = "/var/run/php-fpm/php-fpm.sock"
