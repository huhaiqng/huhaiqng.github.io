在主库中导出全部数据库

> --source-data=1:  在导出的文件会新增一条语句`CHANGE MASTER TO MASTER_LOG_FILE='binlog.000005', MASTER_LOG_POS=23363959;`，在已存在的从库中导入，会自动更新 MASTER_LOG_FILE 和 MASTER_LOG_POS。
>
> --source-data=2:   在导出的文件会新增一条注释语句`CHANGE MASTER TO MASTER_LOG_FILE='binlog.000005', MASTER_LOG_POS=23363959;`，在已存在的从库中导入时不会执行。
>
> 命令执行时会锁住全部表。
>
> 从 MySQL 8.0.26 开始，使用`--source-data`，在 MySQL 8.0.26 之前，使用 `--master-data`。

```
mysqldump -u root -p'password' --all-databases --source-data=1 > all-database-master-`date +%Y%m%d%H%M%S`.dump
```

停止从库 slave

```
stop slave;
```

备份从库

```
mysqldump -u root -p'password' --all-databases --source-data=2 > all-database-slave-`date +%Y%m%d%H%M%S`.dump
```

在从库中导入 all-database

```
mysql -u root -p'password' < all-database-master-`date +%Y%m%d%H%M%S`.dump
```

启动从库 slave

```
start slave;
```