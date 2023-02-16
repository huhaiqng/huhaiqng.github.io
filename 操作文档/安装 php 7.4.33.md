##### 安装 php

安装依赖

> 服务器使用的是 oniguruma5php-6.9.6-1.el7.remi.x86_64 和 oniguruma5php-devel-6.9.6-1.el7.remi.x86_64。需要使用一样的，否则报错 ”libonig.so.5 文件无法找到”。

```
yum install -y epel-release
yum install -y libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c xmlrpc-c-devel libicu-devel libmcrypt-devel libmemcached-devel sqlite-devel oniguruma oniguruma-devel m4 autoconf gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel wget net-tools lrzsz vim libwebp-devel
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
wget https://www.php.net/distributions/php-7.4.33.tar.gz
tar zxvf php-7.4.33.tar.gz
cd php-7.4.33

./configure \
--prefix=/usr/local/php7 \
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
--enable-intl \
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

修改 /usr/lib/systemd/system/php-fpm.service

```
ProtectSystem=false
```

设置环境变量 .bash_profile

```
PATH=$PATH:/usr/local/php/bin
export PATH
```

修改启动用户 /usr/local/php/etc/php-fpm.d/[www.conf](http://www.conf/)

```
user = www
group = www
pm.max_children = 10
```

修改 /etc/php.ini

```
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
```

systemctl 启动

```
systemctl start php-fpm
systemctl enable php-fpm
```

命令启动

```
/usr/local/php/sbin/php-fpm
```



##### 安装 ssh2 扩展

下载

```
wget http://www.libssh2.org/download/libssh2-1.4.2.tar.gz
wget http://pecl.php.net/get/ssh2-1.3.1.tgz
```

编译 libssh2

```
tar -zxvf libssh2-1.4.2.tar.gz
cd libssh2-1.4.2
./configure --prefix=/usr/local/libssh2
make && make install
```

编译 ssh

```
tar zxvf ssh2-1.3.1.tgz 
cd ssh2-1.3.1
/usr/local/php/bin/phpize
./configure --with-ssh2=/usr/local/libssh2 --with-php-config=/usr/local/php/bin/php-config
make
make install
```

php.ini 配置文件增加 extension=ssh2.so



##### 安装 redis 扩展

下载

```
wget https://pecl.php.net/get/redis-5.3.7.tgz
```

编译

```
tar zxvf redis-5.3.7.tgz 
cd redis-5.3.7
/usr/local/php/bin/phpize 
./configure --with-php-config=/usr/local/php/bin/php-config
make
make install
```

php.ini 配置文件增加 extension=redis.so



##### 添加 amqp(rabbitmq) 模块

安装 rabbitmq-c

> 编译后只有 lib64 目录，而安装 amqp 搜索的目录是 lib，所有需要拷贝 lib64 到 lib。
>
> 否则报错: `/usr/bin/ld: cannot find -lrabbitmq`

```
yum install -y cmake
tar zxvf rabbitmq-c-0.11.0.tar.gz 
cd rabbitmq-c-0.11.0
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/rabbitmq-c ..
cmake --build .  --target install
cd /usr/local/rabbitmq-c
cp -R lib64 lib
```

安装 amqp

```
yum install -y autoconf
tar zxvf amqp-1.11.0.tgz 
cd amqp-1.11.0
/usr/local/php/bin/phpize
./configure \
--with-php-config=/usr/local/php/bin/php-config \
--with-amqp \
--with-librabbitmq-dir=/usr/local/rabbitmq-c
make && make install
```

php.ini 配置文件增加 extension=amqp.so