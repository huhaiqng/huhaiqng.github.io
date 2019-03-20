#!/bin/bash
user=`whoami`
if [ "$user" != "tomcat" ]; then
    echo "请使用 tomcat 用户执行该脚本！"
    exit
fi
cd /usr/local/baipao/manager/
# Stop Baipao Manager
if ps -ef | grep baipao-manager-rest-2.0.0.jar | grep -v grep >/dev/null ;then
    kill -9 `ps -ef | grep baipao-manager-rest-2.0.0.jar | grep -v grep | awk '{print $2}'`
else
    echo "Baipao Manager 没有在运行!"
fi
# Backup Old Package
mv baipao-manager-rest-2.0.0.jar baipao-manager-rest-2.0.0.jar.`date +%Y%m%d.%H%M%S`
# Delete Old Package More Then 5
rm -f `ls -t baipao-manager-rest-2.0.0.jar.* | tail -n +6`
# Copy Test Env Package
cp /data/backup/baipao/manager/baipao-manager-rest-2.0.0.jar .

# Start Baipao Manager
sh /data/scripts/start_baipao_manager.sh
