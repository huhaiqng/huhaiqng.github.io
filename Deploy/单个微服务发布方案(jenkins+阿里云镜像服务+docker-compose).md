

#### 发布 JAR 包

##### 准备 Dockerfile

openjdk:8-alpine-cts 镜像 Dockerfile

> 中文时区

```dockerfile
FROM openjdk:8-jdk-alpine
RUN echo "https://mirrors.aliyun.com/alpine/v3.9/main/" > /etc/apk/repositories ;\
    apk add tzdata ;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    echo "Asia/Shanghai" >/etc/timezone ;\
    apk add curl --no-cache && rm -f /var/cache/apk/*
WORKDIR /data
```

生成 openjdk:8-alpine-cts 镜像 

```shell
docker build -t openjdk:8-alpine-cts .
```

jar 镜像 Dockerfile /data/dockerfile/openjdk-8-jar

```dockerfile
FROM openjdk:8-alpine-cts
COPY target/*.jar app.jar
```

##### Jenkins 服务器

> 需要设置与微服务服务器 ssh 免密登录

创建微服务信息文件 /data/scripts/publish-microservice/service_info.txt

```
# 服务名		  # 用户名@服务器		      # ssh 端口号  	# 环境
warehouse       www@1.1.1.1             22             test
```

创建发布脚本 /data/scripts/publish-microservice/deploy_jar_service.sh

> 需要登录阿里云镜像服务：docker login --username=username registry.cn-shenzhen.aliyuncs.com

```shell
#!/bin/bash
set -e
SERVICE_NAME=$1
SERVICE_ENV=$2
IMAGE_TAG=${SERVICE_ENV}-`date +%Y%m%d%H%M%S`

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 SERVICE_NAME PUBLISH_ENV"
    exit 1
fi

function create_jar_image() {
    IMAGE_NAME="registry.cn-shenzhen.aliyuncs.com/lfn/${SERVICE_NAME}:${IMAGE_TAG}"
    echo "开始生成镜像 ${IMAGE_NAME}"
    if ls target/*.jar ; then
        docker build -t ${IMAGE_NAME} --no-cache --label "project=${SERVICE_NAME}" -f /data/dockerfile/openjdk-8-jar .
        docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}
    else
        echo "jar 包不存在！"
        exit 1
    fi
}

function deploy_service() {
    COUNT=`grep "^${SERVICE_NAME}[[:space:]]\+" $(dirname $0)/service_info.txt | grep "${SERVICE_ENV}$" | wc -l`

    if [ $COUNT -ne 0 ]; then
        cat $(dirname $0)/service_info.txt | grep "^${SERVICE_NAME}[[:space:]]\+" | grep "${SERVICE_ENV}$" | while read line
        do
            SERVER=`echo $line | awk '{print $2}'`
            SSH_PORT=`echo $line | awk '{print $3}'`
    
            echo "开始在服务器 ${SERVER} 上执行更新 ${SERVICE_NAME} 服务"
            ssh -i /root/.ssh/deploy -p ${SSH_PORT} ${SERVER} "sh /data/scripts/publish_microservice_agent.sh ${SERVICE_NAME} ${IMAGE_TAG}" < /dev/null 
        done
    else
        echo "相应环境 ${DEPLOY_ENV} 的项目 ${PROJECT_NAME} 不存在!"
        exit 1
    fi

}
create_jar_image
deploy_service
```

执行实例

```
sh /data/scripts/publish-microservice/deploy_jar_service.sh service test
```

##### 微服务服务器

创建发布脚本 /data/scripts/publish_microservice_agent.sh

```shell
#!/bin/bash
set -e

SERVICE_NAME=$1
IMAGE_TAG=$2

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 SERVICE_NAME IMAGE_TAG"
    exit 1
fi

cd /data/microservice
sed -i "/${SERVICE_NAME}tag/d" .env
echo "${SERVICE_NAME}tag=${IMAGE_TAG}" >> .env

docker-compose up -d ${SERVICE_NAME}
echo "清理没有使用的镜像"
# 清理指定项目的对象，label 创建镜像的时候设置的
docker image prune --filter="label=project=${SERVICE_NAME}" -a -f
```

创建 docker-compose /data/microservice/docker-compose.yml

```yaml
version: "3.8"

services:
  warehouse:
    image: registry.cn-shenzhen.aliyuncs.com/lfn/warehouse:${warehousetag}
    entrypoint: ["java","-Xms256m","-Xmx512m","-jar", "app.jar", "--spring.profiles.active=test"]
    volumes:
      - /data/logs/warehouse2:/data/logs/wms
    ports:
      - 7030:7010
```

创建版本环境文件 /data/microservice/.env

```
touch /data/microservice/.env
```

