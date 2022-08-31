#### 优化

设置 ip 主机名映射
``` 
1.1.1.1		hostname 
```
关闭防火墙
```
systemctl stop firewalld
systemctl disable firewalld 
```

关闭 selinux
```
setenforce 0
vim /etc/sysconfig/selinux
------------------------------------
SELINUX=disabled
------------------------------------
```
调整最大文件打开数，重启生效
```
vim /etc/security/limits.conf 
------------------------------------
*    soft    nofile   65535
*    hard    nofile   65535
*    soft    nproc    65535
*    hard    nproc    65535
------------------------------------
vim /etc/security/limits.d/20-nproc.conf
------------------------------------
*          soft    nproc     65535
root       soft    nproc     unlimited

------------------------------------
```



#### 永久关闭 swap

```
vim /etc/fstab 
# /dev/mapper/centos-swap swap                    swap    defaults        0 0
```



#### 设置对所有用户永久生效的环境变量 npm

创建文件 /etc/profile.d/custom.sh

> /etc/profile 会加载此文件

```
PATH=$PATH:/usr/local/node/bin
export PATH
```



#### 设置对所有用户永久生效的环境变量 java

创建文件 /etc/profile.d/custom.sh

```
JAVA_HOME=/usr/local/jdk1.8.0_261
CLASSPATH=$JAVA_HOME/lib
PATH=$JAVA_HOME/bin:$PATH
export PATH JAVA_HOME CLASSPATH
```

