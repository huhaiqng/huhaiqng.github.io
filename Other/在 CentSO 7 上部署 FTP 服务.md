

### 搭建基本的 vsftpd 服务器

安装 vsftp

```
yum install -y vsftpd
```

修改配置文件

> 被动模式(passive):  以端口21监听，有连接请求时，随机开放一个比较大的端口号来处理数据传输。ftp 客户端要能够连通该端口号。

```
anonymous_enable=NO
# 禁止匿名访问
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
# 禁止用户访问家目录的上一层目录
listen=NO
listen_ipv6=YES

pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
allow_writeable_chroot=YES

# 设置被动模式端口随机启动的端口范围
pasv_min_port=6000
pasv_max_port=7000
```

修改 /etc/pam.d/vsftpd，注释以下行

```
# auth       required	pam_shells.so
```

创建用户

```
useradd -d /ftproot -s /sbin/nologin ftpuser
password ftpuser
```

启动 vsftpd

```
systemctl start vsftpd
```

### ftp 命令的使用

连接 ftp 服务器

```
# 主动模式，ftp 服务器数据传输使用 21 端口号
ftp -A 192.168.198.10
# 被动模式，ftp 服务器数据传输使用随机端口号
ftp -p 192.168.198.10
```

上传文件

```
ftp> put src_filename dest_filename
```

下载文件

```
ftp> get dest_filename
```

切换模式

```
ftp> passive
```



### 搭建使用虚拟用户的 vsftpd 服务器

安装 vsftpd

```
yum -y install pam pam-devel db4 db4-tcl
yum -y install vsftpd
```

修改配置文件 

```
anonymous_enable=NO
# 禁止匿名访问
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
# 禁止用户访问家目录的上一层目录
listen=NO
listen_ipv6=YES

pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
allow_writeable_chroot=YES
# 在 CentOS 7 上设置了 chroot_local_user=YES 后，需要配置此参数，否则无法登陆。

# 以下这些是关于Vsftpd虚拟用户支持的重要配置项目
guest_enable=YES
# 设定启用虚拟用户功能
guest_username=ftpuser
# 指定虚拟用户的宿主用户
virtual_use_local_privs=YES
# 设定虚拟用户的权限符合他们的宿主用户 
user_config_dir=/etc/vsftpd/vconf
# 设定虚拟用户个人Vsftp的配置文件存放路径。这些配置文件名必须和虚拟用户名相同。
```

创建宿主用户

```
useradd -s /sbin/nologin ftpuser
```

创建虚拟用户配置文件存放路径

```
mkdir /etc/vsftpd/vconf
```

创建虚拟用户名单文件 /etc/vsftpd/virtusers，奇数行用户名，偶数行口令

```
ftpuser01
password123
```

生成虚拟用户数据文件

```
db_load -T -t hash -f /etc/vsftpd/virtusers /etc/vsftpd/virtusers.db
# 修改虚拟用户名单文件后，需要执行此命令
```

配置认证文件 /etc/pam.d/vsftpd ，**将原有的行都注释**

```
auth    sufficient      /lib64/security/pam_userdb.so    db=/etc/vsftpd/virtusers
account sufficient      /lib64/security/pam_userdb.so    db=/etc/vsftpd/virtusers
```

创建 vsftpd 目录

```
mkdir /ftproot/
chown ftpuser.ftpuser /ftproot/
```

创建虚拟用户配置模板 /etc/vsftpd/vconf/vconf.tmp

```
local_root=/ftproot/
# 指定虚拟用户的具体主路径
anonymous_enable=NO
# 设定不允许匿名用户访问
write_enable=YES
# 设定允许写操作
local_umask=022
# 设定上传文件权限掩码
anon_upload_enable=NO
# 设定不允许匿名用户上传
anon_mkdir_write_enable=NO
# 设定不允许匿名用户建立目录
idle_session_timeout=600
# 设定空闲连接超时时间
data_connection_timeout=120
# 设定单次连续传输最大时间
max_clients=10
# 设定并发客户端访问个数
max_per_ip=5
# 设定单个客户端的最大线程数
local_max_rate=50000
# 设定该用户的最大传输速率，单位b/s
```

创建用户配置文件

```
cp /etc/vsftpd/vconf/vconf.tmp /etc/vsftpd/vconf/ftpuser01
```

启动 vsftpd

```
systemctl start vsftpd
```

参考博文：https://blog.51cto.com/xmomo/2074258



### 内外网可以访问

> 可能是ftp的保护设置 配置文件中增加 pasv_promiscuous 关闭PASV模式的安全检查

```
pasv_promiscuous=YES
```

参考博文：https://blog.csdn.net/hajistark/article/details/82954777