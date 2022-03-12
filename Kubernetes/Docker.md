#### 安装 docker

```
# 安装依赖包
yum install yum-utils device-mapper-persistent-data lvm2
# 配置yum 源
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装
yum install docker-ce docker-ce-cli containerd.io
# 配置
mkdir /etc/docker
# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# 启动
systemctl daemon-reload
systemctl enable docker
systemctl start docker
```



#### 常用命令

##### Docker

创建 docker

```
docker run -id <REPOSITORY:TAG>   
```

创建有端口映射的 docker

```
docker run -id -p 9090:9090 REPOSITORY:TAG
```

创建有目录映射的 docker

```
docker run -id -v /host_dir:/docker_dir REPOSITORY:TAG
```

登陆 docker

```
docker exec -it <CONTAINER ID> /bin/bash
```

查看所有已经创建的 docker

```
docker ps -a
```

查看正在运行的 docker

```
docker ps
```

删除 docker

```
docker rm <CONTAINER ID>
```

启动 docker

```
docker start <CONTAINER ID>
```

停止 docker

```
docker stop <CONTAINER ID>
```

查看 docker 创建详情

```
docker history 28bad97b3d94
```

##### 镜像

下载镜像

```
docker pull <REPOSITORY:TAG>
```

删除镜像

```
docker rmi <REPOSITORY:TAG>
```

生成镜像

```
docker build -t <REPOSITORY:TAG> .
```



#### 生成 Docker 镜像

##### 生成 jdk 1.8 镜像

创建 Dockerfile 文件

> 需要提前下载好 jdk-8u151-linux-x64.tar.gz

```
FROM centos:7.6.1810

ADD jdk-8u151-linux-x64.tar.gz /usr/local/

ENV JAVA_HOME /usr/local/jdk1.8.0_151
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN sh -c echo 'Asia/Shanghai' >/etc/timezone
```

生成镜像

```
docker build --no-cache -t oraclejdk:1.8 .
```

创建 docker

```
docker run -id oraclejdk:1.8
```

登陆 docker 测试 java 版本和时区

```
[root@gpsdb01 centos]# docker exec -it 8d76c676b4e9 /bin/bash
[root@8d76c676b4e9 /]# java -version
java version "1.8.0_151"
Java(TM) SE Runtime Environment (build 1.8.0_151-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.151-b12, mixed mode)
[root@8d76c676b4e9 /]# date
Wed Sep  4 18:25:53 CST 2019
```

##### 生成运行 jar 包的镜像

创建 Dockerfile

```
FROM oraclejdk:1.8
RUN mkdir /usr/local/eureka
ADD baipao-eureka.jar /usr/local/eureka
ENTRYPOINT ["java", "-jar", "/usr/local/eureka/baipao-eureka.jar"] 
```

生成镜像

```
docker build --no-cache -t eureka.jar:1.0 .
```

创建 docker

```
docker run -id -p 9090:9090 eureka.jar:1.0 
```

##### 生成 redis 镜像

创建 Dockerfile 文件

> redis.conf 下载地址 http://download.redis.io/redis-stable/redis.conf
>
> bind 和 requirepass 需要修改

```
FROM redis:6.0
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY redis.conf /usr/local/etc/redis/redis.conf
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
```

生成镜像

```
docker build --no-cache -t redis-cst:6.0 .
```

创建 docker

```
docker run -id -p 6379:6379 redis-cst:6.0
```

##### 生成 easyswoole3.3.x 镜像

> 在官方的基础上新增了自动启动和 /easyswoole 目录挂载到本地

Dockerfile

```
FROM easyswoole/easyswoole3:latest
VOLUME /easyswoole
ENTRYPOINT [ "sh", "-c", "php easyswoole start" ]
```

创建镜像

```
docker build -t easyswoole:3 .
```

创建容器

```
docker run -id -p 9501:9501 --mount source=easyswoole,target=/easyswoole easyswoole:3
```

创建 volume 路径

```
# docker volume ls
DRIVER              VOLUME NAME
local               easyswoole
# docker volume inspect easyswoole
[
    {
        "CreatedAt": "2021-01-15T15:06:14+08:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/opt/docker/volumes/easyswoole/_data",
        "Name": "easyswoole",
        "Options": {},
        "Scope": "local"
    }
]
```

创建软链接，方便更新

```
ln -s /opt/docker/volumes/easyswoole/_data /data/easyswoole
```



#### Docker Compose

##### 安装

```
# curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
```

##### 开始使用

创建实例程序文件 app.py

