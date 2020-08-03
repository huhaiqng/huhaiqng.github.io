#!/bin/bash
source ~/.bash_profile
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi

sh /data/scripts/stop_baipao_driverapp.sh

cd /usr/local/baipao/driverapp/
ls -tl /data/backup/baipao/driverapp/baipao-driver-app-rest-2.0.0.jar*  | awk '{print $NF}'

echo "请输入回滚到哪一个包："
read package
# 重命名有问题的包名
mv baipao-driver-app-rest-2.0.0.jar baipao-driver-app-rest-2.0.0.jar.`date +%Y%m%d.%H%M%S`.with.problem
cp $package baipao-driver-app-rest-2.0.0.jar

sh /data/scripts/start_baipao_driverapp.sh 
