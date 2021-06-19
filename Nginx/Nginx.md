#### 实现简单的认证

使用命令 htpasswd 添加用户文件和创建用户

```
htpasswd -bc .passwd webuser Pswd123
```

修改 nginx 配置文件，可以实现对 http, server, location 的认证

```
location / {
    auth_basic           "closed site";
    auth_basic_user_file .passwd;
}
```



#### 配置文件下载服务器

在 nginx 文件中添加以下 server

```
server {
        listen       200;
        server_name  download.example.com;
		limit_rate 2m;
        location / {
        		root /data/download;
                autoindex on;
                autoindex_exact_size off;
                autoindex_localtime on;
        }
}
```



#### 限制最大连接数

**连接周期 ** 从客户端发送请求开始，到客户端接收到数据结束

可设定的范围

- http
- server
- location

可设定的类型

- 设定指定范围内最大的连接数
- 设定指定范围内单个 IP 的最大连接数

配置实例

```
http {
    limit_conn_zone $binary_remote_addr zone=perip:10m;
	limit_conn_zone $server_name zone=perserver:10m;

	server {
        limit_conn perip 10;
        limit_conn perserver 100;
	}
}
```



#### 设置最大处理速率

可设定的范围

- http

- server

- location

可设定类型

- 设定指定范围内最大的处理速率
- 设定指定范围内单个 IP 的处理速率

配置实例

```
http {
    limit_req_zone $binary_remote_addr zone=perip:10m rate=1r/s;
	limit_req_zone $server_name zone=perserver:10m rate=10r/s;

    server {
        limit_req zone=perip burst=5 nodelay;
        limit_req zone=perserver burst=10;
    }
}     
```

说明

- **burst** 设置最大的并发请求数，可设置大一些

- **nodelay** 如果设置了此参数，则超过的并发请求数默认返回 503，否则等待处理。
- **rate** 应设置为 **burst** 的整数倍 或 **burst** 为 **rate** 的整数倍



#### 配置文件模板

##### 主配置文件 nginx.conf

```
user  nginx;
worker_processes  4;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  65535;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main "$remote_addr | $http_x_forwarded_for | $time_local | $request | "
                    "$status | $body_bytes_sent | $request_body | $content_length | "
                    "$http_referer | $http_user_agent | $http_cookie | "
                    "$hostname | $upstream_addr | $upstream_response_time $request_time";  
    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  120s;

    gzip            on;
    gzip_min_length 1024;
    gzip_comp_level 5;
    gzip_proxied    expired no-cache no-store private auth;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;

    client_max_body_size 10M;
    client_body_buffer_size 10M;

    proxy_buffer_size 1024k;
    proxy_buffers 32 1024k;
    proxy_busy_buffers_size 1024k;
    proxy_set_header Host $host;
	proxy_set_header X-Real-IP $remote_addr;
	proxy_set_header Accept-Encoding "";
	proxy_http_version 1.1;
	proxy_read_timeout 120s;

    include /etc/nginx/conf.d/*.conf;
}
```

##### http 虚拟主机配置文件 http.conf

```
server {
    listen       80;
    server_name  example.org  www.example.org;
    
    access_log /var/log/nginx/example.access_log main;
    error_log  /var/log/nginx/example.error_log  warn;
    
    location / {
    	root html;
    	index index.html;
    }
}
```

##### https 虚拟主机配置文件 https.conf

```
server {
    listen 443;
    server_name example.org  www.example.org;
    ssl on;
    root html;
    index index.html index.htm;
    ssl_certificate   cert/a.pem;
    ssl_certificate_key  cert/a.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    
    error_log  /var/log/nginx/example.error_log  warn;
	access_log /var/log/nginx/example.access.log main;
	
    location / {
        root html;
        index index.html index.htm;
    }
}
```

##### 反向代理虚拟主机配置文件 upstream.conf

> 如果设置 proxy_redirect     off，如果通过浏览器访问 http://www.example.org，则浏览器中显示 http://backend。

