创建备份账号

```
mysql> create user 'backup'@'%' identified by 'Yuh04j!w';
mysql> GRANT SELECT, RELOAD, PROCESS, SHOW DATABASES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER ON *.* TO `backup`@`%`;
mysql> flush privileges;
```

定时备份数据库脚本

> --source-data: 在备份文件中生成一条`-- CHANGE MASTER TO MASTER_LOG_FILE='binlog.000004', MASTER_LOG_POS=596142684;`，记录备份时 binlog 位置。

```
mysqldump sbtest \
--set-gtid-purged=OFF \
--triggers \
--routines \
--events \
--single-transaction \
--quick \
--source-data=2 > sbtest.sql
```

创建目标数据库

```
create database sbtest_backup;
```

导入备份数据库

> skip-log-bin: 关闭binlog。

```
mysql sbtest_backup < sbtest.sql
```

查看备份时 binlog 位置

```
more sbtest.sql 
...
-- CHANGE MASTER TO MASTER_LOG_FILE='binlog.000004', MASTER_LOG_POS=596142684;
...
```

修改 net_read_timeout，防止重放binlog时超时。

```
set global net_read_timeout=30000;
set global max_allowed_packet=1073741824;
```

重放 binlog

> --rewrite-db 必须在 --database 之前，且 --database 为新数据库名

```
mysqlbinlog \
--rewrite-db="sbtest->sbtest_backup" \
--database=sbtest_backup \
--start-position="596142684" binlog.000004 | mysql
```





