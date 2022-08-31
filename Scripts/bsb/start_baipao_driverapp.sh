#!/bin/bash
source ~/.bash_profile
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi

if ps -ef | grep baipao-driver-app-rest-2.0.0.jar | grep -v grep >/dev/null ;then
    echo "Baipao Driverapp 已经在运行！"
    exit
fi

cd /usr/local/baipao/driverapp/
nohup java -Xms1g -Xmx3g -jar baipao-driver-app-rest-2.0.0.jar > /dev/null 2>&1 &

while ! netstat -ntlp | grep java | grep 8666
do
    echo "Baipao Driverapp 正在启动 ......"
    sleep 10s
done

echo "Baipao Driverapp 启动完成！"
