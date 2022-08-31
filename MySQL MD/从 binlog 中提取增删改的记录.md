##### 提前删除的记录

> -B 1:  过滤行前面的行数，显示执行的时间
>
> -A 5:  过滤行后面的行数，等于表字段数加1

```
mysqlbinlog \
--start-datetime="2022-05-20 11:00:00" \
--stop-datetime="2022-05-20 12:00:00" \
--base64-output=decode-rows \
--database=sbtest \
--skip-gtids \
-v /var/lib/mysql/binlog.000012 | \
grep -B 1 -A 5 "DELETE FROM \`sbtest\`.\`sbtest1\`" > delete.sql
```

创建脚本 delete_to_insert.sh，将删除 sql 改为新增 sql

```
#!/bin/bash
# 表的字段数
count=$1
# 提前删除的记录文件名
file_name=$2
sed -i 's/DELETE FROM/INSERT INTO/' $file_name
sed -i 's/WHERE/VALUES(/g' $file_name
sed -i 's/### //' $file_name

for((n=1;n<=$count;n++))
do
    echo $n
    if [ $n -eq $count ]; then
        sed -i "/@${n}=/s/$/&);/g" $file_name
    else    
        sed -i "/@${n}=/s/$/&,/g" $file_name
    fi
    sed -i "s/@${n}=//g" $file_name
done
```

##### 提前修改的记录

> -B 1:  过滤行前面的行数，显示执行的时间
>
> -A 10:  过滤行后面的行数，等于表字段数加1的两倍

```
mysqlbinlog \
--start-datetime="2022-05-20 11:00:00" \
--stop-datetime="2022-05-20 12:00:00" \
--base64-output=decode-rows \
--database=sbtest \
--skip-gtids \
-v /var/lib/mysql/binlog.000012 | \
grep -B 1 -A 10 "UPDATE \`sbtest\`.\`sbtest1\`" > update.sql
```

##### 提前新增的记录

> -B 1:  过滤行前面的行数，显示执行的时间
>
> -A 5:  过滤行后面的行数，等于表字段数加1

```
mysqlbinlog \
--start-datetime="2022-05-20 11:00:00" \
--stop-datetime="2022-05-20 12:00:00" \
--base64-output=decode-rows \
--database=sbtest \
--skip-gtids \
-v /var/lib/mysql/binlog.000012 | \
grep -B 1 -A 5 "INSERT INTO \`sbtest\`.\`sbtest1\`" > insert.sql
```

