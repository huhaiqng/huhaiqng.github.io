##### zabbix agent 设置

服务器上创建脚本 `/usr/local/zabbix/scripts/php_process_discovery.sh`

> etimes: 进程启动的时间，启动超过1个小时才进行监控，注意进程重启的情况，自动发现最好在凌晨检测。

```
#!/bin/bash

ps -eo etimes,command | grep "php[[:space:]]" | grep "app.php[[:space:]]" | grep -v "sudo\|^grep" | awk '{if($1>3600) print($2,$3,$4)}' | sort | uniq
```

创建 key 文件 `/usr/local/zabbix/etc/zabbix_agentd.conf.d/abc.conf`

```
UserParameter=oms.process.discovery,sh /usr/local/zabbix/scripts/php_process_discovery.sh
```



##### 创建 zabbix 模板 `php process`

创建模板自动发现 `php process discovery`

自动发现规则

- 名称: php process discovery
- 类型: Zabbix 客户端
- 键值: oms.process.discovery
- 更新间隔: 0
- 自定义时间间隔: 调度 -> wd1-5h5m5

进程

- 名称: JavaScript
- 参数: 

```
return JSON.stringify(value.split("\n").map(function (name) {
    return ({"{#PROCNAME}": name});
}));
```

监控原型1

- 名称: `进程: {#PROCNAME}`
- 键值: `proc.num[,www,,^{#PROCNAME}$]`

监控原型2

- 名称: `进程CPU: {#PROCNAME}`
- 键值: `proc.cpu.util[,www,,^{#PROCNAME}$]`

监控原型3

- 名称: `进程内存: {#PROCNAME}`
- 键值: `proc.mem[,www,,^{#PROCNAME}$,rss]`

触发器类型1

- 名称: `进程退出: {#PROCNAME}`

- 表达式: `last(/php process/proc.num[,www,,^{#PROCNAME}$])=0`