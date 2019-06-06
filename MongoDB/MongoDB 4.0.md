### 使用 tar 包安装 MongoDB 4.0

##### 禁用透明大页面(CentOS 7)

创建初始化脚本 /etc/init.d/disable-transparent-hugepages

```
#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case $1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > ${thp_path}/enabled
    echo 'never' > ${thp_path}/defrag

    re='^[0-1]+$'
    if [[ $(cat ${thp_path}/khugepaged/defrag) =~ $re ]]
    then
      # RHEL 7
      echo 0  > ${thp_path}/khugepaged/defrag
    else
      # RHEL 6
      echo 'no' > ${thp_path}/khugepaged/defrag
    fi

    unset re
    unset thp_path
    ;;
esac
```

启用

```
chmod 755 /etc/init.d/disable-transparent-hugepages
chkconfig --add disable-transparent-hugepages
systemctl start disable-transparent-hugepages
```

保留 tuned和ktune

```
# 创建目录
mkdir /etc/tuned/no-thp
# 创建文件 /etc/tuned/no-thp/tuned.conf
[main]
include=virtual-guest
[vm]
transparent_hugepages=never
# 执行已命令 
tuned-adm profile no-thp
```

验证结果

```
# 执行以下命令
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag
# 正确的结果
always madvise [never]
```

##### 安装

安装依赖包

```
yum install -y libcurl openssl
```

下载安装包

```
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-4.0.10.tgz
```

解压安装包

```
tar zxvf mongodb-linux-x86_64-rhel70-4.0.10.tgz 
mv mongodb-linux-x86_64-rhel70-4.0.10 mongodb
```

创建数据目录和日志目录

```
cd mongodb
mkdir data log
```

创建配置文件 mongod.conf

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27017
storage:
   dbPath: /usr/local/mongodb/data/
systemLog:
   destination: file
   path: "/usr/local/mongodb/log/mongod.log"
   logAppend: true
storage:
   journal:
      enabled: true
```

修改系统 limit 限制

```
# 在 /etc/security/limits.conf 添加以下行
*	 soft    nofile  65535
*	 hard    nofile  65535
*    soft    nproc   65535  
*    hard    nproc   65535 
# 修改 /etc/security/limits.d/20-nproc.conf 的以下行
*    soft    nproc     65535
```

创建系统用户，用于管理 mongodb

```
groupadd -g 1200 mongo
useradd -u 1200 -g mongo mongo
passwd mongo
chown -R mongo.mongo /usr/local/mongodb/
```

启动 mongodb

```
su - mongo
cd /usr/local/mongodb
bin/mongod -f mongod.conf
```

登陆 mongodb

```
bin/mongo
```

关闭 mongodb

```
bin/mongod -f mongod.conf --shutdown
```

##### 启用身份认证

创建管理员账号

```
use admin
db.createUser(
  {
    user: "admin",
    pwd: "abc123",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
  }
)
```

关闭 mongodb

```
bin/mongod -f mongod.conf --shutdown
```

修改配置文件，添加以下内容

```
security:
   authorization: enabled
```

启动 mongodb

```
bin/mongod -f mongod.conf
```

使用管理员账号登陆 mongodb

```
bin/mongo -u admin -p --authenticationDatabase admin
```

创建普通账号

```
use test
db.createUser(
  {
    user: "mongo",
    pwd: "xyz123",
    roles: [ { role: "readWrite", db: "test" },
             { role: "read", db: "reporting" } ]
  }
)
```

使用普通账号登陆

```
bin/mongo -u mongo -p --authenticationDatabase test
```

