#!/bin/bash
set -e
date

CMD_TYPE=$1
TOMCAT_NAME=$2
EXEC_USER=`whoami`
TOMCAT_BIN_DIR="/usr/local/${TOMCAT_NAME}/bin"
CHECK_PORT=`grep "^${TOMCAT_NAME}[[:space:]]\+" $(dirname $0)/tomcat-info.txt | awk '{print $2}'`
TOMCAT_STATUS="null"
TOMCAT_PID="null"

function usage() {
    echo -e "参数错误,脚本使用说明: \n \
    启动：sh $0 start TOMCAT_NAME \n \
    停止：sh $0 stop TOMCAT_NAME \n \
    重启：sh $0 restart TOMCAT_NAME"
}

if [ $# -ne 2 ]; then
    usage
    exit
fi

if [ "$EXEC_USER" != "www" ]; then
    echo "用户 $EXEC_USER 无法执行此脚本, 请用 www 用户执行!"
    exit
fi

if [ ! -d ${TOMCAT_BIN_DIR} ]; then
    echo "${TOMCAT_NAME} 不存在!"
    exit
fi

if [ ! -n "${CHECK_PORT}" ]; then
    echo "检测端口不存在!"
    exit
fi

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
        sh $TOMCAT_BIN_DIR/startup.sh
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

case $CMD_TYPE in
    start)
        starttomcat
    ;;
    stop)
        stoptomcat
    ;;
    restart)
        stoptomcat
        starttomcat
    ;;
    *)
        usage
        exit
    ;;
esac