```
upstream backend {
    server backup1.example.com:8080;
    server backup2.example.com:8080;
}

server {
	listen       80;
    server_name  example.org  www.example.org;
    
    error_log  /var/log/nginx/example.error_log  warn;
	access_log /var/log/nginx/example.access.log main;
	
    location / {
        proxy_pass http://backend;
        proxy_redirect     off;
        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_connect_timeout      120;
        proxy_send_timeout         120;
        proxy_read_timeout         120;
    }
}
```

##### http 转 https 、反向代理配置文件

```
server {
    listen       80;
    server_name  www.example.com;
    rewrite ^(.*) https://$server_name$1 permanent;
    access_log /var/log/nginx/example.access_log main;
    error_log  /var/log/nginx/example.error_log  warn;
}

server {
    listen       443 ssl;
    server_name  www.example.com;
    
    ssl_certificate ../cert/www.example.com.pem;
    ssl_certificate_key ../cert/www.example.com.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
    ssl_prefer_server_ciphers on;
    
    access_log /var/log/nginx/example.access_log main;
    error_log  /var/log/nginx/example.error_log  warn;

    location / {
        root /data/wwwroot;
        index index.html index.htm;
    }

    location ^~ /api {
        proxy_pass  http://127.0.0.1:8080;
        proxy_redirect          off;
        proxy_set_header    	Host             $host;
        proxy_set_header        X-Real-IP        $remote_addr;
        proxy_set_header        X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_connect_timeout   120;
        proxy_send_timeout      120;
        proxy_read_timeout      120;
    }
}
```

##### location rewrite 实现自动跳转到移动端

```
server {
	listen       80;
        server_name  www.example.com;
        
        error_log  /var/log/nginx/example.error_log  warn;
		access_log /var/log/nginx/example.access.log main;

        location / {
                if ($http_user_agent ~* (mobile|nokia|iphone|ipad|android|samsung|htc|blackberry)) {
                        rewrite ^/(.*) /m$1;
                }
      
                proxy_pass http://localhost:9090;
                proxy_redirect     off;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }

        location ^〜 /m {
                proxy_pass http://localhost:9090;
                proxy_redirect     off;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }
}
```

##### 文件下载虚拟主机

```
server {
	listen 80;
	server_name download.example.com;

	autoindex on;
	autoindex_exact_size off;
	autoindex_localtime on;
	
	error_log  /var/log/nginx/example.error_log  warn;
	access_log /var/log/nginx/example.access.log main;

	location / {
		root /software;
		allow 14.153.52.0/24;
		allow 14.153.53.0/24;
		allow 14.153.54.0/24;
		allow 14.153.55.0/24;
        deny  all;
	}
}
```





#### Nginx 反向代理加 '/' 和不加 '/' 的区别

情况1

```
server {
    listen 80;
    server_name localhost;
    location / {
        root /var/www/html;
        index index.html;
    }

    location /proxy/ {
        proxy_pass http://192.168.1.5:8090/;
    }
}
```

> 这样，访问http://192.168.1.23/proxy/就会被代理到http://192.168.1.5:8090/。p匹配的proxy目录不需要存在根目录/var/www/html里面
> 注意，终端里如果访问http://192.168.1.23/proxy（即后面不带"/"），则会访问失败！因为proxy_pass配置的url后面加了"/"

情况2

```
server {
    listen 80;
    server_name localhost;
    location / {
        root /var/www/html;
        index index.html;
    }

    location  /proxy/ {
        proxy_pass http://192.168.1.5:8090;
    }
}
```

> 那么访问http://192.168.1.23/proxy或http://192.168.1.23/proxy/，都会失败！
> 这样配置后，访问http://192.168.1.23/proxy/就会被反向代理到http://192.168.1.5:8090/proxy/

情况3

```
server {
    listen 80;
    server_name localhost;
    location / {
        root /var/www/html;
        index index.html;
    }

    location /proxy/ {
        proxy_pass http://192.168.1.5:8090/haha/;
    }
}
```

> 这样配置的话，访问http://103.110.186.23/proxy/代理到http://192.168.1.5:8090/haha/

情况4

```
server {
    listen 80;
    server_name localhost;
    location / {
        root /var/www/html;
        index index.html;
    }

    location  /proxy/ {
        proxy_pass http://192.168.1.5:8090/haha;
    }
}
```