> host='redis' : redis 为 redis 的服务名，同一 docker-compose 的服务可以使用服务名进行通信。 

```
import time

import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)


def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
```

创建安装依赖文件 requirements.txt

```
flask
redis
```

创建应用 Dockerfile

> COPY . . : 把当前目录所有的文件拷贝到容器工作目录

```
FROM python:3.7-alpine
WORKDIR /code
ENV FLASK_APP app.py
ENV FLASK_RUN_HOST 0.0.0.0
RUN apk add --no-cache gcc musl-dev linux-headers
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . .
CMD ["flask", "run"]
```

创建 docker-compose.yml

```
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
  redis:
    image: "redis:alpine"
```

启动

```
docker-compose up -d
```

修改 docker-compose 文件，挂载盘和设置环境变量

```
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - .:/code
    environment:
      - FLASK_ENV=development
  redis:
    image: "redis:alpine"
```

更新

```
docker-compose up -d
```

##### 网络

> docker-compose 以 yml 文件所在的目录为单位创建网络
>
> 同一目录中的服务可以使用服务器互相通信

运行 mysql1 目录的服务

```
docker-compose -f /root/mysql1/compose-mysql.yml -d
```

生成 mysql1_default 网络

![image-20200713173851918](Docker.assets/image-20200713173851918.png)

运行 mysql2 目录的服务

```
docker-compose -f /root/mysql2/compose-mysql.yml up -d
```

生成 mysql2_default 网络

![image-20200713174046279](Docker.assets/image-20200713174046279.png)



#### Docker Compose 实例

##### 部署 MySQL

创建 yml 文件 compose-mysql.yml

> 主配置文件会包含 /etc/mysql/conf.d 目录中的配置文件

```
version: '3.1'
services:
  mysql-service:
    image: mysql:5.7.30
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=MySQL5.7
    ports:
      - 3366:3306
    volumes:
      - /data/mysql-data:/var/lib/mysql
      - /data/mysql-conf:/etc/mysql/conf.d
```

创建 MySQL 配置文件 /data/mysql-conf/config-mysql.cnf

```
[mysqld]
# general
server_id=1
max_connections=2000
table_open_cache=10000
open_files_limit=65536
character-set-server=utf8mb4
skip_name_resolve=on
gtid_mode=on
enforce_gtid_consistency=on
tmp_table_size=64M
max_heap_table_size=64M
max_allowed_packet=64M
innodb_data_file_path=ibdata1:12M:autoextend:max:4096M
range_optimizer_max_mem_size=64M
read_rnd_buffer_size=8M
join_buffer_size=8M
sort_buffer_size=8M

# log
log_timestamps=system
binlog_format=row
log_bin=mysql-bin
slow_query_log=1
long_query_time=2
slow_query_log_file=slow.log
expire-logs-days=7
innodb_flush_log_at_trx_commit=1
sync_binlog=1

# innodb
innodb_buffer_pool_size=2G
innodb_log_buffer_size=128M
innodb_log_file_size=1G
innodb_read_io_threads=8
innodb_write_io_threads=8
```

运行

```
docker-compose -f compose-mysql.yml up -d
```

重启

```
docker-compose -f compose-mysql.yml restart
```

停止

```
docker-compose -f compose-mysql.yml stop
```

删除

```
docker-compose -f compose-mysql.yml rm
```

##### 部署 mindoc

> mindoc 的数据保存在 MySQL 或 sqlite3
>
> 需要备份数据库和 uploads 目录

docker-compose.yml 文件

```
MinDoc_New:
  image: registry.cn-hangzhou.aliyuncs.com/mindoc/mindoc:v2.0-beta.2
  privileged: false
  restart: always
  ports:
    - 8181:8181
  volumes:
    - /data/mindoc/database:/mindoc/database
    - /data/mindoc/uploads:/mindoc/uploads
  environment:
    - MINDOC_RUN_MODE=prod
    - MINDOC_DB_ADAPTER=sqlite3
    - MINDOC_DB_DATABASE=./database/mindoc.db
    - MINDOC_CACHE=true
    - MINDOC_CACHE_PROVIDER=file
    - MINDOC_ENABLE_EXPORT=false
    - MINDOC_BASE_URL=
    - MINDOC_CDN_IMG_URL=
    - MINDOC_CDN_CSS_URL=
    - MINDOC_CDN_JS_URL=
  dns:
    - 223.5.5.5
    - 223.6.6.6
```

##### 部署 zabbix 监控系统

创建 zabbix/docker-compose.yml

> 注意：没有挂载盘重新创建容器后修改会丢失，数据库中的数据也会丢失，会重新初始化数据。

