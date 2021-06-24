#!/bin/bash
set -e
PROJECT_NAME=$1
MODULE_NAME=$2
PUBLISH_MODULE_NAME=$2
PUBLISH_ENV=$3
TIME_TAG=`date +%Y%m%d%H%M%S`

if [ $# -ne 3 ]; then
    echo "参数错误！正确格式: sh $0 ${PROJECT_NAME} ${MODULE_NAME} ${PUBLISH_ENV}"
    exit 1
fi

function create_image {
    IMAGE_NAME="harbor.shuibeitd.com:4436/${PROJECT_NAME}-${PUBLISH_ENV}/${MODULE_NAME}:${TIME_TAG}"
    echo -e "\n---------------------------- 开始生成镜像 ${IMAGE_NAME} ----------------------------"
    if [ -d ${MODULE_NAME} ]; then
        docker build -t ${IMAGE_NAME} --no-cache --label "project=${PROJECT_NAME}" -f /data/dockerfile/openjdk-8-jar ${MODULE_NAME}
        docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}
    else
        echo "项目 ${PROJECT_NAME} 模块 ${MODULE_NAME} 不存在"
        exit 1
    fi
}

function set_module {
    COUNT=`grep "^${PROJECT_NAME}_list=" $(dirname $0)/module_list.txt | wc -l`

    if [ ${COUNT} -eq 1 ]; then
        if [ "${MODULE_NAME}" = "all" ]; then
            MODULE_LIST=`grep "^${PROJECT_NAME}_list=" $(dirname $0)/module_list.txt | awk -NF '=' '{print $2}'`
            for MODULE_NAME in ${MODULE_LIST}
            do
                create_image
            done
        else
            create_image
        fi
    else
        echo "发布的项目 ${PROJECT_NAME} 不唯一或不存在"
        exit 1
    fi
}

function publish_java {
    COUNT=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/msr_info.txt | grep ${PUBLISH_ENV} | wc -l`

    if [ ${COUNT} -eq 1 ]; then
        MSR_INFO=`grep "^${PROJECT_NAME}[[:space:]]\+" $(dirname $0)/msr_info.txt | grep ${PUBLISH_ENV}`
        PUBLISH_SERVER=`echo ${MSR_INFO} | awk '{print $4}'`
        PUBLISH_PORT=`echo ${MSR_INFO} | awk '{print $5}'`
        echo "开始在服务器上 ${PUBLISH_SERVER} 发布"
        ssh -i /root/.ssh/deploy -p ${PUBLISH_PORT} ${PUBLISH_SERVER} "sh /data/scripts/publish_spring_cloud.sh ${PROJECT_NAME} ${PUBLISH_MODULE_NAME} ${PUBLISH_ENV} ${TIME_TAG}" || exit 1
    else
        echo "发布的项目 ${PROJECT_NAME} 和环境 ${PUBLISH_ENV} 不唯一或不存在"
        exit 1
    fi
}

set_module
publish_java
