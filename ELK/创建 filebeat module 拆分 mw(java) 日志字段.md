配置 es 索引

> 区分同一系统中，不同应用的日志

```
index: "uat-%{[event.module]}-%{[fileset.name]}-%{+yyyy.MM.dd}"
```

在目录 /etc/filebeat/modules.d 中创建模块文件 mw.yml

```
- module: mw
  lfl:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    var.paths: ["/tmp/mw-lfl.log"]

  # Error logs
  fom:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    var.paths: ["/tmp/mw-fom.log"]
```

在目录 /usr/share/filebeat/module 创建模块目录 mw

```
cd /usr/share/filebeat/module
cp -R nginx mw
cd mw
mv access lfl
```

修改文件 lfl/ingest/default.json

> \\s*% : 匹配一个或多个空格，INFO 日志此处有两个空格，ERROR 日志只有一个。
>
> [^\\]]* : 匹配由任意字符组成的字符串。

```
{
    "description": "Pipeline for parsing java mw logs.",
    "processors": [
        {
            "grok": {
                "field": "message",
                "patterns": ["%{TIMESTAMP_ISO8601:log.time} %{LOGLEVEL:log.level}\\s*%{JAVACLASS:java.class} %{NUMBER:number} %{DATA:cmd} - %{COMPONENT:component}"],
                "ignore_missing": true,
                "pattern_definitions": {
                     "COMPONENT": "[^\\]]*"
                }
            }
        },
        {
            "date": {
                "field": "log.time",
                "target_field": "@timestamp",
                "formats": ["yyyy-MM-dd HH:mm:ss.SSS"],
                "ignore_failure": true,
                "timezone": "Asia/Shanghai"
            }
        }
    ],
    "on_failure": [
        {
            "set": {
                "field": "error.message",
                "value": "{{ _ingest.on_failure_message }}"
            }
        }
    ]
}
```

日志格式

```
2022-09-21 13:04:18.046 INFO  com.fom.push.PushProduct 198 pushData - {"error_response":{"code":"0","msg":"success"}}
2022-09-21 16:10:02.893 ERROR com.fom.push.PushFailOrder 84 handleData - java.lang.NullPointerException: Cannot invoke "com.alibaba.fastjson.JSONObject.getJSONObject(String)" because "result" is null
```



**注意**

kafka/log/config/log.yml 文件中的一下目录是进行多行匹配的

> 多行匹配以 '[' 开头的行

```
multiline:
  pattern: '^\['
  negate: true
  match: after
```

