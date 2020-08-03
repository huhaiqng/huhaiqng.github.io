#!/bin/bash
IFS=$'\n\n'  
if [ $# -ne 1 ];then
    echo "参数错误！"
    echo "正确的格式：sh rollback_jar.sh ***.jar"
    exit
fi

chk=`awk -v var=$1 '{if($1 == var) print}' /data/scripts/baipao/config_jar.txt`
if [ "$chk" = "" ];then
    echo "包 $1 不存在！"
    exit
else
    for l in $chk
    do
        host=`echo $l | awk '{print $2}'`
        or_dir=`echo $l | awk '{print $3}'`
        de_dir=`echo $l | awk '{print $4}'`
        echo "---------------------- 在 $host 上回滚包 $1 ----------------------"
        ssh tomcat@$host "sh /data/scripts/baipao/rollback_jar_agent.sh $1 $or_dir $de_dir"
    done
fi
