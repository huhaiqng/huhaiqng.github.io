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

##### 安装 php

> 配置文件: /etc/php.ini
>
> php-fpm配置文件: /etc/php-fpm.conf

```
yum install -y php php-fpm php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-odbc php-pear php-xml php-xmlrpc php-mbstring php-bcmath php-mhash
```

参考博文：<https://www.tecmint.com/install-php-5-6-on-centos-7/>

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

