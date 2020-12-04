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
