#!/bin/bash
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi
# Stop Baipao Driverapp
if ps -ef | grep baipao-driver-app-rest-2.0.0.jar | grep -v grep >/dev/null ;then
    kill -9 `ps -ef | grep baipao-driver-app-rest-2.0.0.jar | grep -v grep | awk '{print $2}'`
    echo "Baipao Driverapp 已经停止！"
    exit
else
    echo "Baipao Driverapp 没有运行!"
fi

