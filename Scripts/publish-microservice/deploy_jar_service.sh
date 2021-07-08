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
