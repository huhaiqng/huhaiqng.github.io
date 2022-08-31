#!/bin/bash
binlog_file=$1
start_time=$2
stop_time=$3
db_name=$4
tb_name=$5
colum_count=$6
grep_count=$[$colum_count+1]
time_tag=`date +%s`
delete_sql=delete-${time_tag}.sql
insert_sql=insert-${time_tag}.sql

if [ $# -ne 6 ]; then
    echo "参数错误"
    echo -e "脚本执行方式: sh $0 binlog_file start_time stop_time db_name tb_name colum_count
        binlog_file: 二进制日志名
        start_time: 日志开始时间
        stop_time: 日志结束时间
        db_name: 数据库名
        tb_name: 表名
        colum_count: 表字段数"
   echo "例子：sh $0 binlog.000012 '2022-05-20 11:00:00' '2022-05-20 12:00:00' sbtest sbtest1 5"
   exit 1
fi

mysqlbinlog \
--start-datetime="${start_time}" \
--stop-datetime="${stop_time}" \
--base64-output=decode-rows \
--database=${db_name} \
--skip-gtids \
-v /var/lib/mysql/binlog.000012 | \
grep -B 1 -A $grep_count "DELETE FROM \`${db_name}\`.\`${tb_name}\`" > ${delete_sql}

cp ${delete_sql} ${insert_sql}
sed -i 's/DELETE FROM/INSERT INTO/' $insert_sql
sed -i 's/WHERE/VALUES(/g' $insert_sql
sed -i 's/### //' $insert_sql

for((n=1;n<=$colum_count;n++))
do
    if [ $n -eq $colum_count ]; then
        sed -i "/@${n}=/s/$/&);/g" $insert_sql
    else    
        sed -i "/@${n}=/s/$/&,/g" $insert_sql
    fi
    sed -i "s/@${n}=//g" $insert_sql
done
