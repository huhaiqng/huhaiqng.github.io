1、下载代码

```
git clone https://github.com/YOURLS/YOURLS.git
```

2、将user目录下的config-sample.php 重命名 为 config.php

3、修改config.php里面的配置参数 （linux上注意：config.php这个文件权限最好跟启动Web服务器用户一致，不然可能加密密码保存不了）

```
define( 'YOURLS_DB_USER', 'root' );
define( 'YOURLS_DB_PASS', '123456' );
define( 'YOURLS_DB_NAME', 'yourls' );
define( 'YOURLS_DB_HOST', 'localhost' );
define( 'YOURLS_DB_PREFIX', 'yourls_' );
//上面是数据信息不用多说
define( 'YOURLS_SITE', 'http://test.com' ); //你自己服务器的域名 用最短的，短地址也是基于这个生成。
define( 'YOURLS_HOURS_OFFSET', '+8'); 　　　//时区偏移　
define( 'YOURLS_LANG', 'zh_CN' ); 　　　　　//这个语言默认是英文，没有中文包，需要自己去 https://github.com/guox/yourls-zh_CN/下载,放到 user/languages 里面　
define( 'YOURLS_UNIQUE_URLS', true );　　　//短地址是否唯一　
define( 'YOURLS_PRIVATE', true );         //是否私有，如果私有的，则进行api调用生成短地址时需要传递用户名和密码
define( 'YOURLS_COOKIEKEY', 'A2C7&H~r80pTps{nIfI8VFpTxnfF3c)j@J#{nDUh' );//加密cookie 去 http://yourls.org/cookie 获取
$yourls_user_passwords = array(
    'admin' => '123456' /* Password encrypted by YOURLS */ ,  //用户名=>密码  可填多个  登录成功后这里的明文密码会被加密
    );
define( 'YOURLS_DEBUG', false );　　　　　　//是否开启调试　　
define( 'YOURLS_URL_CONVERT', 62 );　　　　//使用36进制 还是62进制  这个最好一开始设好不要修改，避免地址冲突，建议62进制
$yourls_reserved_URL = array(
    'porn', 'faggot', 'sex', 'nigger', 'fuck', 'cunt', 'dick',  //排除一下短地址，这些地址是不会生成的
);
```

4、根目录下创建文件  .htaccess 文件

```
#.htaccess 文件内容，如果是根目录下  http://yoursite/ 
# BEGIN YOURLS
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^.*$ /yourls-loader.php [L]
</IfModule>
# END YOURLS
```

5、创建 Dockerfile

> 开启 apache 重写和 安装 php pdo_mysql 插件

```
FROM php:7.4.28-apache
COPY ./ /var/www/html
RUN a2enmod rewrite && docker-php-ext-install pdo_mysql
```

6、生成镜像并启动

```
docker build -t yourls:v1.0 .
docker run -id -p 8088:80 -n yourls yourls:v1.0 
```

7、api接口生成   

http://域名/yourls-api.php?username=用户名&password=密码&url=源地址&action=shorturl&format=json



参考文档: https://www.cnblogs.com/myIvan/p/10582849.html