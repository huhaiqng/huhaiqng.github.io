### 安装

下载

```
curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

赋予执行权限

```
chmod +x /usr/local/bin/docker-compose
```

创建软链接

```
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```



### 教程

#####  1、创建 Dockerfile  文件

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

 ##### 2、创建 docker-compose.yml  文件

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

##### 3、生成和运行

```
docker-compose up
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_redis_1 ... done
Attaching to composetest_web_1, composetest_redis_1
web_1    |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
redis_1  | 1:C 17 Aug 22:11:10.480 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
redis_1  | 1:C 17 Aug 22:11:10.480 # Redis version=4.0.1, bits=64, commit=00000000, modified=0, pid=1, just started
redis_1  | 1:C 17 Aug 22:11:10.480 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
web_1    |  * Restarting with stat
redis_1  | 1:M 17 Aug 22:11:10.483 * Running mode=standalone, port=6379.
redis_1  | 1:M 17 Aug 22:11:10.483 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
web_1    |  * Debugger is active!
redis_1  | 1:M 17 Aug 22:11:10.483 # Server initialized
redis_1  | 1:M 17 Aug 22:11:10.483 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
web_1    |  * Debugger PIN: 330-787-903
redis_1  | 1:M 17 Aug 22:11:10.483 * Ready to accept connections
```

### 常用命令

 后台运行 

```
docker-compose up -d
```

查看运行状态

```
docker-compose ps
```

查看运行状态

```
docker-compose run web env
```

停止服务

```
docker-compose stop
```



### 实例：使用 docker-compose 管理 Web 系统

创建程序文件

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
    return 'Hello TestWeb! I have been seen {} times.\n'.format(count)

```

创建 Dockerfile 文件

> 工作目录：testweb

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

使用脚本 create_image.sh 生成镜像

> 生成镜像后会把之前 tag 为 lastest 的镜像重新打 tag 用于回滚

```
#!/bin/bash
IMAGE_ID_OLD=`docker images | grep testweb | grep latest | awk '{print $3}'`
docker build -t testweb .
IMAGE_ID_NEW=`docker images | grep testweb | grep latest | awk '{print $3}'`
IMAGE_COUNT=`docker images | grep testweb | wc -l`
if [ $IMAGE_COUNT -gt 5 ]; then
  docker images | grep testweb | tail -n +6 | awk '{print $3}' | xargs docker rmi
fi
if [[ $IMAGE_ID_OLD != $IMAGE_ID_NEW ]] && [[ -n $IMAGE_ID_OLD ]] ; then
    docker tag $IMAGE_ID_OLD testweb:`date +%Y%m%d.%H%M%S`
fi
```

创建 docker-compose.yml 文件

> 通过 ${TESTWEB_IMAGE_TAG} 变量指定镜像的版本，
>
> ${TESTWEB_IMAGE_TAG} 变量可以使用 shell 命令 export TESTWEB_IMAGE_TAG=latest 指定

```
version: '3'
services:
  web:
    # build: .
    image: "testweb:${TESTWEB_IMAGE_TAG}"
    ports:
      - "5000:5000"
    environment:
      FLASK_ENV: development
  redis:
    image: "redis:alpine"
```

启动服务

```
# export TESTWEB_IMAGE_TAG="latest"
# docker-compose up -d
# curl http://localhost:5000
Hello Hello TestWeb! I have been seen 32 times.
```

更新 Web

```
# cat app.py
......
return 'Hello Hello TestWeb V2! I have been seen {} times.\n'.format(count)
# sh create_image.sh 
# docker-compose up -d web
# curl http://localhost:5000
Hello Hello TestWeb V2! I have been seen 33 times.
```

回滚

```
# export TESTWEB_IMAGE_TAG="20200514.155246"
# docker-compose up -d web
# curl http://localhost:5000
Hello Hello TestWeb! I have been seen 34 times.
```