> 上面配置后，访问http://192.168.1.23/proxy/index.html就会被代理到http://192.168.1.5:8090/hahaindex.html
> 同理，访问http://192.168.1.23/proxy/test.html就会被代理到http://192.168.1.5:8090/hahatest.html

情况5

```
server {
    listen 80;
    server_name localhost;
    location / {
        root /var/www/html;
        index index.html;
    }

    location  /proxy {
        proxy_pass http://192.168.1.5:8090/haha;
    }
}
```

> 上面配置后，访问http://192.168.1.23/proxy/index.html就会被代理到http://192.168.1.5:8090/haha/index.html
> 同理，访问http://192.168.1.23/proxy/test.html就会被代理到http://192.168.1.5:8090/haha/test.html



#### 配置 url 重写

> url重写是指通过配置conf文件，以让网站的url中达到某种状态时则定向/跳转到某个规则，比如常见的伪静态、301重定向、浏览器定向等

**rewrite**

语法

在配置文件的`server`块中写，如：

```undefined
server {    rewrite 规则 定向路径 重写类型;}
```

规则：可以是字符串或者正则来表示想匹配的目标url

定向路径：表示匹配到规则后要定向的路径，如果规则里有正则，则可以使用`$index`来表示正则里的捕获分组

重写类型：

> last ：相当于Apache里德(L)标记，表示完成rewrite，浏览器地址栏URL地址不变
>
>  break；本条规则匹配完成后，终止匹配，不再匹配后面的规则，浏览器地址栏URL地址不变
>
> redirect：返回302临时重定向，浏览器地址会显示跳转后的URL地址
>
> permanent：返回301永久重定向，浏览器地址栏会显示跳转后的URL地址

简单例子

```undefined
server {    
	# 访问 /last.html 的时候，页面内容重写到 /index.html 中    
	rewrite /last.html /index.html last;  
    
	# 访问 /break.html 的时候，页面内容重写到 /index.html 中，并停止后续的匹配    
	rewrite /break.html /index.html break; 
    
	# 访问 /redirect.html 的时候，页面直接302定向到 /index.html中    
	rewrite /redirect.html /index.html redirect;   
    
	# 访问 /permanent.html 的时候，页面直接301定向到 /index.html中    
	rewrite /permanent.html /index.html permanent;    
	
	# 把 /html/*.html => /post/*.html ，301定向    
	rewrite ^/html/(.+?).html$ /post/$1.html permanent;    
	
	# 把 /search/key => /search.html?keyword=key   
    rewrite ^/search\/([^\/]+?)(\/|$) /search.html?keyword=$1 permanent;
}
```

last和break的区别

因为301和302不能简单的只返回状态码，还必须有重定向的URL，这就是return指令无法返回301,302的原因了。这里 last 和 break 区别有点难以理解：

> last一般写在server和if中，而break一般使用在location中
>
> last不终止重写后的url匹配，即新的url会再从server走一遍匹配流程，而break终止重写后的匹配
>
> break和last都能组织继续执行后面的rewrite指令

在`location`里一旦返回`break`则直接生效并停止后续的匹配`location`

```undefined
server {    
	location / {        
		rewrite /last/ /q.html last;        
		rewrite /break/ /q.html break;    
	}    
	location = /q.html {
    	return 400;    
    }
}
```

访问`/last/`时重写到`/q.html`，然后使用新的`uri`再匹配，正好匹配到`locatoin = /q.html`然后返回了`400`

访问`/break`时重写到`/q.html`，由于返回了`break`，则直接停止了

**if 判断**

只是上面的简单重写很多时候满足不了需求，比如需要判断当文件不存在时、当路径包含xx时等条件，则需要用到`if`

语法

```undefined
if (表达式) {}
```

> 当表达式只是一个变量时，如果值为空或任何以0开头的字符串都会当做false
>
> 直接比较变量和内容时，使用=或!=
>
> ~正则表达式匹配，~*不区分大小写的匹配，!~区分大小写的不匹配

一些内置的条件判断：

