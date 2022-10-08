##### 在能联网的服务器上下载 rpm 包

```
mkdir /tmp/erlang
cd /tmp/erlang
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
yum localinstall -y erlang-solutions-1.0-1.noarch.rpm --downloadonly --downloaddir=/tmp/erlang
yum install -y erlang --downloadonly --downloaddir=/tmp/erlang

mkdir /tmp/rabbitmq
cd /tmp/rabbitmq
# 生成 rabbitmq yum 源
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | sudo bash
yum install -y rabbitmq-server.noarch --downloadonly --downloaddir=/tmp/rabbitmq
```

##### 将 erlang rpm 包及依赖包传到目标服务器目录 /tmp/erlang 上并安装

> 会自动从本地读取依赖包

```
cd /tmp/erlang
yum localinstall -y *.rpm
```

##### rpm 包方式安装 rabbitmq

将 rabbitmq rpm 包及依赖包传到目标服务器目录 /tmp/rabbitmq上并安装

```
cd /tmp/rabbitmq
yum localinstall -y *.rpm
```

管理

```
systemctl start rabbitmq-server
systemctl stop rabbitmq-server
```

##### 二进制安装包方式安装 rabbitmq

下载安装包: https://github.com/rabbitmq/rabbitmq-server/releases

将安装包上传到服务器目录 /usr/local/src 并解压

```
cd /usr/local/src
tar xf rabbitmq-server-generic-unix-3.10.1.tar.xz
mv rabbitmq_server-3.10.1 /usr/local/rabbitmq
```

管理

```
# 前台启动
sbin/rabbitmq-server
# 后台启动
sbin/rabbitmq-server -detached
# 关闭
sbin/rabbitmqctl shutdown
```



