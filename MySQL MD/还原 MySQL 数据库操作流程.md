#### 准备数据

##### 1、登录 ESXI 服务器 micro-dev(192.168.40.56)

##### 2 、创建 MySQL 5.7.30 容器

a.拉取镜像

```
docker pull mysql:5.7.30
```

b.启动容器

```
docker run --name mysql-rec -p 6666:3306 -e MYSQL_ROOT_PASSWORD='Abc@123456' -id mysql:5.7.30 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

##### 3、导入备份

```
docker exec -i mysql-rec sh -c 'exec mysql -uroot -p"Abc@123456"' < backup.dump
```

##### 4、导出需要还原的表

```
docker exec mysql-rec sh -c 'exec mysqldump db_name tb_name -uroot -p"Abc@123456"' > db_name-tb_name.dump
```

#### 恢复数据

##### 1、重命名被恢复表名

```
rename table old_table_name to new_table_name;
```

##### 2、恢复表

```
docker exec -i mysql-rec sh -c 'exec mysql -uroot -p"Abc@123456" db_name' < db_name-tb_name.dump
```

