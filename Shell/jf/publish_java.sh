#!/bin/bash
TAG=`date +%Y%m%d%H%M%S`
MODULE_LIST="gem-dist-auth gem-dist-config gem-dist-eureka gem-dist-getnumber gem-dist-tools gem-dist-web gem-dist-zuul"
BUILD_PATH="/data/maven/lfn-gem-dist-java-production"
CMD_MODULE=$1
PUBLISH_MODULE=$2
MODULE_EXSIT="no"

if [ "$PUBLISH_MODULE" != "all" ]; then
    for MODULE_NAME in $MODULE_LIST
    do
        if [ "$MODULE_NAME" = "$PUBLISH_MODULE" ]; then
            MODULE_EXSIT="yes"
        fi
    done
    if [ "$MODULE_EXSIT" = "no" ]; then
        echo "模块 $PUBLISH_MODULE 不存在"
        exit
    fi
fi

function change_tag {
    cd /data/gem-dist/compose
    TAG_NAME=`echo $MODULE_NAME | awk -F '-' '{print $NF}'`
    sed -i "/${TAG_NAME}tag/d" .env
    echo "${TAG_NAME}tag=$TAG" >> .env
}

function build_image {
    echo -e "\n开始生成镜像 ${MODULE_NAME}:${TAG}"
    cd ${BUILD_PATH}/$MODULE_NAME && docker build -t ${MODULE_NAME}:${TAG}  --no-cache . -f ./Dockerfile
    IMAGE_COUNT=`docker images | grep ${MODULE_NAME} | wc -l`
    if [ $IMAGE_COUNT -gt 5 ]; then
        echo "清理过期镜像 `docker images | grep ${MODULE_NAME} | tail -n +6`"
        docker images | grep ${MODULE_NAME} | tail -n +6 | awk '{print $3}' | xargs docker rmi
    fi
    change_tag
}

function publish_jar {
    if [ "$PUBLISH_MODULE" = "all" ]; then
        for MODULE_NAME in $MODULE_LIST
        do
            build_image
        done
        cd /data/gem-dist/compose
        docker-compose -p gem-dist up -d
    else
        MODULE_NAME=$PUBLISH_MODULE
        build_image
        docker-compose -p gem-dist up -d $PUBLISH_MODULE
    fi
}

function rollback_jar {
    if [ "$PUBLISH_MODULE" = "all" ]; then
        for MODULE_NAME in $MODULE_LIST
        do
            change_tag
        done
        cd /data/gem-dist/compose
        docker-compose -p gem-dist up -d
    else
        MODULE_NAME=$PUBLISH_MODULE
        change_tag
        cd /data/gem-dist/compose
        docker-compose -p gem-dist up -d $PUBLISH_MODULE
    fi
}

case "$CMD_MODULE" in
    "publish")
        publish_jar
    ;;
    "rollback")
        TAG=$3
        rollback_jar
    ;;
    *)
        echo "操作 $CMD_MODULE 不存在"
        exit
    ;;
esac
