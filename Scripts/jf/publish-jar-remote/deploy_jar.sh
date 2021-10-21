#!/bin/bash
set -e
PROJECT_NAME=$1
PUBLISH_ENV=$2
PUBLISH_SERVER_IP=$3
PUBLISH_SERVER_PORT=$4
DEPLOY_OBJ=$5
PUBLISH_USER=$6
DEPLOY_DIR=$7
JAR_PATH=/data/maven/${PROJECT_NAME}-${PUBLISH_ENV}/${DEPLOY_OBJ}
PUBLISH_SERVER="-i /root/.ssh/deploy -p ${PUBLISH_SERVER_PORT} ${PUBLISH_USER}@${PUBLISH_SERVER_IP}"

if [ $# -ne 7 ]; then
    echo "参数错误！"
    exit 1
fi

echo "${PUBLISH_USER}@${PUBLISH_SERVER_IP}:${PUBLISH_SERVER_PORT} 开始发布"
ssh ${PUBLISH_SERVER} "sh /data/scripts/deploy_jar_agent.sh publish ${PROJECT_NAME} ${PUBLISH_ENV} ${JAR_PATH} ${DEPLOY_DIR}" || exit 1