> -f和!-f用来判断是否存在文件
>
> -d和!-d用来判断是否存在目录
>
> -e和!-e用来判断是否存在文件或目录
>
> -x和!-x用来判断文件是否可执行

内置的全局变量

```gams
$args ：这个变量等于请求行中的参数，同$query_string。
$content_length ： 请求头中的Content-length字段。
$content_type ： 请求头中的Content-Type字段。
$document_root ： 当前请求在root指令中指定的值。
$host ： 请求主机头字段，否则为服务器名称。
$http_user_agent ： 客户端agent信息$http_cookie ： 客户端cookie信息
$limit_rate ： 这个变量可以限制连接速率。
$request_method ： 客户端请求的动作，通常为GET或POST。
$remote_addr ： 客户端的IP地址。
$remote_port ： 客户端的端口。
$remote_user ： 已经经过Auth Basic Module验证的用户名。
$request_filename ： 当前请求的文件路径，由root或alias指令与URI请求生成。
$scheme ： HTTP方法（如http，https）。
$server_protocol ： 请求使用的协议，通常是HTTP/1.0或HTTP/1.1。
$server_addr ： 服务器地址，在完成一次系统调用后可以确定这个值。
$server_name ： 服务器名称。
$server_port ： 请求到达服务器的端口号。
$request_uri ： 包含请求参数的原始URI，不包含主机名，如：”/foo/bar.php?arg=baz”。
$uri ： 不带请求参数的当前URI，$uri不包含主机名，如”/foo/bar.html”。
$document_uri ： 与$uri相同。
```

如：

```stylus
访问链接是：http://localhost:88/test1/test2/test.php 网站路径是：/var/www/html$host：localhost$server_port：88$request_uri：http://localhost:88/test1/test2/test.php$document_uri：/test1/test2/test.php$document_root：/var/www/html$request_filename：/var/www/html/test1/test2/test.phpstylus
```

例子

```undefined
# 如果文件不存在则返回400
if (!-f $request_filename) {
	return 400;
}
# 如果host不是xuexb.com，则301到xuexb.com中
if ( $host != 'xuexb.com' ){
	rewrite ^/(.*)$ https://xuexb.com/$1 permanent;
}
# 如果请求类型不是POST则返回405
if ($request_method = POST) {
	return 405;
}
# 如果参数中有 a=1 则301到指定域名
if ($args ~ a=1) {
	rewrite ^ http://example.com/ permanent;
}
```

在某种场景下可结合`location`规则来使用，如：

```undefined
# 访问 /test.html 时
location = /test.html {
	# 默认值为xiaowu    
	set $name xiaowu;    
	# 如果参数中有 name=xx 则使用该值    
	if ($args ~* name=(\w+?)(&|$)) {
    	set $name $1;    
    }    
    # 301
    rewrite ^ /$name.html permanent;
}
```

上面表示：

> /test.html => /xiaowu.html
>
> /test.html?name=ok => /ok.html?name=ok

**location**

语法

在`server`块中使用，如：

```undefined
server {
	location 表达式 {
    }
}
```

location表达式类型

> 如果直接写一个路径，则匹配该路径下的
>
> ~ 表示执行一个正则匹配，区分大小写
>
> ~* 表示执行一个正则匹配，不区分大小写
>
> ^~ 表示普通字符匹配。使用前缀匹配。如果匹配成功，则不再匹配其他location。
>
> = 进行普通字符精确匹配。也就是完全匹配。

优先级

1. 等号类型（=）的优先级最高。一旦匹配成功，则不再查找其他匹配项。
2. ^~类型表达式。一旦匹配成功，则不再查找其他匹配项。
3. 正则表达式类型（~ ~*）的优先级次之。如果有多个location的正则能匹配的话，则使用正则表达式最长的那个。
4. 常规字符串匹配类型。按前缀匹配。

例子 - 假地址掩饰真地址

```nginx
server {    
    # 用 xxoo_admin 来掩饰 admin    
    location / {        
        # 使用break拿一旦匹配成功则忽略后续location        
        rewrite /xxoo_admin /admin break;    
    }    
    # 访问真实地址直接报没权限    
    location /admin {        
        return 403;    
    }
}
```

