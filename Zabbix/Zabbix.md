#### 编译安装 zabbix

##### 安装 nginx

安装依赖包

```
yum install -y gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel
```

安装

```
# 下载安装包
cd /usr/local/src
wget http://nginx.org/download/nginx-1.22.0.tar.gz
tar zxvf nginx-1.22.0.tar.gz
cd nginx-1.22.0

useradd -s /sbin/nologin www
mkdir /var/cache/nginx

#生成makefile文件
./configure \
--prefix=/usr/local/nginx \
--sbin-path=/usr/sbin/nginx \
--error-log-path=/data/log/nginx/error.log \
--http-log-path=/data/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=www \
--group=www \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module 
```

修改配置 user 改为 www

```
user  www;
```

创建 vhost

```	
server {
    listen       80;
    server_name  zabbix.example.com;

    root /data/html/zabbix;

    location / {
        index index.php;
    }

    location ~ \.php$ {
        try_files $uri = 404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

启动

```
nginx
```

测试

```
nginx -v
```

##### 安装 php

安装依赖

```
yum install -y epel-release
yum install -y libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmcrypt-devel libmemcached-devel sqlite-devel oniguruma oniguruma-devel
```

编译

> 不要随意更改 php 版本

```
cd /usr/local/src
wget https://www.php.net/distributions/php-7.2.34.tar.gz
tar zxvf php-7.2.34.tar.gz
cd php-7.2.34

./configure \
--prefix=/usr/local/php \
--with-config-file-path=/etc \
--enable-fpm \
--enable-inline-optimization \
--disable-debug \
--disable-rpath \
--enable-shared \
--enable-soap \
--with-libxml-dir \
--with-xmlrpc \
--with-openssl \
--with-mcrypt \
--with-mhash \
--with-pcre-regex \
--with-zlib \
--enable-bcmath \
--with-iconv \
--with-bz2 \
--enable-calendar \
--with-curl \
--with-cdb \
--enable-dom \
--enable-exif \
--enable-fileinfo \
--enable-filter \
--with-pcre-dir \
--enable-ftp \
--with-gd \
--with-openssl-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib-dir \
--with-freetype-dir \
--enable-gd-native-ttf \
--enable-gd-jis-conv \
--with-gettext \
--with-gmp \
--with-mhash \
--enable-json \
--enable-mbstring \
--enable-mbregex \
--enable-mbregex-backtrack \
--with-libmbfl \
--with-onig \
--enable-pdo \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-zlib-dir \
--with-readline \
--enable-session \
--enable-shmop \
--enable-simplexml \
--enable-sockets \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-wddx \
--with-libxml-dir \
--with-xsl \
--enable-zip \
--enable-mysqlnd-compression-support \
--with-pear \
--enable-opcache

make && make install

cp php.ini-production /etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
```

设置环境变量  .bash_profile

```
PATH=$PATH:/usr/local/php/bin
export PATH
```

修改启动用户 /usr/local/php/etc/php-fpm.d/www.conf

```
user = www
group = www
```

命令启动

```
/usr/local/php72/sbin/php-fpm
```

service 管理

```
service php-fpm start　　#启动
service php-fpm stop　　 #停止
service php-fpm restart #重启
```

##### 安装 MySQL

解压安装包

```
cd /usr/local/
tar zxvf src/mysql-8.0.29-el7-x86_64.tar.gz 
mv mysql-8.0.29-el7-x86_64/ mysql
```

创建 配置文件 my.cnf

```
[mysqld]
datadir=/data/mysql
socket=/tmp/mysql.sock
symbolic-links=0
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/data/mysql/mysqld.pid
```

创建用户

```
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
```

初始化

> 会输出临时密码

```
bin/mysqld --defaults-file=/usr/local/mysql/my.cnf --initialize --user=mysql
```

启动

```
bin/mysqld_safe --defaults-file=/usr/local/mysql/my.cnf --user=mysql &
```

修改密码

```
ALTER USER root@'localhost' IDENTIFIED BY 'MySQL8.0';
```

关闭

```
bin/mysqladmin -u root -p shutdown
```

##### 安装 zabbix

安装依赖

```
yum install gcc gcc-c++ make unixODBC-devel net-snmp-devel libssh2-devel OpenIPMI-devel libevent-devel pcre-devel libcurl-devel curl-* net-snmp* libxml2-* wget tar mysql-devel -y 
```

编译

```
cd /usr/local/src/
tar zxvf zabbix-6.0.5.tar.gz 
cd zabbix-6.0.5
mkdir -p /usr/local/zabbix
./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2
make && make install

cp misc/init.d/fedora/core/zabbix_* /etc/init.d/
ll -d /etc/init.d/zabbix_*
chmod +x /etc/init.d/zabbix_*
```

创建用户

```
groupadd --system zabbix
useradd --system -g zabbix -d /usr/lib/zabbix -s /sbin/nologin -c "Zabbix Monitoring System" zabbix
```

创建数据库

> 数据库字符集要正确

```
create user zabbix@'%' identified WITH mysql_native_password by 'MySQL8.0';
create database zabbix CHARACTER SET utf8mb4_bin COLLATE utf8mb4_bin;
grant all on zabbix.* to zabbix@'%';
flush privileges;
```

导入数据

```
mysql -u zabbix -p'MySQL8.0' zabbix < /usr/local/src/zabbix-6.0.5/database/mysql/schema.sql
mysql -u zabbix -p'MySQL8.0' zabbix < /usr/local/src/zabbix-6.0.5/database/mysql/images.sql
mysql -u zabbix -p'MySQL8.0' zabbix < /usr/local/src/zabbix-6.0.5/database/mysql/data.sql
```

修改 server 配置文件 zabbix_server.conf

```
DBHost=192.168.1.200
DBName=zabbix
DBUser=zabbix
DBPassword=MySQL8.0
```

启动

```
# server
/usr/local/zabbix/sbin/zabbix_server -c /usr/local/zabbix/etc/zabbix_server.conf
# agent
/usr/local/zabbix/sbin/zabbix_agentd
```

拷贝 ui

```
cp -R /usr/local/src/zabbix-6.0.5/ui /data/html/zabbix
chown -R www.www /data/html/zabbix
```

#### yum 安装 zabbix

> 包地址：http://repo.zabbix.com/zabbix/

##### 安装 centos 7 zabbix yum 源

```
# 3.4
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
# 5.0
rpm -ivh http://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
```

##### 安装 server

##### 安装 agent

安装

```
yum install -y zabbix-agent
```

修改配置文件 /etc/zabbix/zabbix_agentd.conf

```
Server=192.168.40.201
ServerActive=192.168.40.201
Hostname=centos7-001
```

##### 安装 proxy

> 只需 proxy 能够连接 server 的端口，无需 server 能够连接 proxy 的端口, proxy 主动上传数据。
>
> Hostname 必须与 web 上的 “agent代理程序名称” 一致。
>
> proxy 必须能解析 agent  Hostname 。
>
> 主机添加流程：web 新增 -> 重启 proxy (拉取配置) -> 启动(重启) agent 。

安装

```
yum install -y zabbix-proxy-mysql
gzip -d /usr/share/doc/zabbix-proxy-mysql-3.4.15/schema.sql.gz
mysql -u zabbix -p zabbix < schema.sql
```

修改配置文件 /etc/zabbix/zabbix_proxy.conf

```
Server=47.106.230.34
# 在 hosts 添加解析
Hostname=zabbix-proxy
DBHost=192.168.40.185
DBName=zabbix
DBUser=zabbix
DBPassword=Zabbix@139
```

启动

```
systemctl start zabbix-proxy
```

##### 安装 web