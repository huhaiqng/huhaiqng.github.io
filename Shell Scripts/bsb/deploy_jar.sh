#!/bin/bash
set -e
username=$1
jarurl=$2
jarname=$3
jardir=$4
port=$5

if [ "$(whoami)" != "tomcat" ]; then
    echo "请选择 tomcat 用户！"
    exit
fi
echo "### 开始在服务器 $(hostname) 上执行发布！"

[[ ! -d $jardir ]] && mkdir -pv $jardir
cd $jardir
if ps -ef | grep "java -jar $jarname" | grep -v grep ;then
    jarpid=`ps -ef | grep "java -jar $jarname" | grep -v grep | awk '{print $2}'`
    kill -9 $jarpid
    echo "$jarname 停止成功！"
fi

if ls /tmp/$jarname.* ;then
    rm -f /tmp/$jarname.*
    tar zcfP /tmp/${jarname}-tmp.tar.gz /tmp/tomcat*.$port --remove-files
fi

[[ -f $jarname ]] && mv $jarname /tmp/$jarname.$(date +%s)
wget -c $jarurl -O $jarname >/dev/null 2>&1
nohup java -jar $jarname >/dev/null 2>&1 &
sleep 5s
if ps -ef | grep "java -jar $jarname" | grep -v grep >/dev/null 2>&1;then    
    while ! netstat -ntlp | grep $port
    do
        sleep 5s
        echo "$jarname 正在启动......"
    done
    echo "$jarname 发布成功！"
else
    echo "$jarname 发布失败！"
fi
