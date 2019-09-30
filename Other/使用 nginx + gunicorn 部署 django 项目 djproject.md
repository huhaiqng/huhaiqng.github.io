##### 安装 python 3.7

安装依赖包

```
yum install gcc openssl-devel bzip2-devel libffi-devel mysql-devel python-devel
```

安装 python

```
cd /usr/src
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
tar xzf Python-3.7.3.tgz
cd Python-3.7.3
./configure --enable-optimizations
make altinstall
```

检查安装结果

```
python3.7 -V
```

##### 更新 pip

```
pip3.7 install --upgrade pip
```

##### 安装 django

```
pip install django
```

##### 安装 python 模块

```
pip install mysqlclient dwebsocket paramiko 
```

##### 准备项目文件

将项目 djproject 上 git clone 到 /usr/local

```
cd /usr/local
git clone https://github.com/huhaiqng/djproject.git
```

复制静态文件到项目根目录下

```
cd /usr/local/djproject
python3.7 manage.py collectstatic
```

##### 安装 gunicorn 和启动实例

```
cd /usr/local/djproject
pip install gunicorn
gunicorn djproject.wsgi:application \
-b 0.0.0.0:8080 \
-k gthread --threads 10 -w 4 \
--max-requests 4096 \
-p /tmp/gunicorn.pid \
--access-logfile /var/log/gunicorn-access.log \
--error-logfile /var/log/gunicorn-error.log \
--daemon
```

##### 配置 nginx 虚拟主机

```
upstream django {
    server 188.188.1.151:8080;
}
server {
    listen      9090;
    server_name localhost; 
    charset     utf-8;

    location /media  {
    }

    location /static {
        root /usr/local/djproject/;
    }

    location / {
        proxy_pass    http://django;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

