**修改模板 `Redis by Zabbix agent 2`**

新增 redis 密码宏

> 名称不能更改

```
{$REDIS_PASS}: foobared
```

修改 item `Redis: Get config` key

```
redis.config["{$REDIS.CONN.URI}","{$REDIS_PASS}"]
```

修改 item `Redis: Get info` key

```
redis.info["{$REDIS.CONN.URI}","{$REDIS_PASS}"]
```

修改 item `Redis: Ping` key

```
redis.ping["{$REDIS.CONN.URI}","{$REDIS_PASS}"]
```

修改 item `Redis: Slowlog entries per second` key

```
redis.slowlog.count["{$REDIS.CONN.URI}","{$REDIS_PASS}"]
```

**创建主机**

主机1

- 名称: hostname: redis1
- 模板: Redis by Zabbix agent 2
- Interfaces

创建宏

- {$REDIS.CONN.URI}: tcp://192.168.198.10:8001
- {$REDIS_PASS}: 111111

主机2

- 名称: hostname: redis2
- 模板: Redis by Zabbix agent 2
- Interfaces

创建宏

- {$REDIS.CONN.URI}: tcp://192.168.198.10:8002
- {$REDIS_PASS}: 222222

参考文档: https://blog.csdn.net/lyace2010/article/details/122750287





