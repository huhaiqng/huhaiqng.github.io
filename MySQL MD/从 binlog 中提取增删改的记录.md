提前删除的记录

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

提前修改的记录

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

提前新增的记录

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

