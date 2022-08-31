**使用 keepalive+haproxy+nginx 的架构可以事现多个 nginx 同时提供服务**

**使用 keepalive+nginx 的架构只有一个 nginx 提供服务 **

##### nginx

安装

```
yum install -y epel-release
yum install -y nginx
```

修改配置文件 /etc/nginx/nginx.conf

> proxy_protocol: 可以获取客户端真实 IP，使用后无法直接访问 nginx

```
http {
    ...
    set_real_ip_from    192.168.1.0/24;
    real_ip_header      proxy_protocol;
	...
    server {
        listen       88 proxy_protocol;
        listen       [::]:88;
        ...
    }
}
```

启动

```
nginx
```



##### haproxy

配置文件 /etc/haproxy/haproxy.cfg

```shell
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0 warning
    log /dev/log local1 warning
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

frontend nginxhttp
    bind *:80
    mode tcp
    option tcplog
    default_backend nginxhttp
	
frontend nginxhttps
    bind *:443
    mode tcp
    option tcplog
    default_backend nginxhttps

backend nginxhttp
    mode tcp
    balance roundrobin
    server server0 192.168.1.200:88 check send-proxy
    server server0 192.168.1.201:88 check send-proxy
	
backend nginxhttps
    mode tcp
    balance roundrobin
    server server0 192.168.1.200:446 check send-proxy
    server server0 192.168.1.201:446 check send-proxy
```



##### keepalived

安装

```
yum install -y keepalived
```

检测脚本 /etc/keepalived/check_nginx.sh
```
#!/bin/bash
V_IP=192.168.40.170

# haproxy 异常，vip 迁移
nc -zv localhost 80 || exit 1
```

MASTER 配置文件 /etc/keepalived/keepalived.conf

> interface: 修改为服务器对应的网卡名

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_nginx {
  script "/etc/keepalived/check_nginx.sh"
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
        192.168.1.8
    }
    track_script {
        check_nginx
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
vrrp_script check_nginx {
  script "/etc/keepalived/check_nginx.sh"
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
        192.168.1.8
    }
    track_script {
        check_nginx
    }
}
```
