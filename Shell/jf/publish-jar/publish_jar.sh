#!/bin/bash
PROJECT_NAME=$1
DEPLOY_ENV=$2
BASE_DIR=`dirname $(pwd)`

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 PROJECT_NAME ENV"
    exit
fi

if [ "$BASE_DIR" != "/data/jenkins/workspace" ]; then
    echo "父级目录不是 /data/jenkins/workspace"
    exit
fi

COUNT=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/project_info.txt | grep "${DEPLOY_ENV}$" | wc -l`

if [ $COUNT -ne 0 ]; then
    cat $(dirname $0)/project_info.txt | grep "^${PROJECT_NAME}[[:space:]]\+" | grep "${DEPLOY_ENV}$" | while read line
    do
        SERVER=`echo $line | awk '{print $2}'`
        SSH_PORT=`echo $line | awk '{print $3}'`
        JAR_FILE=`echo $line | awk '{print $4}'`

        if [ ! -f "${JAR_FILE}" ]; then
            echo "JAR 包 ${JAR_FILE} 不存在"
            exit
        fi
        echo "开始开始传送包 ${JAR_FILE}  到服务器 ${SERVER}"
        scp -P ${SSH_PORT} ${JAR_FILE} ${SERVER}:/tmp/${PROJECT_NAME}.jar || exit 1
        echo "开始在服务器 ${SERVER} 上执行更新"
        ssh -p ${SSH_PORT} ${SERVER} "sh /data/scripts/publish_jar_agent.sh publish ${PROJECT_NAME}"
    done
else
    echo "相应环境 ${DEPLOY_ENV} 的项目 ${PROJECT_NAME} 不存在!"
    exit
fi
