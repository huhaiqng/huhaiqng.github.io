### 通过 keepalived 实现 mysqlrouter 高可用

Innodb Cluster 高可用架构

```
mysql01(188.188.1.151): primary、mysqlrouter、keepalived master
mysql02(188.188.1.152): secondary、mysqlrouter、keepalived backup1
mysql03(188.188.1.153): secondary、mysqlrouter、keepalived backup2
```

安装 Keepalived

```
yum install -y keepalived
```

Keepalived Master 配置文件

```
! Configuration File for keepalived
global_defs {
   router_id ha_mysqlrouter
}
vrrp_script chk_mysqlrouter {
   script "netstat -ntlp | grep mysqlrouter | grep 6446"
   interval 10
   weight -15
}
vrrp_instance VI_1 {
    state MASTER
    interface eno16780032
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass wXLw2vuE
    }
    virtual_ipaddress {
        188.188.1.150
    }
    track_script {
        chk_mysqlrouter
    }
}
```

Keepalived Backup1 配置文件

```
! Configuration File for keepalived
global_defs {
   router_id ha_mysqlrouter
}
vrrp_script chk_mysqlrouter {
   script "netstat -ntlp | grep mysqlrouter | grep 6446"
   interval 10
   weight -15
}
vrrp_instance VI_1 {
    state BACKUP
    interface eno16780032
    virtual_router_id 51
    priority 99
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass wXLw2vuE
    }
    virtual_ipaddress {
        188.188.1.150
    }
    track_script {
        chk_mysqlrouter
    }
}
```

Keepalived Backup2 配置文件

```
! Configuration File for keepalived
global_defs {
   router_id ha_mysqlrouter
}
vrrp_script chk_mysqlrouter {
   script "netstat -ntlp | grep mysqlrouter | grep 6446"
   interval 10
   weight -15
}
vrrp_instance VI_1 {
    state BACKUP
    interface eno16780032
    virtual_router_id 51
    priority 98
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass wXLw2vuE
    }
    virtual_ipaddress {
        188.188.1.150
    }
    track_script {
        chk_mysqlrouter
    }
}
```

启动 Keepalived

```
systemctl enable keepalived
systemctl start keepalived
```

