下载编译安装

```
yum install -y gcc gcc-c++
wget http://download.redis.io/releases/redis-5.0.3.tar.gz
tar xzf redis-5.0.3.tar.gz
cd redis-5.0.3
make install
```

默认安装到了 /usr/local/bin

```
# ls /usr/local/bin
redis-benchmark  redis-check-aof  redis-check-rdb  redis-cli  redis-sentinel  redis-server
```

初始化服务

```
# cd utils/
# sh install_server.sh 
Welcome to the redis service installer
This script will help you easily set up a running redis server

Please select the redis port for this instance: [6379] 
Selecting default: 6379
Please select the redis config file name [/etc/redis/6379.conf] /etc/redis/redis.conf     
Please select the redis log file name [/var/log/redis_6379.log] /var/log/redis.log     
Please select the data directory for this instance [/var/lib/redis/6379] 
Selected default - /var/lib/redis/6379
Please select the redis executable path [/usr/local/bin/redis-server] 
Selected config:
Port           : 6379
Config file    : /etc/redis/redis.conf
Log file       : /var/log/redis.log
Data dir       : /var/lib/redis/6379
Executable     : /usr/local/bin/redis-server
Cli Executable : /usr/local/bin/redis-cli
Is this ok? Then press ENTER to go on or Ctrl-C to abort.
Copied /tmp/6379.conf => /etc/init.d/redis_6379
Installing service...
Successfully added to chkconfig!
Successfully added to runlevels 345!
/var/run/redis_6379.pid exists, process is already running or crashed
Installation successful!
```

修改配置文件 /etc/redis/redis.conf 

```
# 绑定IP
bind 192.168.1.224
# 后台运行
daemonize yes
# 设置密码
requirepass "redisPASSWORD"
# 最大使用内存字节数
maxmemory 536870912
# 删除策略
maxmemory-policy allkeys-lru
```

启动 redis

```
systemctl start redis_6379
```

