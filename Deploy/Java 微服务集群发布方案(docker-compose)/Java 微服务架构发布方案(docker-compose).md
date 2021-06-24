#### 发布流程图

![image-20201126140040449](Java 微服务架构发布方案(docker-compose).assets/image-20201126140040449.png)

#### 服务器信息

> SERVER-A 与 SERVER-B、SERVER-C 之间用户 devops ssh 免密

私有云

- SERVER-A 192.168.1.10: 部署 gitlab, jenkins

公有云

- SERVER-B 172.16.1.10: 部署 maven, harbor
- SERVER-C 172.16.1.21: 部署项目A
- SERVER-D 172.16.1.22: 部署项目B



#### 在 SERVER-A  进行相关配置 

##### 创建相关服务器信息文件 /data/scripts/msr_info.txt

> PROJECT_NAME: 项目名称
>
> BUILD_SERVER: 编译服务器
>
> PUBLISH_SERVER: 发布服务器
>
> PUBLISH_ENV: 发布环境

```shell
# PROJECT_NAME	# BUILD_SERVER			# PUBLISH_SERVER		# PUBLISH_ENV
piomin			devops@192.168.40.202   devops@192.168.40.203   test
```

##### 创建发布脚本 /data/scripts/publish_java_msr.sh

```shell
#!/bin/bash
set -e
TIME_TAG=`date +%s`
PROJECT_NAME=$1
MODULE_NAME=$2
PUBLISH_ENV=$3
TAR_FILE=/tmp/${PROJECT_NAME}.tar.gz
BASE_PATH=`dirname $(pwd)`

if [ $# -ne 3 ]; then
    echo "测试错误！正确格式: sh $0 PROJECT_NAME MODULE_NAME PUBLISH_ENV"
    exit 1
fi

if [ "${BASE_PATH}" = "/data/jenkins/workspace" ]; then
    tar zcf ${TAR_FILE} *
else
    echo "当前目录的父目录不是 /data/jenkins/workspace"
    exit 1
fi

COUNT=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/msr_info.txt | grep ${PUBLISH_ENV} | wc -l`

if [ ${COUNT} -eq 1 ]; then
    MSR_INFO=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/msr_info.txt | grep ${PUBLISH_ENV}`
    BUILD_SERVER=`echo ${MSR_INFO} | awk '{print $2}'`
    PUBLISH_SERVER=`echo ${MSR_INFO} | awk '{print $3}'`

    echo "开始开始传送包 ${TAR_FILE}  到服务器 ${BUILD_SERVER}"
    scp ${TAR_FILE} ${BUILD_SERVER}:/data/maven || exit 1
    echo "开始在服务器上 ${BUILD_SERVER} 编译"
    ssh ${BUILD_SERVER} "sh /data/scripts/build_java_create_image.sh ${PROJECT_NAME} ${MODULE_NAME} ${PUBLISH_ENV} ${TIME_TAG}" || exit 1
    echo "开始在服务器上 ${PUBLISH_SERVER} 发布"
    ssh ${PUBLISH_SERVER} "sh /data/scripts/publish_spring_cloud.sh ${PROJECT_NAME} ${MODULE_NAME} ${PUBLISH_ENV} ${TIME_TAG}" || exit 1
else
    echo "发布的项目 ${PROJECT_NAME} 和环境 ${PUBLISH_ENV} 不唯一或不存在"
    exit 1
fi
```

##### 在 Jenkins 上创建项目 piomin

git 参数化

![image-20201204160810666](Java 微服务架构发布方案(docker-compose).assets/image-20201204160810666.png)

模块参数化

![image-20201204160851121](Java 微服务架构发布方案(docker-compose).assets/image-20201204160851121.png)

配置源码

![image-20201204160950939](Java 微服务架构发布方案(docker-compose).assets/image-20201204160950939.png)

构建

> 需要提供 3个参数，项目名、模块名和环境

![image-20201204161016129](Java 微服务架构发布方案(docker-compose).assets/image-20201204161016129.png)



#### 在 SERVER-B 进行相关配置 

##### 依赖启动脚本 entrypoint.sh

```shell
#!/bin/sh
SERVICE_NAME=$1
SERVICE_PORT=$2

while ! curl -I --connect-timeout 5 http://${SERVICE_NAME}:${SERVICE_PORT} >/dev/null 2>&1
do
    echo "等待启动 ${SERVICE_NAME}:${SERVICE_PORT} ......"
    sleep 5s
done

shift 2
cmd="$@"
$cmd
[root@server-b dockerfile]# cat openjdk-8-alpine-cts
FROM openjdk:8-jdk-alpine
RUN echo "https://mirrors.aliyun.com/alpine/v3.9/main/" > /etc/apk/repositories ;\
    apk add tzdata ;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    echo "Asia/Shanghai" >/etc/timezone ;\
    apk add curl --no-cache && rm -f /var/cache/apk/*
WORKDIR /data
COPY entrypoint.sh .
```

