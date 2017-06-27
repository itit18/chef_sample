#
# Cookbook Name:: apache2
# Attributes:: apache
#

default["ServerName"] = "127.0.0.1"

default["vhost"]["name"] = "*"
default["vhost"]["port"] = "80"
default["vhost"]["DocumentRoot"] = "/var/app/current"
default["vhost"]["ServerName"] = "127.0.0.1"
default["vhost"]["ErrorLog"] = "/var/log/httpd/vhost_error_log"
default["vhost"]["CustomLog"] = "logs/vhost.common-access_log common"
