#!/bin/bash
source ~/.bash_profile
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi

if ps -ef | grep baipao-manager-rest-2.0.0.jar | grep -v grep >/dev/null ;then
    echo "Baipao Manager 已经在运行！"
    exit
fi

cd /usr/local/baipao/manager/
nohup java -Xms1g -Xmx3g -jar baipao-manager-rest-2.0.0.jar > /dev/null 2>&1 &

while ! netstat -ntlp | grep java | grep 8444 
do
    echo "Baipao Manager 正在启动 ......"
    sleep 10s
done

echo "Baipao Manager 启动完成！"
