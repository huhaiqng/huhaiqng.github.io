#!/bin/bash
set -e
PROJECT_NAME=$1
DEPLOY_ENV=$2
TIME_TAG=`date +%Y%m%d%H%M%S`
BASE_DIR=`dirname $(pwd)`
TAR_FILE=/tmp/${PROJECT_NAME}-${TIME_TAG}.tar.gz

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 PROJECT_NAME ENV"
    exit 1
fi

if [ "$BASE_DIR" != "/data/jenkins/workspace" ]; then
    echo "父级目录不是 /data/jenkins/workspace"
    exit 1
fi

COUNT=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/project_info.txt | grep "${DEPLOY_ENV}$" | wc -l`

if [ $COUNT -ne 0 ]; then
    cat $(dirname $0)/project_info.txt | grep "^${PROJECT_NAME}[[:space:]]\+" | grep "${DEPLOY_ENV}$" | while read line
    do
        SERVER=`echo $line | awk '{print $2}'`
        SSH_PORT=`echo $line | awk '{print $3}'`
        SOURCE_DIR=`echo $line | awk '{print $4}'`

        if [ ! -f ${TAR_FILE} ]; then
            echo "开始 TAR 包 ${FILE_NAME}"
            if [ "${SOURCE_DIR}" = "self" ]; then
                tar zcf ${TAR_FILE} *
            elif [ -n "${SOURCE_DIR}" ]; then
                cd ${SOURCE_DIR} && tar zcf ${TAR_FILE} *
            else
                echo "源路径为空"
                continue
            fi
        fi
        [ $? -ne 0 ] && echo "TAR 包失败" && exit 1
        echo "开始开始传送包 ${TAR_FILE}  到服务器 ${SERVER}"
        scp -i /root/.ssh/deploy -P ${SSH_PORT} ${TAR_FILE} ${SERVER}:/tmp
        echo "开始在服务器 ${SERVER} 上执行更新"
        ssh -i /root/.ssh/deploy -p ${SSH_PORT} ${SERVER} "sh /data/scripts/publish_web_agent.sh ${PROJECT_NAME} ${TIME_TAG}"
    done
    echo "清理包 ${TAR_FILE}"
    rm -f ${TAR_FILE}
else
    echo "相应环境 ${DEPLOY_ENV} 的项目 ${PROJECT_NAME} 不存在!"
    exit
fi
