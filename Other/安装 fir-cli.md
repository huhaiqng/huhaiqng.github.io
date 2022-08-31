在 /etc/hosts 中添加记录

```
199.232.28.133 raw.githubusercontent.com
```

首先安装rvm安装会使用的包：

```
yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel \
libyaml-devel libffi-devel openssl-devel make \
bzip2 autoconf automake libtool bison iconv-devel sqlite-devel
```

之后便是安装rvm:

```lua
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
```

配置rvm的运行环境

```
source /etc/profile.d/rvm.sh
rvm reload
```

输入一下命令检查安装情况

```
rvm requirements run
```

将显示：

```
Checking requirements for centos.
Requirements installation successful.
```

配置国内源

```
cat /usr/local/rvm/user/db
echo "ruby_url=https://cache.ruby-china.com/pub/ruby" >> /usr/local/rvm/user/db
cat /usr/local/rvm/user/db
```

最后便可安装ruby了，当然版本可以任选，反正我选2.4.4

```
rvm install 2.6.2
```

检查安装情况

```
rvm list
```

显示如下信息则 安装完成：

```nginx
rvm rubies

=* ruby-2.6.2 [ x86_64 ]

# => - current
# =* - current && default
#  * - default
```

设置默认运行的ruby版本

```
rvm use 2.6.2 --default
ruby -v
```

安装 fir-cli 

```
gem install fir-cli
fir help 
```