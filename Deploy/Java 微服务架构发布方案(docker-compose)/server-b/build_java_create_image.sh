#!/bin/bash
set -e
PROJECT_NAME=$1
MODULE_NAME=$2
PUBLISH_ENV=$3
TIME_TAG=$4
BASE_PATH=/data/maven
TAR_FILE=${PROJECT_NAME}.tar.gz

if [ $# -ne 4 ]; then
    echo "参数错误！正确格式: sh $0 ${PROJECT_NAME} ${MODULE_NAME} ${PUBLISH_ENV} ${TIME_TAG}"
    exit 1
fi

function create_image {
    IMAGE_NAME="harbor.huhaiqing.xyz/${PROJECT_NAME}/${MODULE_NAME}:${TIME_TAG}-${PUBLISH_ENV}"
    echo -e "\n---------------------------- 开始生成镜像 ${IMAGE_NAME} ----------------------------"
    if [ -d ${MODULE_NAME} ]; then
		# 设置 label 方便清理镜像时指定需要清理哪个项目的镜像
        docker build -t ${IMAGE_NAME} --label "project=${PROJECT_NAME}" -f /data/dockerfile/openjdk-8-jar ${MODULE_NAME}
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

if [ -d ${BASE_PATH} ]; then
    cd ${BASE_PATH}
    [ -d ${PROJECT_NAME} ] && mv ${PROJECT_NAME} /tmp/${PROJECT_NAME}-${TIME_TAG}
    if [ -f ${TAR_FILE} ]; then
        echo "解压包"
        mkdir ${PROJECT_NAME}
        cd ${PROJECT_NAME}
        tar zxf ../${TAR_FILE} && rm -f ../${TAR_FILE}
        mvn install -DskipTests && set_module || exit 1
    else
        echo "${TAR_FILE} 不存在"
        exit 1
    fi
fi

echo "清理目录 /tmp/${PROJECT_NAME}-${TIME_TAG}"
[ -d /tmp/${PROJECT_NAME}-${TIME_TAG} ] && rm -rf /tmp/${PROJECT_NAME}-${TIME_TAG}
