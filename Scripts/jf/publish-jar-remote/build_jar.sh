#!/bin/bash
set -e
PROJECT_NAME=$1
PUBLISH_ENV=$2
BUILD_SERVER_IP=$3
BUILD_SERVER_PORT=$4
BUILD_USER=$5
SRC_DIR=`pwd`
DESC_DIR=/data/maven/${PROJECT_NAME}-${PUBLISH_ENV}
BASE_DIR=`dirname $(pwd)`
BUILD_SERVER="-i /root/.ssh/deploy -p ${BUILD_SERVER_PORT} ${BUILD_USER}@${BUILD_SERVER_IP}"

if [ $# -ne 5 ]; then
    echo "参数错误！正确格式: sh $0 PROJECT_NAME BUILD_SERVER PUBLISH_SERVER PUBLISH_ENV"
    exit 1
fi

if [ "$BASE_DIR" != "/data/jenkins/workspace" ]; then
    echo "父级目录不是 /data/jenkins/workspace"
    exit 1
fi

echo "${BUILD_USER}@${BUILD_SERVER_IP}: 开始同步文件"
# rsync -avz --delete --exclude ".git" -e "ssh -i /root/.ssh/deploy -p ${BUILD_SERVER_PORT}" ${SRC_DIR}/ ${BUILD_USER}@${BUILD_SERVER_IP}:${DESC_DIR}/
rsync -avz --exclude ".git" -e "ssh -i /root/.ssh/deploy -p ${BUILD_SERVER_PORT}" ${SRC_DIR}/ ${BUILD_USER}@${BUILD_SERVER_IP}:${DESC_DIR}/
echo "${BUILD_USER}@${BUILD_SERVER_IP}: 开始编译"
ssh ${BUILD_SERVER} "cd ${DESC_DIR}; mvn package -Dmaven.compile.fork=true -T 1C" || exit 1
