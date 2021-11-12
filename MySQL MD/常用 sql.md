##### 查询占空间最大的 10 个表

```sql
SELECT
	TABLE_ROWS,
	TABLE_SCHEMA,
	TABLE_NAME,
	ROUND(DATA_LENGTH/1024/1024/1024,2) AS DATA_LENGTH,
	ROUND(INDEX_LENGTH/1024/1024/1024,2) AS INDEX_LENGTH,
	ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024/1024,2) AS TOTAL
FROM
	information_schema.`TABLES` 
ORDER BY TOTAL DESC
LIMIT 10;
```

##### 查询每个数据库的大小

```sql
SELECT
	TABLE_SCHEMA, SUM(DATA_LENGTH + INDEX_LENGTH)/1024/1024/1024 AS TOTAL
FROM
	information_schema.`TABLES` 
GROUP BY TABLE_SCHEMA
ORDER BY TOTAL DESC;
```

##### 查询指定数据库占空间最大的 10 个表

```sql
SELECT
	TABLE_ROWS,
	TABLE_SCHEMA,
	TABLE_NAME,
	ROUND(DATA_LENGTH/1024/1024/1024,2) AS DATA_LENGTH,
	ROUND(INDEX_LENGTH/1024/1024/1024,2) AS INDEX_LENGTH,
	ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024/1024,2) AS TOTAL
FROM
	information_schema.`TABLES` 
WHERE
	TABLE_SCHEMA = 'DB_NAME'
ORDER BY TOTAL DESC
LIMIT 10;
```

##### 查询耗时最多的 10 个线程

```sql
SELECT * FROM information_schema.`PROCESSLIST` ORDER BY TIME DESC LIMIT 10;
```

##### 查询等待的 SQL

```sql
SELECT
	r.trx_id waiting_trx_id,
	r.trx_mysql_thread_id waiting_thread,
	r.trx_query waiting_query,
	b.trx_id blocking_trx_id,
	b.trx_mysql_thread_id blocking_thread,
	b.trx_query blocking_query 
FROM
	information_schema.innodb_lock_waits w
	INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
	INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;
```

