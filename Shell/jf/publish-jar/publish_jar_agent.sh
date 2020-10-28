#!/bin/bash
set -e
PROJECT_NAME=$2
TIME_TAG=`date +%Y%m%d%H%M%S`
PACKAGE_NAME=${PROJECT_NAME}.jar
PACKAGE_VERSION_NAME=${PROJECT_NAME}-${TIME_TAG}.jar
PUBLISH_PATH=/data/${PROJECT_NAME}
VERSION_PATH=/data/${PROJECT_NAME}/versions

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 publish|start|stop PROJECT_NAME"
    exit
fi

if [ ! -f /tmp/${PACKAGE_NAME} ]; then
    echo "包 /tmp/${PACKAGE_NAME} 不存在"
    exit
fi

function start_package {
    if ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep ;then
        echo "正在运行"
        exit
    else
        echo "开始启动"
        nohup java -jar -Xms256m -Xmx256m ${PUBLISH_PATH}/${PACKAGE_NAME} --spring.profiles.active=test >/dev/null 2>&1 &
        sleep 5s
    fi
    
    while true
    do
        if ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep ;then
            P_ID=`ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep | awk '{print $2}'`
            if netstat -ntlp | grep $P_ID ;then
                echo "启动成功"
                break
            else
                echo "正在启动"
                sleep 5s
            fi
        else
            echo "启动失败"
            break
        fi
    done
}

function stop_package {
    while true
    do
        if ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep ;then
            P_ID=`ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep | awk '{print $2}'`
            echo "开始停止"
            kill -9 $P_ID
            sleep 2s
            if ps -ef | grep java | grep ${PACKAGE_NAME} | grep -v grep ;then
                echo "正在停止"
                sleep 5s
            else
                echo "停止成功"
                break
            fi
        else
            echo "未运行"
            break
        fi
    done
}

function rm_expire_package {
    cd ${VERSION_PATH}
    EXPIRE_PACKAGE=`ls -t *.jar | tail -n +4`
    [ -n "${EXPIRE_PACKAGE}" ] && rm -f `ls -t *.jar | tail -n +4`
}

function publish_package {
    stop_package
    [ ! -d ${PUBLISH_PATH} ] && mkdir -pv ${PUBLISH_PATH}
    [ ! -d ${PUBLISH_PATH}/versions ] && mkdir -pv ${PUBLISH_PATH}/versions
    [ -f ${PUBLISH_PATH}/${PACKAGE_NAME} ] && mv /data/${PROJECT_NAME}/${PROJECT_NAME}.jar ${VERSION_PATH}/${PACKAGE_VERSION_NAME}
    mv /tmp/${PACKAGE_NAME} ${PUBLISH_PATH}
    start_package
    rm_expire_package
}

case $1 in
    "publish")
        publish_package ;;
    "start")
        start_package ;;
    "stop")
        stop_package ;;
     *)
        echo "$1 操作不存在"
esac
