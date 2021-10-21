#!/bin/bash
set -e
PUBLISH_SERVER_IP=$1
PUBLISH_SERVER_PORT=$2
PUBLISH_USER=$3
TOMCAT_NAME=$4
WAR_NAME=$5
WAR_VERSION=$6
CHECK_PORT=$7
PUBLISH_SERVER="-i /root/.ssh/deploy -p ${PUBLISH_SERVER_PORT} ${PUBLISH_USER}@${PUBLISH_SERVER_IP}"
# PUBLISH_SERVER="-i /root/.ssh/deploy -p 22 www@192.168.40.252"

if [ $# -ne 7 ]; then
    echo "参数错误！"
    exit 1
fi

echo "${PUBLISH_USER}@${PUBLISH_SERVER_IP}:${PUBLISH_SERVER_PORT} 开始发布 ${WAR_NAME} ${WAR_VERSION}"
ssh ${PUBLISH_SERVER} "sh /data/scripts/deploy_war_agent.sh publish ${TOMCAT_NAME} ${CHECK_PORT} ${WAR_NAME} ${WAR_VERSION}" || exit 1
