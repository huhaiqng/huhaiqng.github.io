创建 MySQL 监控账号

```
CREATE USER 'zbx_monitor'@'%' IDENTIFIED BY 'MySQL8.0';
GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'%';
```

创建 /var/lib/zabbix/.my.cnf 文件

```
[client]
user='zbx_monitor'
password='MySQL8.0'
```

修改 zabbix agent 配置文件 /usr/local/zabbix/etc/zabbix_agentd.conf

```
Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/*.conf
UnsafeUserParameters=1
```

 创建 /usr/local/zabbix/etc/zabbix_agentd.conf.d/mysql.conf

> zabbix 无法读取默认的 .my.cnf，使用 --defaults-file 指定

```
UserParameter=mysql.ping[*], mysqladmin --defaults-file=/var/lib/zabbix/.my.cnf -h$1 -P$2 ping
UserParameter=mysql.get_status_variables[*], mysql --defaults-file=/var/lib/zabbix/.my.cnf -h"$1" -P"$2" -sNX -e "show global status"
UserParameter=mysql.version[*], mysqladmin --defaults-file=/var/lib/zabbix/.my.cnf -s -h"$1" -P"$2" version
UserParameter=mysql.db.discovery[*], mysql --defaults-file=/var/lib/zabbix/.my.cnf -h"$1" -P"$2" -sN -e "show databases"
UserParameter=mysql.dbsize[*], mysql --defaults-file=/var/lib/zabbix/.my.cnf -h"$1" -P"$2" -sN -e "SELECT COALESCE(SUM(DATA_LENGTH + INDEX_LENGTH),0) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$3'"
UserParameter=mysql.replication.discovery[*], mysql --defaults-file=/var/lib/zabbix/.my.cnf -h"$1" -P"$2" -sNX -e "show slave status"
UserParameter=mysql.slave_status[*], mysql --defaults-file=/var/lib/zabbix/.my.cnf -h"$1" -P"$2" -sNX -e "show slave status"
```

重启 zabbix agent

```
systemctl restart zabbix_agentd
```

修改主机，添加模板`MySQL by Zabbix agent`

![image-20220915103820134](C:\Users\haiqi\Desktop\devops-note\Zabbix\assets\image-20220915103820134.png)

修改默认 MYSQL.HOST: localhost 和 MYSQL.PORT: 3306

![image-20220915103937542](C:\Users\haiqi\Desktop\devops-note\Zabbix\assets\image-20220915103937542.png)

参考文档: https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/db/mysql_agent?at=release%2F6.0



#### 