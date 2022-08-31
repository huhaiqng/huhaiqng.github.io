#!/bin/bash
set -e
CMD_TYPE=$1
TOMCAT_NAME=$2
CHECK_PORT=$3
WAR_NAME=$4
WAR_VERSION=$5
TOMCAT_PATH=/usr/local/${TOMCAT_NAME}
DEPLOY_PATH=${TOMCAT_PATH}/webapps
WAR_DIR=`echo ${WAR_NAME} | awk -F '.' '{print $1}'`
WAR_FILE=/data/warfile/${WAR_VERSION}-${WAR_NAME}
TOMCAT_STATUS="running"
EXEC_USER=`whoami`
ARG_COUNT=$#

if [ "$EXEC_USER" != "www" ]; then
    echo "用户 $EXEC_USER 无法执行此脚本, 请用 www 用户执行!"
    exit 1
fi

if [ ! -d ${TOMCAT_PATH} ]; then
    echo "${DEPLOY_PATH} 不存在!"
    exit 1
fi

if [ ! -n "${TOMCAT_PATH}" ]; then
    echo "检测端口不存在!"
    exit 1
fi

function checkarg2() {
    if [ ${ARG_COUNT} -ne 3 ]; then
        echo "参数错误！sh $0 start|stop|restart TOMCAT_NAME CHECK_PORT"
        exit 1
    fi
}

function checkarg5() {
    if [ ${ARG_COUNT} -ne 5 ]; then
        echo "参数错误！sh $0 publish TOMCAT_NAME CHECK_PORT WAR_NAME WAR_VERSION"
        exit 1
    fi
}

function checktomcat() {
    TOMCAT_PID=`ps -ef | grep java | grep www | grep ${TOMCAT_NAME} | grep -v grep | awk '{print $2}'`
    if netstat -ntlp | grep "127.0.0.1:${CHECK_PORT}[[:space:]]\+" >/dev/null 2>&1 ;then
        TOMCAT_STATUS="running"
    elif [ -n "${TOMCAT_PID}" ]; then
        TOMCAT_STATUS="ready"
    else
        TOMCAT_STATUS="stopped"
    fi
}

function starttomcat() {
    checktomcat
    if [ "$TOMCAT_STATUS" = "stopped" ]; then
        echo "${TOMCAT_NAME} 未运行, 开始启动......"
        sh ${TOMCAT_PATH}/bin/startup.sh
        sleep 5s
    else
        echo "${TOMCAT_NAME} 正在运行!"
        ps -ef | grep java | grep www | grep ${TOMCAT_NAME} | grep -v grep
        netstat -ntlp | grep ${TOMCAT_PID}
        exit
    fi

    while true
    do
        checktomcat
        if [ "$TOMCAT_STATUS" = "stopped" ]; then
            echo "${TOMCAT_NAME} 启动失败!"
            break
        elif [ "$TOMCAT_STATUS" = "ready" ]; then
            echo "${TOMCAT_NAME} 正在启动......"
        elif [ "$TOMCAT_STATUS" = "running" ]; then
            ps -ef | grep java | grep www | grep ${TOMCAT_NAME} | grep -v grep
            netstat -ntlp | grep ${TOMCAT_PID}
            echo "${TOMCAT_NAME} 启动成功!"
            break
        fi
        sleep 5s
    done
}

function stoptomcat() {
    checktomcat
    if [ "$TOMCAT_STATUS" = "stopped" ]; then
        echo "${TOMCAT_NAME} 未运行!"
    else
        echo "${TOMCAT_NAME} 运行中，开始停止......"
        ps -ef | grep java | grep www | grep ${TOMCAT_NAME} | grep -v grep
        netstat -ntlp | grep ${TOMCAT_PID}
        kill -9 ${TOMCAT_PID}
        sleep 5s
    fi

    while true
    do
        checktomcat
        if [ "$TOMCAT_STATUS" = "stopped" ]; then
            echo "${TOMCAT_NAME} 停止成功!"
            break
        elif [ "$TOMCAT_STATUS" = "ready" ]; then
            echo "${TOMCAT_NAME} 正在停止......"
        elif [ "$TOMCAT_STATUS" = "running" ]; then
            echo "${TOMCAT_NAME} 停止失败!"
            ps -ef | grep java | grep www | grep ${TOMCAT_NAME} | grep -v grep
            netstat -ntlp | grep ${TOMCAT_PID}
            break
        fi
        sleep 5s
    done
}

function publishwar() {
    DEPLOY_WAR_FILE=/data/warfile/${WAR_VERSION}-${WAR_NAME}
    if [ ! -f ${DEPLOY_WAR_FILE} ]; then
        echo "文件 ${DEPLOY_WAR_FILE} 不存在"
        exit 1
    fi

    if [ -d ${DEPLOY_PATH} ]; then
        cd ${DEPLOY_PATH}
    else
        echo "${DEPLOY_PATH} 不存在"
        exit 1
    fi

    stoptomcat
    if [ -d ${WAR_DIR} ]; then
        mv ${WAR_DIR} /tmp/${WAR_DIR}-`date +%Y%m%d%H%M%S`
    fi
    unzip ${DEPLOY_WAR_FILE} -d ${WAR_DIR} >/tmp/unzip.txt 2>&1
    starttomcat

    cd /data/warfile && rm -f `ls -t *-${WAR_NAME} | tail -n +6`
}

case $CMD_TYPE in
    start)
        checkarg2
        starttomcat
    ;;
    stop)
        checkarg2
        stoptomcat
    ;;
    restart)
        checkarg2
        stoptomcat
        starttomcat
    ;;
    publish)
        checkarg5
        publishwar
    ;;
    *)
        echo "参数错误！sh $0 start|stop|restart TOMCAT_NAME CHECK_PORT"
        echo "参数错误！sh $0 publish TOMCAT_NAME CHECK_PORT WAR_NAME WAR_VERSION"
        exit 1
    ;;
esac
