配置 hostname

```
192.168.40.171	mysql01
192.168.40.173  mysql02
192.168.40.175  mysql03
```

配置 yum 源 mysql-community.repo

```
rpm -i https://repo.mysql.com//mysql80-community-release-el7-6.noarch.rpm
sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/mysql-community.repo
```

安装 mysql-server mysql-router mysql-shell

```
yum install -y mysql-community-{server,client,common,libs}-* mysql-router mysql-shell
systemctl start mysqld
systemctl enable mysqld
```

查看 MySQL 的默认密码

```
grep pass /var/log/mysqld.log
```

更改 root 默认密码

```
ALTER USER 'root'@'localhost' identified by 'MySQL8.0';
CREATE USER 'root'@'192.168.40.%' identified by 'MySQL8.0';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.40.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

检测设置配置

```
dba.checkInstanceConfiguration('root@mysql01')
dba.configureInstance('root@mysql01')
```

创建集群

```
\connect root@mysql01
var cluster=dba.createCluster('testCluster')
```

创建管理用户

```
cluster.setupAdminAccount('icadmin')
```

添加实例

```
cluster.addInstance('root@mysql02')
```

查看集群状态

```
\connect root@mysql01
var cluster=dba.getCluster()
cluster.status()
```