```
version: '3.1'
services:
  server:
    image: zabbix/zabbix-server-mysql
    restart: always
    environment:
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=root
      - MYSQL_PASSWORD=MySQL5.7
    ports:
      - 10051:10051
    depends_on:
      - mysql
  web:
    image: zabbix/zabbix-web-nginx-mysql
    restart: always
    environment:
      - DB_SERVER_HOST=mysql
      - MYSQL_USER=root
      - MYSQL_PASSWORD=MySQL5.7
      - ZBX_SERVER_HOST=server
      - PHP_TZ=Asia/Shanghai
    ports:
      - 6060:8080
    depends_on:
      - mysql
      - server
  mysql:
    image: mysql:5.7.30
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=MySQL5.7
    ports:
      - 3366:3306
    volumes:
      - /data/mysql-data:/var/lib/mysql
      - /data/mysql-conf:/etc/mysql/conf.d
```

启动

> 访问地址：http://host-ip:6060 默认用户名 Admin，默认密码 zabbix

```
cd zabbix
docker-compose up -d
```

##### 部署 dubbo-admin

创建 docker-compose.yml 文件

```
version: '3'

services:
  zookeeper:
    image: zookeeper
    ports:
      - 2181:2181
  admin:
    image: apache/dubbo-admin
    depends_on:
      - zookeeper
    ports:
      - 8080:8080
    environment:
      - admin.registry.address=zookeeper://zookeeper:2181
      - admin.config-center=zookeeper://zookeeper:2181
      - admin.metadata-report.address=zookeeper://zookeeper:2181
```

启动

> 访问地址:  http://hostip:8080 

```
docker-compose up -d
```

##### 部署禅道

**方式1:** nginx + php-fpm

创建 docker-compose.yml 文件

```
version: "3.6"

services:
  phpfpm:
    image: bitnami/php-fpm:7.4-prod
    volumes:
      - /data/zentaopms:/app

  nginx:
    image: nginx:1.19.10
    volumes:
      - ./nginx-vhost.conf:/etc/nginx/conf.d/nginx-vhost.conf
      - /data/zentaopms:/app
    ports:
      - "88:90"
```

nginx-vhost.conf 文件

```
server {
    listen       90;
    server_name  example.org  www.example.org;

    root /app;

    location /www {
        index index.php;
    }

    location ~ \.php$ {
        try_files $uri = 404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass phpfpm:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

方式2: apache

创建 docker-compose.yml 文件

```
version: "3.6"

services:
  phpfpm:
    image: php:7.3-apache
    volumes:
      - /data/zentaopms:/var/www/html
    ports:
      - "80:80"
```

修改目录权限

```
chown -R 33:33 /data/zentaopms
```



#### Docker Swarm

##### 常用命令

开启 swarm 模式

> --advertise-addr: 配置 manager ip

```
docker swarm init --advertise-addr 192.168.99.100
```

查看加入集群命令

```
docker swarm join-token worker
```

加入集群

```
docker swarm join \
  --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
  192.168.99.100:2377
```

退出 swarm 模式

```
docker swarm leave
```

创建集群

```
docker stack deploy -f docker-compose.yml stackdemo
```

删除集群

```
docker stack rm stackdemo
```

列出集群

```
docker stack ls
```

查看集群

```
docker stack ps stackdemo
```



##### 部署 java 微服务集群

jar 信息文件 jar_info.txt

```
# 项目名	# 模块名		# 包名					# 端口号
zuul		hystrix-dashboard 	hystrix-dashboard-0.0.1-SNAPSHOT.jar    8910
zuul		product-service		product-service-0.0.1-SNAPSHOT.jar	2200
zuul		service-discovery	service-discovery-0.0.1-SNAPSHOT.jar	8260
zuul		user-service		user-service-0.0.1-SNAPSHOT.jar		2100
zuul		zuul-server		zuul-server-0.0.1-SNAPSHOT.jar 		8280
```

生成 docker 镜像脚本 build_jar_image.sh

```shell
#!/bin/bash
set -e
PROJECT_NAME=$1
MODULE_NAME=$2
TIME_TAG=$3

