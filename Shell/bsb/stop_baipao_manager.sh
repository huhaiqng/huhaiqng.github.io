#!/bin/bash
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi
# Stop Baipao Manager
if ps -ef | grep baipao-manager-rest-2.0.0.jar | grep -v grep >/dev/null ;then
    kill -9 `ps -ef | grep baipao-manager-rest-2.0.0.jar | grep -v grep | awk '{print $2}'`
    echo "Baipao Manager 已经停止！"
    exit
else
    echo "Baipao Manager 没有运行!"
fi

