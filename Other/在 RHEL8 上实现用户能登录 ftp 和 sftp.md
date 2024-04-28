安装 vsftp

```
yum install -y vsftpd
```

修改 vsftp 配置文件 /etc/vsftpd/vsftpd.conf

> 被动模式(passive):  以端口21监听，有连接请求时，随机开放一个比较大的端口号来处理数据传输。ftp 客户端要能够连通该端口号。

```
listen=YES
listen_ipv6=NO
# 日志目录
xferlog_file=/data/logs/vsftpd/xferlog
# 禁止用户访问家目录的上一层目录
chroot_local_user=YES

pasv_min_port=16000
pasv_max_port=17000
```

修改 /etc/pam.d/vsftpd，注释以下行

```
# auth       required	pam_shells.so
```

启动 vsftpd

```
systemctl start vsftpd
```

修改 /etc/ssh/sshd_config

> 需要将 ftpgroup 修改成相应的组名

```
# Subsystem     sftp    /usr/libexec/openssh/sftp-server
Subsystem sftp  internal-sftp
# 添加到文件最后
Match Group sftpgroup
        ForceCommand    internal-sftp
        ChrootDirectory %h
```

重启 sshd

```
systemctl restart sshd
```

创建用户

> -M: 不创建 home 目录
>
> /data/sftpuser的属主属组必须为 root.root

```
# sg uat
groupadd -g 20002 sftpgroup
useradd -u 20002 -M -d /data/sftphome/globalsftp -s /sbin/nologin -g sftpgroup globalsftpuat
passwd globalsftpuat
mkdir -pv /data/sftphome/globalsftp
chown -R root.root /data/sftphome/globalsftp
chmod -R 755 /data/sftphome
mkdir -pv /data/sftphome/globalsftp/inbound
mkdir -pv /data/sftphome/globalsftp/outbound
chown -R globalsftpuat.sftpgroup /data/sftphome/globalsftp/inbound
chown -R globalsftpuat.sftpgroup /data/sftphome/globalsftp/outbound

# sg prod
groupadd -g 20002 sftpgroup
useradd -u 20002 -M -d /data/sftphome/globalsftp -s /sbin/nologin -g sftpgroup globalsftpprod
passwd globalsftpprod
mkdir -pv /data/sftphome/globalsftp
chown -R root.root /data/sftphome/globalsftp
chmod -R 755 /data/sftphome
mkdir -pv /data/sftphome/globalsftp/inbound
mkdir -pv /data/sftphome/globalsftp/outbound
chown -R globalsftpprod.sftpgroup /data/sftphome/globalsftp/inbound
chown -R globalsftpprod.sftpgroup /data/sftphome/globalsftp/outbound
```

修改 selinux

```
setsebool -P ftpd_full_access 1
# setsebool -P ftp_home_dir 1
```

