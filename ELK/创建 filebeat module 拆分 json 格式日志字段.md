配置 es 索引

> 区分同一系统中，不同应用的日志

```
index: "uat-%{[event.module]}-%{[fileset.name]}-%{+yyyy.MM.dd}"
```

在目录 /etc/filebeat/modules.d 中创建模块文件 mw.yml

```
- module: mw
  nginx:
    enabled: true
    var.paths: ["/tmp/mw-nginx.log"]
```

在目录 /usr/share/filebeat/module 创建模块目录 mw

```
cd /usr/share/filebeat/module
cp -R nginx mw
cd mw
mv access nginx
```

修改文件 nginx/ingest/default.json

```
{
  "description": "Pipeline for json logs",
  "processors": [
    {
      "json" : {
        "field": "message",
        "target_field": "log"
      }
    },
    {
        "geoip": {
            "field": "log.remote_addr",
            "target_field": "source.geo",
            "ignore_missing": true
        }
    }
  ],
  "on_failure" : [{ 
    "set" : { 
      "field" : "error.message", 
      "value" : "pipeline-json: {{ _ingest.on_failure_message }}" 
    } 
  }]
}
```

日志格式

```
{"@timestamp": "2022-09-22T11:33:05+08:00", "remote_addr": "192.168.1.1","costime": "1.799","realtime": "1.799","status": 200,"x_forwarded": "","referer": "","request": "POST / HTTP/1.1","content-type": "application/x-www-form-urlencoded; charset=UTF-8","upstr_addr": "127.0.0.1:9090","bytes":44,"dm":"method=fom_trade_send&request_time=20220922103303&app_key=HK_API_Real_Time&format=json&sign=2e53ce142edae3c0d0af6865e78d884f&data=eyJ0aWQiOiIyMjA5MjJFUkU4VzVLSiIsInNlbGxlcl9uaWNrIjoiU2hvcGVlU2tlY2hlcnNUaGFpbGFuZFx1NWU5NyIsInNpZCI6IjIyMDkyMkVSRThXNUtKIiwiY29tcGFueV9jb2RlIjoiSiZUIEV4cHJlc3MiLCJsb2NhdGlvbl9pZCI6IkJEQzAyIiwic3ViX3RpZCI6IjIyMDkyMkVSRThXNUtKMTYzNTY4MDIxNjU2In0=","agent": ""}
```

