#!/bin/bash
if [ $# -ne 1 ] ;then
    echo "参数错误！"
    echo "请输入：sh ans_deploy_microbaipao_jar_agent.sh app"
    exit
fi

ansible $1 -m shell -u tomcat -f 1 -a "sh /data/scripts/microbaipao/deploy_microbaipao_jar_agent.sh $1"
