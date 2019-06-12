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
   journal:
      enabled: true
   wiredTiger:
      engineConfig:
         cacheSizeGB: 0.5
systemLog:
   destination: file
   path: "/usr/local/mongodb/log/mongod.log"
   logAppend: true

operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 1000
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

### 副本集

##### 部署副本集

配置文件

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27017
storage:
   dbPath: /usr/local/mongodb/data/
   journal:
      enabled: true
   wiredTiger:
      engineConfig:
         cacheSizeGB: 0.5
systemLog:
   destination: file
   path: "/usr/local/mongodb/log/mongod.log"
   logAppend: true
operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 1000
replication:
   replSetName: "rs"
```

初始化副本集

```
rs.initiate( {
   _id : "rs",
   members: [
      { _id: 0, host: "188.188.1.151:27017" },
      { _id: 1, host: "188.188.1.152:27017" },
      { _id: 2, host: "188.188.1.153:27017" }
   ]
})
```

##### 强制切换 PRIMARY 节点

当前副本集状态

```
mdb0.example.net - the current primary.
mdb1.example.net - a secondary.
mdb2.example.net - a secondary .
```

冻结节点 mdb2.example.net 120秒

```
rs.freeze(120)
```

降级节点 mdb0.example.net 120秒

```
rs.stepDown(120)
```

##### 新增节点

清空新节点的数据目录

```
rm -rf data/*
```

启动新节点

```
bin/mongod -f rs.conf
```

在 PRIMARY 节点添加新节点，新节点自动同步数据

```
rs.add( { host: "188.188.1.153:27017", priority: 0, votes: 0 } )
```

新节点转换为 SECONDARY状态后，更新新添加节点的 priority和 votes

```
var cfg = rs.conf();
cfg.members[2].priority = 1
cfg.members[2].votes = 1
rs.reconfig(cfg)
```

### 分片

##### 部署配置副本集

配置文件 configrs.conf

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27000
storage:
   dbPath: /usr/local/mongodb/config/data/
   journal:
      enabled: true
   wiredTiger:
      engineConfig:
         cacheSizeGB: 0.5
systemLog:
   destination: file
   path: "/usr/local/mongodb/config/log/mongod.log"
   logAppend: true
operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 1000
sharding:
   clusterRole: configsvr
replication:
   replSetName: configrs
```

初始化配置副本集

```
rs.initiate(
  {
    _id: "configrs",
    configsvr: true,
    members: [
      { _id : 0, host : "cfg1.example.net:27000" },
      { _id : 1, host : "cfg2.example.net:27000" },
      { _id : 2, host : "cfg3.example.net:27000" }
    ]
  }
)
```

##### 部署分片副本集

分片副本集 shardrs01 配置文件 shardrs01.conf

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27001
storage:
   dbPath: /usr/local/mongodb/shardrs01/data/
   journal:
      enabled: true
   wiredTiger:
      engineConfig:
         cacheSizeGB: 0.5
systemLog:
   destination: file
   path: "/usr/local/mongodb/shardrs01/log/mongod.log"
   logAppend: true
operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 1000
sharding:
   clusterRole: shardsvr
replication:
   replSetName: shardrs01
```

初始化分片副本集 shardrs01

```
rs.initiate(
  {
    _id : "shardrs01",
    members: [
      { _id : 0, host : "s1-mongo1.example.net:27001" },
      { _id : 1, host : "s1-mongo2.example.net:27001" },
      { _id : 2, host : "s1-mongo3.example.net:27001" }
    ]
  }
)
```

分片副本集 shardrs02配置文件 shardrs02.conf

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27002
storage:
   dbPath: /usr/local/mongodb/shardrs02/data/
   journal:
      enabled: true
   wiredTiger:
      engineConfig:
         cacheSizeGB: 0.5
systemLog:
   destination: file
   path: "/usr/local/mongodb/shardrs02/log/mongod.log"
   logAppend: true 
operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 1000
sharding:
   clusterRole: shardsvr
replication:
   replSetName: shardrs02
```

初始化分片副本集 shardrs02

```
rs.initiate(
  {
    _id : "shardrs02",
    members: [
      { _id : 0, host : "s1-mongo1.example.net:27002" },
      { _id : 1, host : "s1-mongo2.example.net:27002" },
      { _id : 2, host : "s1-mongo3.example.net:27002" }
    ]
  }
)
```

##### 部署路由

配置文件 mongos.conf

```
processManagement:
   fork: true
net:
   bindIp: 0.0.0.0
   port: 27017
systemLog:
   destination: file
   path: "/usr/local/mongodb/mongos/log/mongod.log"
   logAppend: true
sharding:
   configDB: configrs/188.188.1.151:27000,188.188.1.152:27000,188.188.1.153:27000
```

启动 mongos

```
bin/mongos -f mongos.conf
```

添加分片副本集

```
sh.addShard("shardrs01/188.188.1.151:27001")
sh.addShard("shardrs02/188.188.1.151:27002")
```

数据库启用分片

```
sh.enableSharding("<database>")
```

指定集合分片键

```
sh.shardCollection("<database>.<collection>", { <shard key> : "hashed" } )
```

### 常用命令

##### 数据库

显示数据库

```
show dbs
```

##### 集合

显示集合

```
use test
show collections
```

##### 副本集

配置 SECONDARY 可读

```
rs.slaveOk()
```

查看 SECONDARY 同步状况

```
rs.printSlaveReplicationInfo()
```

查看副本集配置

```
rs.conf()
```

查看集群状态

```
rs.status()
```

查看 PRIMARY 节点

```
rs.isMaster()
```

删除节点

```
rs.remove("mongod3.example.net:27017")
```

##### 分片

查看分片状态

```
sh.status()
```

