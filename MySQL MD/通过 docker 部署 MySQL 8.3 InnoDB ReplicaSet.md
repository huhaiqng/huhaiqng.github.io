安装 docker

```
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce

systemctl start docker
```

创建网络

```
docker network create --subnet 192.168.1.0/24 mysql
```

创建容器

```
docker run -id --name mysql3310 --hostname mysql3310 --ip 192.168.1.10 --add-host mysql3320:192.168.1.20 --network mysql -e MYSQL_ROOT_PASSWORD=MySQL8.3 mysql:8.3.0

docker run -id --name mysql3320 --hostname mysql3320 --ip 192.168.1.20 --add-host mysql3310:192.168.1.10 --network mysql -e MYSQL_ROOT_PASSWORD=MySQL8.3 mysql:8.3.0
```

安装 mysql-shell

```
yum install -y https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-8.3.0-1.el8.x86_64.rpm
```

创建

```
[root@rhel89 ~]# mysqlsh root@mysql3310
 MySQL  mysql3310:33060+ ssl  JS > dba.configureReplicaSetInstance('root@mysql3310',{clusterAdmin: "'rsadmin'@'%'",clusterAdminPassword: 'MySQL8.3'})
 MySQL  mysql3310:33060+ ssl  JS > dba.configureReplicaSetInstance('root@mysql3320',{clusterAdmin: "'rsadmin'@'%'",clusterAdminPassword: 'MySQL8.3'})
 MySQL  mysql3310:33060+ ssl  JS > \q
[root@rhel89 ~]# docker restart mysql3310
[root@rhel89 ~]# docker restart mysql3320
[root@rhel89 ~]# mysqlsh root@mysql3310
 MySQL  mysql3310:33060+ ssl  JS > var rs=dba.createReplicaSet('tRS')
 MySQL  mysql3310:33060+ ssl  JS > rs.addInstance('mysql3320')
[root@rhel89 ~]# docker restart mysql3320
 MySQL  mysql3310:33060+ ssl  JS > rs.status()
 MySQL  mysql3310:33060+ ssl  JS > rs.setupRouterAccount('rsrouter')
```

安装 mysql-router

```
[root@rhel89 ~]# yum install -y https://dev.mysql.com/get/Downloads/MySQL-Router/mysql-router-community-8.3.0-1.el8.x86_64.rpm
[root@rhel89 ~]# mysqlrouter --bootstrap rsadmin@mysql3310 --account=rsrouter --user=root
[root@rhel89 ~]# nohup mysqlrouter -c /etc/mysqlrouter/mysqlrouter.conf >/dev/null 2>&1 &
```

切换 PRIMARY-SECONDARY

```
rs.setPrimaryInstance('root@mysql3320')
```

强制切换 PRIMARY-SECONDARY

```
rs.forcePrimaryInstance('root@mysql3320')
```

删除节点

```
rs.removeInstance('root@mysql3310')
```

强制删除节点

```
rs.removeInstance('root@mysql3310', {force: true})
```

解散 ReplicaSet

```
rs.dissolve()
```

