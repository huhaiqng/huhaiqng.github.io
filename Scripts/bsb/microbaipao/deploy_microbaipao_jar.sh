#!/bin/bash
set -e
if [ $# -ne 1 ] ;then
    echo "参数错误!!!"
    echo "正确的格式：sh deploy_microbaipao_jar.sh app"
    exit
fi

if ! ssh -p 2222 devuser@218.17.56.50 "date" ; then
    echo "连接远程主机失败"
    exit
fi
pkg_name=baipao-$1.jar
pkg_dir=/data/backup/microbaipao/$1

ssh -p 2222 devuser@218.17.56.50 "sh ~/microbaipao/get_jar_from_jenkins.sh $1"
cd $pkg_dir
[[ -f $pkg_name ]] && mv $pkg_name $pkg_name.`date +%Y%m%d.%H%M%S`
scp -P 2222 devuser@218.17.56.50:~/microbaipao/$pkg_name .
rm -f `ls -t $pkg_name | tail -n +6`

ssh -p 2222 devuser@218.17.56.50 "md5sum ~/microbaipao/$pkg_name"
md5sum $pkg_name
r_md5=`ssh -p 2222 devuser@218.17.56.50 "md5sum ~/microbaipao/$pkg_name" | awk '{print $1}'`
l_md5=`md5sum $pkg_name | awk '{print $1}'`

if [ "$r_md5" != "$l_md5" ] ;then
    echo "从测试环境获取包 $1 失败！"
    ls -lt
    exit
else
    echo "包 $pkg_name 成功从测试环境获取!"
fi

ansible $1 -m shell -u tomcat -f 1 -a "sh /data/scripts/microbaipao/deploy_microbaipao_jar_agent.sh $1"
