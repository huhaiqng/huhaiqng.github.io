#!/bin/bash
# 源包路径
SOURCE_PACKAGE_PATH="/data/jpark/jenkins-workspace/jpark-java-all-NEW-dev"
# 时间标记
TIME_TAG=`date +%Y%m%d%H%M%S`
# 新运行包路径
TARGET_PACKAGE_PATH="/data/publish/jpark-java/package/publish-${TIME_TAG}"
# 发布路径
PUBLISH_PATH="/data/publish/jpark-java/running"
# tomcat  路径
TOMCAT_PATH="/usr/local/tomcat"
# 操作
JAR_CMD=$1
# 模块名
INPUT_MODULE=$2
# tomcat 停止状态
echo "no" >/tmp/TOMCAT_STOP_STATUS

# 脚本使用说明
function usage {
echo -e "------------------------------------- 脚本使用说明 ------------------------------------- \n \
    发布单个包：sh $0 publish MODULE_NAME \n \
    发布所有包：sh $0 publish all \n \
    启动单个包：sh $0 start MODULE_NAME \n \
    启动所有包：sh $0 start all \n \
    停止单个包：sh $0 stop MODULE_NAME \n \
    停止所有包：sh $0 stop all \n \
    重启单个包：sh $0 restart MODULE_NAME \n \
    重启所有包：sh $0 restart all \n \
    检测单个包：sh $0 status MODULE_NAME \n \
    检测所有包：sh $0 status all"
}
# 拷贝包
function copy_package {
    [ ! -d "${TARGET_PACKAGE_PATH}"/${DEPLOY_DIR} ] && mkdir -p ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR}
    if [ "$PACKAGE_TYPE" = "jar" ]; then
        # 拷贝 jar 包
        [ -d ${SOURCE_PACKAGE_PATH}/${MODULE_NAME}/target/lib ] && cp -R ${SOURCE_PACKAGE_PATH}/${MODULE_NAME}/target/lib ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR}/lib
        cp ${SOURCE_PACKAGE_PATH}/${MODULE_NAME}/target/${PACKAGE_NAME} ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR}
    elif [ "$PACKAGE_TYPE" = "war" ]; then
        # 拷贝 war 包
        unzip -q ${SOURCE_PACKAGE_PATH}/${MODULE_NAME}/target/${PACKAGE_NAME} -d ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR}
    fi  
    if [ $? -ne 0 ] ; then
        echo "$PACKAGE_NAME 拷贝失败"
        # echo "清理新建的目录 $TARGET_PACKAGE_PATH，退出运行"
        # tar zcfP /tmp/publish.tar.gz $TARGET_PACKAGE_PATH --remove-files
        # exit
    else
        echo "$PACKAGE_NAME 拷贝成功"
    fi
}
# 启动包
function start_package {
    status_package
    if [ "$PACKAGE_STATUS" = "stop" ]; then
        echo "开始启动 ${PACKAGE_NAME}"
        if [ `cat /tmp/TOMCAT_STOP_STATUS` = "yes" -a "$PACKAGE_TYPE" = "war" ]; then
            sh /usr/local/tomcat/bin/catalina.sh start >/dev/null 2>&1
        elif [ "$PACKAGE_TYPE" = "war" ]; then
            sh /usr/local/tomcat/bin/catalina.sh start >/dev/null 2>&1
        elif [ "$PACKAGE_TYPE" = "jar" ]; then
            nohup java -jar -Xms256m -Xmx384m ${PUBLISH_PATH}/${DEPLOY_DIR}/${PACKAGE_NAME} >/dev/null 2>&1 &
        fi
        sleep 5s
        while true
        do
            status_package
            if [ "$PACKAGE_STATUS" = "start" ]; then
                echo "$PACKAGE_NAME 启动成功"
                if [ "$PACKAGE_TYPE" = "jar" ]; then
                    ps -ef | grep "$PACKAGE_NAME" | grep -v grep
                    netstat -ntlp | grep `ps -ef | grep "$PACKAGE_NAME" | grep java | grep -v grep | awk '{print $2}'`
                elif [ "$PACKAGE_TYPE" = "war" ]; then
                    ps -ef | grep java | grep tomcat |grep "/usr/local/jdk/" | grep -v grep
                    netstat -ntlp | grep `ps -ef | grep tomcat | grep "/usr/local/jdk/" | grep java | grep -v grep | awk '{print $2}'`
                fi  
                break
            elif [ "$PACKAGE_STATUS" = "other" ]; then
                echo "$PACKAGE_NAME 正在启动 ..."
                sleep 5s
            elif [ "$PACKAGE_STATUS" = "stop" ]; then
                echo "$PACKAGE_NAME 启动失败"
                break
                # exit
            fi
        done
    fi
}
# 停止包
function stop_package {
    status_package
    if [ "$PACKAGE_STATUS" = "start" ]; then
        if [ "$PACKAGE_TYPE" = "jar" ]; then
            kill -9 `ps -ef | grep java | grep "${PACKAGE_NAME}" | grep -v grep | awk '{print $2}'`
        elif [ "$PACKAGE_TYPE" = "war" ]; then
            echo "开始停止 war 包"
            sh /usr/local/tomcat/bin/catalina.sh stop >/dev/null 2>&1
        fi
        while true
        do
            status_package >/dev/null 2>&1
            if [ "$PACKAGE_STATUS" = "stop" ]; then
                echo "$PACKAGE_NAME 停止成功"
                break
            else
                echo "$PACKAGE_NAME 正在停止 ..."
                sleep 5s
            fi
        done
    fi
}
# 重启包
function restart_package {
    stop_package
    start_package
}
# 检测包
function status_package {
    if [ "$PACKAGE_TYPE" = "jar" ] ;then
        if ps -ef | grep "$PACKAGE_NAME" | grep java | grep -v grep >/dev/null 2>&1; then
            P_ID=`ps -ef | grep "$PACKAGE_NAME" | grep java | grep -v grep | awk '{print $2}'`
            if netstat -nltp | grep $P_ID >/dev/null 2>&1; then
                echo "$PACKAGE_NAME 正在运行"
                PACKAGE_STATUS="start"
            else
                PACKAGE_STATUS="other"
            fi
        else
            echo "$PACKAGE_NAME 未运行"
            PACKAGE_STATUS="stop"
        fi
    elif [ "$PACKAGE_TYPE" = "war" ] ;then
        if ps -ef | grep "tomcat" | grep java | grep "/usr/local/jdk/" | grep -v grep >/dev/null 2>&1; then
            if netstat -nltp | grep 8005 >/dev/null 2>&1; then
                echo "tomcat 正在运行"
                PACKAGE_STATUS="start"
            else
                PACKAGE_STATUS="other"
            fi
        else
            echo "tomcat 未运行"
            PACKAGE_STATUS="stop"
        fi
    fi
}
# 发布包
function publish_package {
    echo -e "\n$(date): 开始发布包 ${PACKAGE_NAME}"
    copy_package
    if [ "$PACKAGE_TYPE" = "jar" ]; then
        stop_package
        rm -f ${PUBLISH_PATH}/${DEPLOY_DIR}
        ln -s ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR} ${PUBLISH_PATH}/${DEPLOY_DIR}
        start_package
    elif [ "$PACKAGE_TYPE" = "war" ]; then
        if [ "$INPUT_MODULE" != "all" ] ; then
            stop_package
            rm -f ${TOMCAT_PATH}/webapps/${DEPLOY_DIR}
            ln -s ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR} ${TOMCAT_PATH}/webapps/${DEPLOY_DIR}
            start_package
        else
            if [ `cat /tmp/TOMCAT_STOP_STATUS` = "no" ]; then
                stop_package
                echo "yes" >/tmp/TOMCAT_STOP_STATUS
            fi
            rm -f ${TOMCAT_PATH}/webapps/${DEPLOY_DIR}
            ln -s ${TARGET_PACKAGE_PATH}/${DEPLOY_DIR} ${TOMCAT_PATH}/webapps/${DEPLOY_DIR}
        fi
    fi
}
# 初始化数据
function init_module {
    if [ "$INPUT_MODULE" = "all" ]; then
        cat $(dirname $0)/module_info.txt | grep -v "^#" | while read line
        do
            MODULE_NAME=`echo $line | awk '{print $1}'`
            PACKAGE_NAME=`echo $line | awk '{print $2}'`
            DEPLOY_DIR=`echo $line | awk '{print $3}'`
            PACKAGE_TYPE=`echo $line | awk '{print $4}'`
            ${JAR_CMD}_package
        done
    else
        line=`grep "^${INPUT_MODULE}[[:space:]]\+" $(dirname $0)/module_info.txt`
        if [ -n "$line" ]; then
            MODULE_NAME=`echo $line | awk '{print $1}'`
            PACKAGE_NAME=`echo $line | awk '{print $2}'`
            DEPLOY_DIR=`echo $line | awk '{print $3}'`
            PACKAGE_TYPE=`echo $line | awk '{print $4}'`
            ${JAR_CMD}_package
        else
            echo "模块 $INPUT_MODULE 不存在!"
            exit
        fi
    fi
}
# 清理历史包
function clear_package {
    DELETE_DIR=`ls -td /data/publish/jpark-java/package/publish-* | tail -n +4`
    if [ -z "$DELETE_DIR" ]; then
        echo "没有需要清理的目录"
    else
        echo -e "需要清理目录：\n$DELETE_DIR"
        rm -f /tmp/publish.tar.gz
        cd /data/publish/jpark-java/package && tar zcf /tmp/publish.tar.gz `ls -td publish-* | tail -n +4` --remove-files
        echo "清理完成"
    fi
}

if [ $# -ne 2 ]; then
    echo "参数错误!"
    usage
    exit
fi

case $JAR_CMD in
    publish)
        echo "开始进行发布操作"
        init_module 
        if [ `cat /tmp/TOMCAT_STOP_STATUS` = "yes" ]; then
            echo -e "\n"
            PACKAGE_TYPE="war"
            PACKAGE_NAME="tomcat"
            start_package
        fi ;;
    start)
        echo "开始进行启动操作"
        init_module ;;
    stop)
        echo "开始进行停止操作"
        init_module ;;
    restart)
        echo "开始进行重启操作"
        init_module ;;
    status)
        echo "开始进行检测操作"
        init_module ;;
    *)
        echo "$1 操作不存在!"
        usage
        exit
esac

# clear_package
