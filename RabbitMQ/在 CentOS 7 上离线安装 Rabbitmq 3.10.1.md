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
yum localinstall -y rabbitmq-server-3.10.0-1.el7.noarch
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

##### 问题1： 使用 rabbitmq 用户启动无法创建用户

/usr/lib/systemd/system/rabbitmq-server.service 文件

```
[Unit]
Description=RabbitMQ broker
After=syslog.target network.target

[Service]
Type=notify
User=rabbitmq
Group=rabbitmq
UMask=0027
NotifyAccess=all
TimeoutStartSec=600

# To override LimitNOFILE, create the following file:
#
# /etc/systemd/system/rabbitmq-server.service.d/limits.conf
#
# with the following content:
#
# [Service]
# LimitNOFILE=65536

LimitNOFILE=32768

# Note: systemd on CentOS 7 complains about in-line comments,
# so only append them here
#
# Restart:
# The following setting will automatically restart RabbitMQ
# in the event of a failure. systemd service restarts are not a
# replacement for service monitoring. Please see
# https://www.rabbitmq.com/monitoring.html
Restart=on-failure
RestartSec=10
WorkingDirectory=/usr/local/rabbitmq
ExecStart=/usr/local/rabbitmq/sbin/rabbitmq-server
ExecStop=/usr/local/rabbitmq/rabbitmqctl shutdown
# See rabbitmq/rabbitmq-server-release#51
SuccessExitStatus=69

[Install]
WantedBy=multi-user.target

```

创建用户报错信息

>  TCP connection succeeded but Erlang distribution failed 

```
# rabbitmqctl add_user admin iTxrsF2o5e53
Error: unable to perform an operation on node 'rabbit@LVASOMSMQAPPD01'. Please see diagnostics information and suggestions below.

Most common reasons for this are:

 * Target node is unreachable (e.g. due to hostname resolution, TCP connection or firewall issues)
 * CLI tool fails to authenticate with the server (e.g. due to CLI tool's Erlang cookie not matching that of the server)
 * Target node is not running

In addition to the diagnostics info below:

 * See the CLI, clustering and networking guides on https://rabbitmq.com/documentation.html to learn more
 * Consult server logs on node rabbit@LVASOMSMQAPPD01
 * If target node is configured to use long node names, don't forget to use --longnames with CLI tools

DIAGNOSTICS
===========

attempted to contact: [rabbit@LVASOMSMQAPPD01]

rabbit@LVASOMSMQAPPD01:
  * connected to epmd (port 4369) on LVASOMSMQAPPD01
  * epmd reports node 'rabbit' uses port 25672 for inter-node and CLI tool traffic 
  * TCP connection succeeded but Erlang distribution failed 
  * suggestion: check if the Erlang cookie is identical for all server nodes and CLI tools
  * suggestion: check if all server nodes and CLI tools use consistent hostnames when addressing each other
  * suggestion: check if inter-node connections may be configured to use TLS. If so, all nodes and CLI tools must do that
   * suggestion: see the CLI, clustering and networking guides on https://rabbitmq.com/documentation.html to learn more

```

原因：创建用户使用的系统账号是 root，使用的 cookie 文件是 /root/.erlang.cookie。rabbitmq 启动用户是 rabbitmq，创建用户时需要使用 /home/rabbitmq/.erlang.cookie。

处理方法

```
mv /root/.erlang.cookie /root/.erlang.cookie-root
cp /home/rabbitmq/.erlang.cookie /root/.erlang.cookie
```