if [ $# -ne 3 ]; then
    echo "参数错误。正在执行方式: sh $0 PROJECT_NAME MODULE_NAME TIME_TAG"
    exit 1
fi

MODULE_COUNT=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/jar_info.txt | wc -l`

if [ ${MODULE_COUNT} -eq 0 ]; then
    echo "不存在 ${PROJECT_NAME} 项目"
    exit
fi

function create_dockerfile {
cat >/tmp/${MODULE_NAME}-dockerfile <<EOF
FROM mcr.microsoft.com/java/jdk:8-zulu-alpine
WORKDIR /data
ADD ${MODULE_NAME}/target/${JAR_NAME} /data/${MODULE_NAME}.jar
EOF
}

function build_image {
    MODULE_NAME=`echo ${MODULE_INFO} | awk '{print $2}'`
    JAR_NAME=`echo ${MODULE_INFO} | awk '{print $3}'`
    JAR_PORT=`echo ${MODULE_INFO} | awk '{print $4}'`
    IMAGE_NAME=harbor.huhaiqing.xyz/${PROJECT_NAME}/${MODULE_NAME}:${TIME_TAG}
    create_dockerfile
    docker build -t "${IMAGE_NAME}" -f /tmp/${MODULE_NAME}-dockerfile .
    docker push ${IMAGE_NAME}
}

if [ "${MODULE_NAME}" = "all" ]; then
    cat $(dirname $0)/jar_info.txt | grep "^${PROJECT_NAME}[[:space:]]\+" | while read MODULE_INFO
    do
        build_image
    done
else
    MODULE_INFO=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/jar_info.txt | grep "[[:space:]]\+${MODULE_NAME}[[:space:]]\+"`
    if [ -n "${MODULE_INFO}" ];then
        build_image
    else
        echo "项目 ${PROJECT_NAME} 的模块 ${MODULE_NAME} 不存在！"
    fi
fi
```

docker-compose.yml 文件

```yaml
version: "3.8"

services:
  hystrix-dashboard:
    image: harbor.huhaiqing.xyz/zuul/hystrix-dashboard:${TAG}
    entrypoint: ["java", "-jar", "hystrix-dashboard.jar"]
    deploy:
      replicas: 2
  product-service:
    image: harbor.huhaiqing.xyz/zuul/product-service:${TAG}
    entrypoint: ["java", "-jar", "product-service.jar"]
    deploy:
      replicas: 2
  service-discovery:
    image: harbor.huhaiqing.xyz/zuul/service-discovery:${TAG}
    ports:
      - "8260:8260"
    entrypoint: ["java", "-jar", "service-discovery.jar"]
    deploy:
      replicas: 2
  user-service:
    image: harbor.huhaiqing.xyz/zuul/user-service:${TAG}
    entrypoint: ["java", "-jar", "user-service.jar"]
    deploy:
      replicas: 2
    ports:
      - "2100:2100"
  zuul-server:
    image: harbor.huhaiqing.xyz/zuul/zuul-server:${TAG}
    entrypoint: ["java", "-jar", "zuul-server.jar"]
    ports:
      - "8280:8280"
    deploy:
      replicas: 2
```

启动集群

> --with-registry-auth: 拉取镜像需要认证, docker 

```shell
export TAG=20201109170037
docker stack deploy -c docker-compose.yml zuul --with-registry-auth
```

##### docker swarm 部署 wordpress

创建 docker-compose.yml 文件

> visualizer 用于查看容器的运行状态

```
version: "3"

services:
  wordpress:
    image: wordpress
    ports:
      - 80:80
    networks:
      - overlay
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
    deploy:
      mode: replicated
      replicas: 3

  db:
    image: mysql
    networks:
       - overlay
    volumes:
      - db-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    deploy:
      placement:
        constraints: [node.role == manager]

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]

volumes:
  db-data:
networks:
  overlay:
```

启动集群

```
docker stack deploy -c docker-compose.yml wordpress
```

##### 通过 node label 将服务部署到指定的节点

给节点添加 label

```
docker node update centos7-001 --label-add project=zuul
```

在 docker-compose.yml 指定部署节点

> node.labels.project

```
zuul-server:
    image: harbor.huhaiqing.xyz/zuul/zuul-server:${TAG}
    deploy:
      placement:
        constraints: [node.labels.project == zuul]
```



#### 管理

##### 实现非 root 用户运行 docker 命令

 将用户加入到 docker 组

```
gpasswd -a devops docker
```

重新登录用户即可执行 docker 命令

##### 配置镜像加速器

修改daemon配置文件 /etc/docker/daemon.json 来使用加速器

```
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://mw9jlg9p.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```



#### Dockerfile 中设置需要 bash 环境的启动命令

CMD

```
......
CMD bash -c 'cd /easyswoole ;php easyswoole start'
......
```

ENTRYPOINT

```
......
ENTRYPOINT [ "sh", "-c", "php easyswoole start" ]
......
```

