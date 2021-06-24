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
echo "TAG=${TIME_TAG}-${PUBLISH_ENV}" >> .env

if [ "${MODULE_NAME}" = "all" ]; then
    docker-compose up -d
else
    docker-compose up -d ${MODULE_NAME}
fi

echo "清理没有使用的镜像"
# 清理指定项目的对象，label 创建镜像的时候设置的
docker image prune --filter="label=project=${PROJECT_NAME}" -a -f
