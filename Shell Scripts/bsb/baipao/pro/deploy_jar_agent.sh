#!/bin/bash
source ~/.bash_profile 

if [ $# -ne 3 ];then
    echo "参数错误！"
    echo "正确的格式：sh deploy_jar_agent.sh 包名 源包目录 发布目录"
    exit
fi

# 停止服务
if ps -ef | grep $1 | grep java | grep -v grep >/dev/null;then
    kill -9 `ps -ef | grep java | grep $1 | grep -v grep | awk '{print $2}'`
else
    echo "$1 没有在运行!"
fi
cd $3
mv $1 /tmp/$1.`date +%Y%m%d.%H%M%S`
rm -f `ls -t /tmp/$1.* | tail -n +6`
cp $2/$1 .

nohup java -Xms512m -Xmx1536m -jar $1 > /dev/null 2>&1 &

if ps -ef | grep java | grep $1 | grep -v grep ;then
    i=`ps -ef | grep java | grep $1 | grep -v grep | awk '{print $2}'`
    echo $i
    while ! netstat -nltp | grep java | grep $i
    do
        echo "$1 正在启动......"
        sleep 10s
    done
else
    echo "$1 启动失败!"
fi
