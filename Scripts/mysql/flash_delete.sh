#!/bin/bash
set -e
echo "说明：此脚本需要5个参数(提取二进制日志开始时间、结束时间，数据库，表和二进制日志文件！"
echo "      脚本运行完后会生成包含恢复记录的SQL语句的 insert.sql 文件！"
if [ $# -ne 5 ];then
    echo "参数错误!!!"
    echo "正确的格式：sh flash_delete.sh start_time end_time database table binlog_file"
    echo "例子：sh flash_delete.sh '2018-08-02 10:00:00' '2018-08-02 12:00:00' db tb mysql-bin.00001"
    exit
fi
s_time=$1
e_time=$2
db=$3
tb=$4
blfile=$5
vbinlog=vbl.log
rbinlog=insert.sql
# 提取二进制日志
mysqlbinlog \
--base64-output=decode-rows \
--start-datetime="$s_time" \
--database=$db \
--stop-datetime="$e_time" \
--skip-gtids \
-v $blfile | grep -A50 "DELETE FROM \`$db\`.\`$tb\`" > $vbinlog

st=0
vl=''
vls=''
while read line
do
    if [ $st = 0 ] ; then
       if echo $line | grep "DELETE FROM \`$db\`.\`$tb\`";then
            st=1
            vls="INSERT INTO \`$db\`.\`$tb\` VALUES ("
            continue
        fi
    fi

    if [ $st = 1 ] ; then
        if echo $line | grep "WHERE";then
            continue
        fi
        if echo $line | grep "=";then
            if [ "$vl" != '' ] ;then
                vls="$vls$vl,"
            fi
            vl=`echo $line | sed 's/.......//'`
            continue
        fi
        if echo $line | grep "DELETE FROM \`$db\`.\`$tb\`";then
            echo "$vls$vl);" >> $rbinlog
            vl=''
            vls="INSERT INTO \`$db\`.\`$tb\` VALUES ("
            continue
        fi
        echo "$vls$vl);" >> $rbinlog
        vl=''
        st=0
    fi

done < $vbinlog