##### 基础镜像 dockerfile openjdk-8-alpine-cts

> 包含 jdk1.8, cts 时区, curl 工具
>
> curl 用来探测 java 服务是否已启动

```
FROM openjdk:8-jdk-alpine
RUN echo "https://mirrors.aliyun.com/alpine/v3.9/main/" > /etc/apk/repositories ;\
    apk add tzdata ;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    echo "Asia/Shanghai" >/etc/timezone ;\
    apk add curl --no-cache && rm -f /var/cache/apk/*
WORKDIR /data
COPY entrypoint.sh .
RUN chmod +x /data/entrypoint.sh
```

##### 生成基础镜像

```
docker build -t openjdk:8-alpine-cts -f openjdk-8-alpine-cts .
```

##### 服务镜像 docker openjdk-8-jar

```
FROM openjdk:8-alpine-cts
RUN addgroup -g 1201 -S spring && adduser -u 1201 -S spring -G spring
USER spring:spring
COPY target/*.jar app.jar
```

##### 创建模块列表文件 /data/scripts/module_list.txt

```
piomin_list=config-service department-service discovery-service employee-service gateway-service organization-service proxy-service
```

##### 创建编译及生成镜像脚本 /data/scripts/build_java_create_image.sh 

```shell
#!/bin/bash
set -e
PROJECT_NAME=$1
MODULE_NAME=$2
PUBLISH_ENV=$3
TIME_TAG=$4
BASE_PATH=/data/maven
TAR_FILE=${PROJECT_NAME}.tar.gz

if [ $# -ne 4 ]; then
    echo "参数错误！正确格式: sh $0 ${PROJECT_NAME} ${MODULE_NAME} ${PUBLISH_ENV} ${TIME_TAG}"
    exit 1
fi

function create_image {
    IMAGE_NAME="harbor.huhaiqing.xyz/${PROJECT_NAME}/${MODULE_NAME}-${PUBLISH_ENV}:${TIME_TAG}"
    echo -e "\n---------------------------- 开始生成镜像 ${IMAGE_NAME} ----------------------------"
    if [ -d ${MODULE_NAME} ]; then
        docker build -t ${IMAGE_NAME} -f /data/dockerfile/openjdk-8-jar ${MODULE_NAME}
        docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}
    else
        echo "项目 ${PROJECT_NAME} 模块 ${MODULE_NAME} 不存在"
        exit 1
    fi
}

function set_module {
    COUNT=`grep "^${PROJECT_NAME}_list=" $(dirname $0)/module_list.txt | wc -l`

    if [ ${COUNT} -eq 1 ]; then
        if [ "${MODULE_NAME}" = "all" ]; then
            MODULE_LIST=`grep "^${PROJECT_NAME}_list=" $(dirname $0)/module_list.txt | awk -NF '=' '{print $2}'`
            for MODULE_NAME in ${MODULE_LIST}
            do
                create_image
            done
        else
            create_image
        fi
    else
        echo "发布的项目 ${PROJECT_NAME} 不唯一或不存在"
        exit 1
    fi
}

if [ -d ${BASE_PATH} ]; then
    cd ${BASE_PATH}
    [ -d ${PROJECT_NAME} ] && mv ${PROJECT_NAME} /tmp/${PROJECT_NAME}-${TIME_TAG}
    if [ -f ${TAR_FILE} ]; then
        echo "解压包"
        mkdir ${PROJECT_NAME}
        cd ${PROJECT_NAME}
        tar zxf ../${TAR_FILE} && rm -f ../${TAR_FILE}
        mvn install -DskipTests && set_module || exit 1
    else
        echo "${TAR_FILE} 不存在"
        exit 1
    fi
fi

echo "清理目录 /tmp/${PROJECT_NAME}-${TIME_TAG}"
[ -d /tmp/${PROJECT_NAME}-${TIME_TAG} ] && rm -rf /tmp/${PROJECT_NAME}-${TIME_TAG}
```



#### 在 SERVER-C 进行相关配置 

##### 创建启动更新脚本 /data/scripts/publish_spring_cloud.sh

