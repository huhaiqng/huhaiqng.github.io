#!/bin/bash
set -e
source ~/.bash_profile 
pkg_name=baipao-$1.jar
pkg_from=/data/backup/microbaipao/$1
pkg_to=/usr/local/baipao/$1

if [ $# -ne 1 ] ;then
    echo "参数错误！正确的格式：sh deploy_microbaipao_jar_agent.sh app"
    exit
fi

cd $pkg_to
if ps -ef | grep java | grep -v grep | grep $pkg_name >/dev/null 2>&1; then
    # 删除临时目录
    psid=`ps -ef | grep java | grep $pkg_name | grep -v grep | awk '{print $2}'`
    port=`sudo netstat -ntlp | grep java | grep $psid | awk '{print $4}' | awk -F ':' '{print $NF}'`
    ls /tmp/tomcat*.$port >/dev/null 2>&1 &&  tar zcf /tmp/tomcat-tmp-$port.tar.gz /tmp/tomcat*.$port --remove-files
    kill -9 `ps -ef | grep "$pkg_name" | grep -v grep | awk '{print $2}'`
else
    echo "包 $pkg_name 没有运行!"
fi

[[ -f $pkg_name ]] && mv $pkg_name /tmp/$pkg_name.`date +%Y%m%d-%H%M%S`
cp $pkg_from/$pkg_name .

sleep 10s

case $1 in
    contract)
        nohup java -Xms512M -Xmx2048M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
    ;;
#     manager)
#         nohup java -Xms512M -Xmx2048M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
#     ;;
    *)
        nohup java -Xms512M -Xmx1536M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
    ;;
esac

sleep 3s

pkg_pid=`ps -ef | grep "$pkg_name" | grep -v grep | awk '{print $2}'`
while ! sudo netstat -ntlp | grep java | grep $pkg_pid >/dev/null 2>&1
do
    sleep 10s
done

ps -ef | grep java | grep -v grep | grep $pkg_name
sudo netstat -ntlp | grep -v grep | grep $pkg_pid
echo "$pkg_name 在节点 `hostname` 启动成功！"
rm -f `ls -t /tmp/$pkg_name.* | tail -n +7`
