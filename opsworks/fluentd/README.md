# fluentdの設定

custom jsonを読み込んで設定ファイルを作成します。  
下記jsonのサンプルです。

```
{
  "fluentd": {
    "name" : "log",
    "port" : "25220",
    "main_host" : "log-main",
    "standby_host" :"log-standby",
    "matchs": [
      {
        "path" : "/var/log/td-agent/app/hoge.log",
        "tag" : "hoge"
      }
    ],
    "sources": [
      {
        "path" : "/srv/www/app_path/log/general.log",
        "tag" : "hoge",
        "format" : "none",
        "time_key": "",
        "time_format": ""
      }
    ]
  }
}
```

# レシピ

logを集積する側（受信側）は、defaultレシピを実行する。  
logを送信する側はclientレシピを実行する