**参考博文**：https://xuexb.com/post/nginx-url-rewrite.html



#### 问题案例

##### 反向代理出现循环

目的：通过该配置实现自动跳转到移动端页面

问题：uri login 出现循环

![image-20201019181947059](Nginx.assets/image-20201019181947059.png)

分析原因：由于后端设置了404自动跳转到 /login, 而又不存在 /m/login。

解决方法：使用 proxy_redirect 将后端的重定向重写。 

源配置文件如下

```
server {
        listen       80;
        server_name  test.example.net;

        location / {
                if ($http_user_agent ~* (mobile|nokia|iphone|ipad|android|samsung|htc|blackberry)) {
                        rewrite ^/(.*) /m$1;
                }

                proxy_pass http://localhost:9090;
                proxy_redirect     off;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }

        location /m {
                proxy_pass http://localhost:9090;
                proxy_redirect     off;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }
}
```

修改后的配置文件

```
server {
        listen       80;
        server_name  test.example.net;

        location / {
                if ($http_user_agent ~* (mobile|nokia|iphone|ipad|android|samsung|htc|blackberry)) {
                        rewrite ^/(.*) /m$1;
                }

                proxy_pass http://localhost:9090;
                proxy_redirect     off;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }

        location /m {
                proxy_pass http://localhost:9090;
                proxy_redirect     http://$server_name/login http://$server_name;
                proxy_set_header   Host             $host;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_connect_timeout      120;
                proxy_send_timeout         120;
                proxy_read_timeout         120;
        }
}
```

##### 修改 nginx 启动用户导致 springboot 接口文档访问不了

> 使用了反向代理

错误信息

```
net::ERR_INCOMPLETE_CHUNKED_ENCODING 200
```

原因：新启动的用户没有缓存文件夹的权限

```
$ ll /var/cache/nginx
total 20
drwx------  2 nginx root 4096 Feb 19 16:44 client_temp
drwx------  2 nginx root 4096 Feb  1 12:01 fastcgi_temp
drwx------ 12 nginx root 4096 Feb  1 12:15 proxy_temp
drwx------  2 nginx root 4096 Feb  1 12:01 scgi_temp
drwx------  2 nginx root 4096 Feb  1 12:01 uwsgi_temp

```

解决方法：

1、删除缓存文件夹，重启 nginx

2、恢复原来的账号启动 nginx



#### 方案

##### 通过 Nginx 实现日志下载

> 说明：用户通过主 Nginx 服务器下载日志，主 Nginx 服务器通过反向代理到生成日志文件服务器上的 Nginx 下载日志。

主 Nginx 服务器 nginx 配置文件 download-log.conf

> 注意: 浏览器中服务器访问 http://logs.example.org/jpark-test/data/logs/jparklogs/jpark-gem-machineg 相当于服务器 http://jpark-test-logs.lingfannao.net/jpark-gem-machineg

```
server {
    listen       80;
    server_name  logs.example.org;
    
    location /jpark-test/data/logs/jparklogs/jpark-gem-machineg {
        proxy_pass http://jpark-test-logs.lingfannao.net/jpark-gem-machineg;
        proxy_set_header   Host             "jpark-test-logs.lingfannao.net";
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_connect_timeout      120;
        proxy_send_timeout         120;
        proxy_read_timeout         120;
    }
}

```

生成日志服务器 nginx 配置文件 download-log.conf

- 新增虚拟主机方式，需要新增域名

```
server {
	listen 80;
	server_name jpark-test-logs.lingfannao.net;

	autoindex on;
	autoindex_exact_size off;
	autoindex_localtime on;

	gzip            on;
   	gzip_min_length 1024;
    gzip_comp_level 9;
    gzip_proxied    expired no-cache no-store private auth;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;

	location /jpark-gem-machineg {
		alias /data/logs/jparklogs/jpark-gem-machineg;
		allow 113.104.246.161;
	    deny  all;
	}
}
```

- 在现有域名下添加


```
location ^~ /logs/wms {
		alias /data/logs/wms;
		
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
}
```



  