#!/bin/bash
ws=`dirname $0`
if [ $# -ne 1 ];then
    echo "参数错误！"
    echo "正确的格式：sh deploy_jar.sh ***.jar"
    exit
fi

chk=`awk -v var=$1 '{if($1 == var) print}' $ws/config_jar.txt`
if [ "$chk" = "" ];then
    echo "包 $1 不存在！"
    exit
else
    host=`awk -v var=$1 '{if($1 == var) print $2}' $ws/config_jar.txt`
    or_dir=`awk -v var=$1 '{if($1 == var) print $3}' $ws/config_jar.txt`
    cd ~/
    rm -f $1
    scp $host:$or_dir/$1 .
fi