```
#!/bin/bash
set -e
PROJECT_NAME=$1
MODULE_NAME=$2
PUBLISH_ENV=$3
TIME_TAG=$4
BASE_PATH=/data/${PROJECT_NAME}

if [ -d ${BASE_PATH} ]; then
    cd ${BASE_PATH}
else
    echo "项目 ${PROJECT_NAME} 目录 ${BASE_PATH} 不存在"
    exit 1
fi

sed -i "/TAG/d" .env
sed -i "/PUBLISH_ENV/d" .env
echo "TAG=${TIME_TAG}" >> .env
echo "PUBLISH_ENV=${PUBLISH_ENV}" >> .env

if [ "${MODULE_NAME}" = "all" ]; then
    docker-compose up -d
else
    docker-compose up -d ${MODULE_NAME}
fi

echo "清理没有使用的镜像"
docker image prune -a -f
```

##### 创建项目文件 /data/piomin/docker-compose.yml

> 一个项目对应一个文件夹

```yaml
version: "3.8"

services:
  config-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/config-service:${TAG}
    entrypoint: ["java", "-jar", "app.jar"]
  discovery-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/discovery-service:${TAG}
    entrypoint: ["./entrypoint.sh","config-service","8088","java", "-jar", "app.jar"]
    ports:
      - "8061:8061"
  department-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/department-service:${TAG}
    entrypoint: ["./entrypoint.sh","discovery-service","8061","java","-jar","app.jar"]
  employee-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/employee-service:${TAG}
    entrypoint: ["./entrypoint.sh","discovery-service","8061","java","-jar","app.jar"]
  gateway-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/gateway-service:${TAG}
    entrypoint: ["./entrypoint.sh","discovery-service","8061","java","-jar","app.jar"]
  organization-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/organization-service:${TAG}
    entrypoint: ["./entrypoint.sh","discovery-service","8061","java","-jar","app.jar"]
  proxy-service:
    image: harbor.huhaiqing.xyz/piomin-${PUBLISH_ENV}/proxy-service:${TAG}
    entrypoint: ["./entrypoint.sh","discovery-service","8061","java","-jar","app.jar"]
```

##### 创建变量文件 /data/forezp16/.env

> 脚本自动写入内容

```
su - devops
touch /data/forezp16/.env
```



#### 新增项目 forezp16

##### 在 Jenkins 上创建项目 forezp16

git 参数化

![image-20201204160810666](Java 微服务架构发布方案(docker-compose).assets/image-20201204160810666.png)

模块参数化

![image-20201204162938716](Java 微服务架构发布方案(docker-compose).assets/image-20201204162938716.png)

配置源码

![image-20201204163159741](Java 微服务架构发布方案(docker-compose).assets/image-20201204163159741.png)

构建

> 注意项目名

![image-20201204163238551](Java 微服务架构发布方案(docker-compose).assets/image-20201204163238551.png)



##### 在 SERVER-A 的文件 /data/scripts/msr_info.txt 中添加一条记录

```
forezp16	devops@192.168.40.202   devops@192.168.40.203   test
```

##### 在 SERVER-B 的文件 /data/scripts/module_list.txt 中添加一条记录

```
forezp16_list=admin-service blog-service common config-server eureka-server gateway-service monitor-service uaa-service user-service zipkin-service
```

##### 在 SERVER-C 上创建文件 /data/forezp16/docker-compose.yml

```
version: "3.8"

services:
  config-server:
    image: harbor.huhaiqing.xyz/forezp16/config-server:${TAG}
    entrypoint: ["java", "-jar", "app.jar"]
  eureka-server:
    image: harbor.huhaiqing.xyz/forezp16/eureka-server:${TAG}
    entrypoint: ["./entrypoint.sh","config-server","8769","java", "-jar", "app.jar"]
    ports:
      - "8761:8761"
  admin-service:
    image: harbor.huhaiqing.xyz/forezp16/admin-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  blog-service:
    image: harbor.huhaiqing.xyz/forezp16/blog-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  common:
    image: harbor.huhaiqing.xyz/forezp16/common:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  monitor-service:
    image: harbor.huhaiqing.xyz/forezp16/monitor-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  gateway-service:
    image: harbor.huhaiqing.xyz/forezp16/gateway-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  uaa-service:
    image: harbor.huhaiqing.xyz/forezp16/uaa-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
  user-service:
    image: harbor.huhaiqing.xyz/forezp16/user-service:${TAG}
    entrypoint: ["./entrypoint.sh","eureka-server","8761","java","-jar","app.jar"]
```

##### 在 SERVER-C 上创建变量文件 /data/forezp16/.env

> 脚本自动写入内容

```
su - devops
touch /data/forezp16/.env
```

