##### 常用

查看防火墙状态

```
firewall-cmd --state
```

查看活动的区域

```
firewall-cmd --get-active-zones
```

重新加载配置

```
firewall-cmd --reload
```

##### 服务

列出开通的服务

```cpp
firewall-cmd --permanent --zone=public --list-services
```

添加服务

```
firewall-cmd --permanent --zone=public --add-service=https
```

删除服务

```
firewall-cmd --permanent --zone=public --remove-service=https
```

##### 端口号

列出开通的端口号

```cpp
firewall-cmd --permanent --zone=public --list-ports
```

添加端口号

```
# 单个端口号
firewall-cmd --permanent --zone=public --add-port=8080/tcp
# 端口号范围
firewall-cmd --permanent --zone=public --add-port=8080/tcp
```

删除端口号

```
# 单个端口号
firewall-cmd --permanent --zone=public --remove-port=8080/tcp
# 端口号范围
firewall-cmd --permanent --zone=public --remove-port=8080-8090/tcp
```

##### rich-rules

列出 rich-rules

```cpp
firewall-cmd --permanent --zone=public --list-rich-rules
```

添加 rich-rules

```
# 允许单个端口号
firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="21" accept"
# 允许端口号范围
firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="6000-8000" accept"

# 拒绝单个端口号
firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="21" reject"
# 拒绝端口号范围
firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="6000-8000" reject"
```

删除 rich-rules

```
# 单个端口号
firewall-cmd --permanent --zone=public --remove-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="21" accept"
# 端口号范围
firewall-cmd --permanent --zone=public --remove-rich-rule="rule family="ipv4" source address="192.168.198.129" port protocol="tcp" port="6000-8000" accept"
```

