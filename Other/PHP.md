##### 安装 epel 和 remi 源

```
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y remi-release-7.rpm
```

##### 安装 yum 管理工具

```
yum install -y yum-utils
```

##### 启用 remi-php

```
# 安装 php5.6
yum-config-manager --enable remi-php56
# 安装 php5.5
yum-config-manager --enable remi-php55   [Install PHP 5.5]
# 安装 php7.2
yum-config-manager --enable remi-php72   [Install PHP 7.2]
```

##### yum 安装 php

> 配置文件: /etc/php.ini
>
> php-fpm配置文件: /etc/php-fpm.conf

```
yum install -y php php-fpm php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-odbc php-pear php-xml php-xmlrpc php-mbstring php-bcmath php-mhash
```

参考博文：<https://www.tecmint.com/install-php-5-6-on-centos-7/>

##### 编译安装 php-7.4.30

> 不同版本的 php 编译参数不一致

安装依赖

```
yum install -y epel-release
yum install -y libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmcrypt-devel libmemcached-devel sqlite-devel oniguruma oniguruma-devel m4 autoconf
```

安装 libzip-1.2.0

> 装完了之后找一下`/usr/local/lib`下有没有`pkgconfig`目录，有的话执行命令`export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/"`指定`PKG_CONFIG_PATH`

```
wget https://libzip.org/download/libzip-1.2.0.tar.gz
tar -zxvf libzip-1.2.0.tar.gz
cd libzip-1.2.0
./configure
make && make install
```

编译

```
cd /usr/local/src/
wget https://www.php.net/distributions/php-7.4.30.tar.gz
cd php-7.4.30

./configure \
--prefix=/usr/local/php \
--with-config-file-path=/etc \
--disable-debug \
--disable-rpath \
--enable-bcmath \
--enable-calendar \
--enable-dom \
--enable-exif \
--enable-fileinfo \
--enable-filter \
--enable-fpm \
--enable-ftp \
--enable-gd \
--enable-gd-jis-conv \
--enable-inline-optimization \
--enable-json \
--enable-mbregex \
--enable-mbstring \
--enable-mysqlnd-compression-support \
--enable-opcache \
--enable-pdo \
--enable-session \
--enable-shared \
--enable-shmop \
--enable-simplexml \
--enable-soap \
--enable-sockets \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--with-bz2 \
--with-cdb \
--with-curl \
--with-fpm-group=www \
--with-fpm-user=www \
--with-freetype \
--with-gettext \
--with-gmp \
--with-iconv \
--with-jpeg \
--with-mhash \
--with-mysqli=mysqlnd \
--with-openssl \
--with-openssl-dir \
--with-pdo-mysql=mysqlnd \
--with-pear \
--with-readline \
--with-webp \
--with-xmlrpc \
--with-xpm \
--with-xsl \
--with-zip \
--with-zlib \
--with-zlib-dir
```

安装

```
make && make install

cp php.ini-production /etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm.service
```

启动

```
systemctl start php-fpm
```

##### 添加 php-7.4.30  gd 模块

编译

> php-7.4.30 为源码包

```
cd /usr/local/src/php-7.4.30/ext/gd/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-freetype --with-jpeg --enable-gd 
make && make install
```

在 /etc/php.ini 中添加

```
extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20190902/gd.so
```

重启

```
systemctl restart php-fpm
```

##### 添加 php-7.4.30  ldap 模块

安装 openldap

```
yum install -y openldap-devel
cp -frp /usr/lib64/libldap* /usr/lib
```

编译

```
cd /usr/local/src/php-7.4.30/ext/ldap
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
```

在 /etc/php.ini 中添加

```
extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20190902/ldap.so
```

重启

```
systemctl restart php-fpm
```

##### 配置

> 配置文件: /etc/php-fpm.d/www.conf

修改 php-fpm 启动用户

```
user = apache
group = apache
```

##### 常用命令

> 查看 pid 文件: grep pid /etc/php-fpm.conf

启动 php-fpm

```
mkdir /run/php-fpm/
php-fpm
```

关闭 php-fpm

```
kill -INT `cat /run/php-fpm/php-fpm.pid`
```

重启 php-fpm

```
kill -USR2 `cat /run/php-fpm/php-fpm.pid`
```

##### nginx 反向代理 php-fpm

```
server {
    listen       80;
    server_name  phpdemo.example.org;
    
    access_log /var/log/nginx/phpdemo.access_log main;
    error_log  /var/log/nginx/phpdemo.error_log  warn;
    root       /data/phpdemo;
    
    location / {
        index  index.php index.html index.htm;
    }
    
    location ~ \.php$ {
    	fastcgi_pass    127.0.0.1:9000;
	    fastcgi_index   index.php;
	    fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;
	    fastcgi_param   SCRIPT_NAME        $fastcgi_script_name;
	    include         fastcgi_params;
    }
}
```

