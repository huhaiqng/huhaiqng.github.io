##### InnoDB ReplicaSet

配置 hostname

```
192.168.40.171	mysql01
192.168.40.173  mysql02
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
dba.configureReplicaSetInstance('root@mysql01:3306')
dba.configureReplicaSetInstance('root@mysql02:3306')
```

创建副本集

```
\connect root@mysql:3306
var rs = dba.createReplicaSet("testRS")
```

添加实例

```
rs.addInstance('root@mysql02')
```

查看状态

```
rs.status()
```

切换主节点

```
rs.setPrimaryInstance('root@mysql01')
```

##### keepalived

> 如果 systemctl restart keepalived 不生效，需要使用 kill 命令关闭 keepalived 进程 

安装

```
yum install -y epel-release
yum install -y keepalived
```

MASTER 配置文件 /etc/keepalived/keepalived.conf

> interface: 修改为服务器对应的网卡名

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_3306 {
  script "netstat -ntlp | grep mysql | grep 3306"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        192.168.40.175
    }
    track_script {
        check_3306
    }
}
```

BACKUP 配置文件 /etc/keepalived/keepalived.conf

> interface: 修改为服务器对应的网卡名

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_3306 {
  script "netstat -ntlp | grep mysql | grep 3306"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 99
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        192.168.40.175
    }
    track_script {
        check_3306
    }
}
```

启动

```
systemctl enable keepalived
systemctl start keepalived
```



**注意**: 使用mysqlrouter 性能会下降 20%