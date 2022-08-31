安装

> 翻墙下载安装包
>
> https://openvpn.net/downloads/openvpn-as-latest-CentOS7.x86_64.rpm
>
> https://openvpn.net/downloads/openvpn-as-bundled-clients-latest.rpm

```shell
yum -y install openvpn-as-bundled-clients-15.rpm
yum -y install openvpn-as-2.8.6_916f8e7d-CentOS7.x86_64.rpm

# 安装结果
Please enter "passwd openvpn" to set the initial
administrative password, then login as "openvpn" to continue
configuration here: https://192.168.40.201:943/admin

To reconfigure manually, use the /usr/local/openvpn_as/bin/ovpn-init tool.

+++++++++++++++++++++++++++++++++++++++++++++++
Access Server 2.8.6 has been successfully installed in /usr/local/openvpn_as
Configuration log file has been written to /usr/local/openvpn_as/init.log


Access Server Web UIs are available here:
Admin  UI: https://192.168.40.201:943/admin
Client UI: https://192.168.40.201:943/
+++++++++++++++++++++++++++++++++++++++++++++++
```



修改用户 openvpn 密码

> 密码: @ncBSvHkBW5!

```
passwd openvpn
```



服务管理

```
# 查看状态
systemctl status openvpnas
# 启动
systemctl start openvpnas
# 停止
systemctl stop openvpnas
# 重启
systemctl restart openvpnas
```



说明

- 免费版只有2个用户可用