#!/bin/bash
set -e
SERVICE_NAME=$1
JAR_PATH=$2
IMAGE_TAG=$3
BASE_DIR=`dirname $(pwd)`
IMAGE_NAME="registry.cn-shenzhen.aliyuncs.com/lfn/${SERVICE_NAME}:${IMAGE_TAG}"

if [ $# -ne 3 ]; then
    echo "参数错误！正确格式: sh $0 SERVICE_NAME JAR_PATH IMAGE_TAG"
    exit 1
fi

if [ "$BASE_DIR" != "/data/jenkins/workspace" ]; then
    echo "父级目录不是 /data/jenkins/workspace"
    exit 1
fi

if [ ! -f ${JAR_PATH} ]; then
    echo "包 ${JAR_PATH} 不存在!"
    exit 1
fi

echo "开始生成镜像 ${IMAGE_NAME}"
docker build -t ${IMAGE_NAME} --no-cache --label "project=${SERVICE_NAME}" -f /data/dockerfile/openjdk-8-jar .
docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}

