**修改模板 `RabbitMQ node by Zabbix agent`**

> {HOST.NAME} 可能和 rabbitmq cluster 中的 hostname 不一致。

修改监控项 `RabbitMQ: Get nodes`，去除 @{HOST.NAME}，在节点宏 {$RABBITMQ.CLUSTER.NAME} 中设置具体的值。

```
web.page.get["{$RABBITMQ.API.SCHEME}://{$RABBITMQ.API.USER}:{$RABBITMQ.API.PASSWORD}@{$RABBITMQ.API.HOST}:{$RABBITMQ.API.PORT}/api/nodes/{$RABBITMQ.CLUSTER.NAME}@{HOST.NAME}?memory=true"]
改为
web.page.get["{$RABBITMQ.API.SCHEME}://{$RABBITMQ.API.USER}:{$RABBITMQ.API.PASSWORD}@{$RABBITMQ.API.HOST}:{$RABBITMQ.API.PORT}/api/nodes/{$RABBITMQ.CLUSTER.NAME}?memory=true"]
```

修改触发器 `RabbitMQ: Too many messages in queue [{#VHOST}][{#QUEUE}] (over {$RABBITMQ.MESSAGES.MAX.WARN:"{#QUEUE}"} for 5m)`

> 主动发现 `RabbitMQ: Get queues: Queues discovery` 触发器

```
min(/RabbitMQ node by Zabbix agent/rabbitmq.queue.messages["{#VHOST}/{#QUEUE}"],5m)>{$RABBITMQ.MESSAGES.MAX.WARN:"{#QUEUE}"}
改为
min(/RabbitMQ node by Zabbix agent/rabbitmq.queue.messages["{#VHOST}/{#QUEUE}"],5m)>{$RABBITMQ.MESSAGES.MAX.WARN}
```

**修改主机**

添加模板 `RabbitMQ node by Zabbix agent`

设置主机宏

- {$RABBITMQ.CLUSTER.NAME}: rabbit@hostname

  >  rabbitmq cluster 名称，web 首页可查看不一定准确。
  >
  > 从监控项 `RabbitMQ: Get queues` 值中查看到的 node 名称一定是准确的。

- {$RABBITMQ.API.PASSWORD}: 123456

  > 获取数据的密码

- {$RABBITMQ.API.USER}: admin

  > 获取数据的用户名

- {$RABBITMQ.MESSAGES.MAX.WARN}: 10

  > 触发报警的队列中未消费消息的数量

- {$RABBITMQ.API.HOST}: 1.1.1.1

  > rabbtimq 服务器 ip，如果 agent 和 rabbitmq 在同一台服务器可以不用配置。

设置自动发现 `RabbitMQ: Get queues: Queues discovery` 过滤器 {#NODE}

> 节点宏 {$RABBITMQ.CLUSTER.NAME} 已修改

```
{$RABBITMQ.CLUSTER.NAME}@{HOST.NAME}
改为
{$RABBITMQ.CLUSTER.NAME}
```

