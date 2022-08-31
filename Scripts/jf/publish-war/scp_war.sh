#!/bin/bash
set -e
WAR_FILE=$1
WAR_VERSION=$2
DIST_SERVER=$3
DIST_SERVER_PORT=$4
DIST_SERVER_USER=$5

if [ $# -ne 5 ]; then
    echo "参数错误！sh $0 WAR_FILE WAR_VERSION DIST_SERVER DIST_SERVER_PORT DIST_SERVER_USER"
    exit 1
fi

echo "开始传输包 ${WAR_FILE}"
scp -i /root/.ssh/deploy -P ${DIST_SERVER_PORT} ${WAR_FILE} ${DIST_SERVER_USER}@${DIST_SERVER}:/data/warfile/${WAR_VERSION}-${WAR_FILE}
if [ $? -ne 0 ]; then
    echo "包传输失败！"
    exit 1
else
    echo "完成传输包"
fi
