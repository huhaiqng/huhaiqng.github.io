**说明：**

alloy: 收集日志	loki: 存储查询日志	grafana: 展示日志UI



**添加 yum 源 `/etc/yum.repos.d/grafana.repo`**

```
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=0
enabled=1
gpgcheck=0
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=0
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
```

**安装**

```
yum install -y grafana loki alloy
```

**注释 loki 配置文件`/etc/loki/config.yml`中的以下内容**

> 不注释无法启动

```
pattern_ingester:
  enabled: true
  metric_aggregation:
    enabled: true
    loki_address: localhost:3100
```

**在 alloy 配置文件`/etc/alloy/config.alloy`中添加以下内容**

```
// applogs
local.file_match "applogs" {
    path_targets = [{"__path__" = "/tmp/app-logs/*.log", node_name = sys.env("HOSTNAME")}]
}

loki.source.file "applogs" {
    targets    = local.file_match.applogs.targets
    forward_to = [loki.process.applogs.receiver]
}

loki.process "applogs" {
    forward_to = [loki.write.default.receiver]

    // 匹配以 [lfl 开头的多行日志
    stage.multiline {
        firstline     = "^\\[lfl"
        max_wait_time = "5s"
    }

    // 拆分日志
    stage.regex {
    // expression = "(?P<time>\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}.\\d{3})"
    	expression = "\\[(?P<service_name>[^:]+):(?P<ip>[^:]+):(?P<port>[^\\]]+)\\] \\[(?P<id>\\d+)\\] (?P<time>\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3})"
    }

    // 将日志收集时间改为日志时间
    stage.timestamp {
        source = "time"
        format = "2006-01-02 15:04:05"
        location = "Asia/Shanghai"
    }

    // 新增 laebel 用于查询日志
    stage.labels {
    	values = { "service_name"="service_name" }
    }
}

loki.write "default" {
    endpoint {
    	url = "http://localhost:3100/loki/api/v1/push"
    }
}
```


