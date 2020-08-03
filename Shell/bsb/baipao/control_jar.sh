#!/bin/bash
set -e

IFS=$'\n\n'  
if [ $# -ne 2 ];then
    echo "参数错误！"
    echo "正确的格式：sh control_jar.sh start|stop|restart ***.jar"
    exit
fi

c_cmd=$1
c_jar=$2

chk=`awk -v var=$c_jar '{if($1 == var) print}' /data/scripts/baipao/config_jar.txt`
if [ "$chk" = "" ];then
    echo "包 $c_jar 不存在！"
    exit
else
    for l in $chk
    do
        host=`echo $l | awk '{print $2}'`
        de_dir=`echo $l | awk '{print $4}'`
        echo "---------------------- 在 $host 上 $c_cmd 包 $c_jar ----------------------"
        ssh tomcat@$host "sh /data/scripts/baipao/control_jar_agent.sh $c_cmd $c_jar $de_dir"
    done
fi
