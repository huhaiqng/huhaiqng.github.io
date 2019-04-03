#!/bin/bash
if [ $# -ne 3 ];then
    echo "参数错误！"
    echo "正确的格式：sh deploy_jar_agent.sh 包名 源包目录 发布目录"
    exit
fi

echo "$1 $2 $3"

