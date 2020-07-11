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

- **nodelay ** 如果设置了此参数，则超过的并发请求数默认返回 503，否则等待处理。
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
    location / {
        root html;
        index index.html index.htm;
    }
}
```

##### 反向代理虚拟主机配置文件 upstream.conf

```
upstream backend {
    server backup1.example.com:8080;
    server backup2.example.com:8080;
}

server {
	listen       80;
    server_name  example.org  www.example.org;
    location / {
        proxy_pass http://backend;
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

