##### 安装 centos 7 zabbix yum 源

> 包地址：http://repo.zabbix.com/zabbix/

```
# 3.4
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
# 5.0
rpm -ivh http://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
# 6.0
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/7/x86_64/zabbix-release-6.0-2.el7.noarch.rpm
```

##### 安装 server

##### 安装 agent

安装

```
yum install -y zabbix-agent
```

修改配置文件 /etc/zabbix/zabbix_agentd.conf

```
Server=192.168.40.201
ServerActive=192.168.40.201
Hostname=centos7-001
```

##### 安装 proxy

> 只需 proxy 能够连接 server 的端口，无需 server 能够连接 proxy 的端口, proxy 主动上传数据。
>
> Hostname 必须与 web 上的 “agent代理程序名称” 一致。
>
> proxy 必须能解析 agent  Hostname 。
>
> 主机添加流程：web 新增 -> 重启 proxy (拉取配置) -> 启动(重启) agent 。

安装

```
yum install -y zabbix-proxy-mysql
gzip -d /usr/share/doc/zabbix-proxy-mysql-3.4.15/schema.sql.gz
mysql -u zabbix -p zabbix < schema.sql
```

修改配置文件 /etc/zabbix/zabbix_proxy.conf

```
Server=47.106.230.34
# 在 hosts 添加解析
Hostname=zabbix-proxy
DBHost=192.168.40.185
DBName=zabbix
DBUser=zabbix
DBPassword=Zabbix@139
```

启动

```
systemctl start zabbix-proxy
```

##### 安装 web


