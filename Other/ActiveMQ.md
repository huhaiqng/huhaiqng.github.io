**使用 docker 部署 activemq**

> 默认用户名 admin，密码 admin

```
docker run --name='data-centre-activemq' -d \
-v /data/data-centre-activemq:/data/activemq \
-p 8162:8161 \
-p 61617:61616 \
-p 61614:61613 \
rmohr/activemq:5.10.0
```



**问题：/data/activemq/kahadb 目录过大，并且持续增长**

![image-20210104144250471](ActiveMQ.assets/image-20210104144250471.png)

产生原因：消息生产者启用了消息持久化，并且部分消息没有被消费，导致 log 文件无法自动删除。

![image-20210104144421122](ActiveMQ.assets/image-20210104144421122.png)

处理方法：

禁用持久化，在 broker 处添加 persistent="false"

```
<broker persistent="false" ...>
  ...
</broker>
```

删除 log 文件，在 kahaDB 添加 ignoreMissingJournalfiles="true"，避免启动时检查 log 文件

> 如果禁用了持久化，ignoreMissingJournalfiles 不设置也不会检查 log 文件。
>
> 如果有部分 log 文件被删除，需要启用持久化，则必须设置 ignoreMissingJournalfiles="true"，否则无法启动。启动成功后，ignoreMissingJournalfiles="true" 可以去掉，再次重启不会报错。
>
> 如果全部 log 文件被删除，不设置 ignoreMissingJournalfiles="true"，也可以启动成功，花费的时间较长。
>
> 

```
<persistenceAdapter>
  <kahaDB ignoreMissingJournalfiles="true" journalMaxFileLength="32mb" .../>
</persistenceAdapter>
```

