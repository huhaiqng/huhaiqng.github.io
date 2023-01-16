#### 单机模式

**下载源码包**

下载地址: https://github.com/alibaba/nacos/archive/refs/tags/2.2.0.tar.gz

**打包**

```
cd /usr/local/src
tar zxvf nacos-2.2.0.tar.gz
cd nacos-2.2.0
mvn -Prelease-nacos -Dmaven.test.skip=true clean install -U
cp distribution/target/nacos-server-2.2.0/nacos /usr/local/nacos
```

**创建数据库**

```
create database nacos;
create user nacos@'%' identified by 'Nacos.123';
grant all on nacos.* to nacos@'%';
flush privileges;
use nacos;
source /usr/local/nacos/conf/mysql-schema.sql;
```

**修改数据库配置文件 `/usr/local/nacos/conf/application.properties`**

```
#*************** Config Module Related Configurations ***************#
### If use MySQL as datasource:
spring.datasource.platform=mysql

### Count of DB:
db.num=1

### Connect URL of DB:
db.url.0=jdbc:mysql://192.168.198.10:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=UTC
db.user.0=nacos
db.password.0=Nacos.123
```

**管理**

```
cd /usr/local/nacos/bin
# 启动
sh startup.sh -m standalone
# 关闭
sh shutdown.sh
```



#### 集群模式

**打包**

```
cd /usr/local/src
tar zxvf nacos-2.2.0.tar.gz
cd nacos-2.2.0
mvn -Prelease-nacos -Dmaven.test.skip=true clean install -U
cp distribution/target/nacos-server-2.2.0/nacos /usr/local/nacos-8848
cp distribution/target/nacos-server-2.2.0/nacos /usr/local/nacos-8858
cp distribution/target/nacos-server-2.2.0/nacos /usr/local/nacos-8868
```

**修改配置文件端口号**

```
# nacos-8848
server.port=8848
# nacos-8858
server.port=8858
# nacos-8848
server.port=8868
```

**修改集群配置文件`cluster.conf`**

```
192.168.198.10:8848
192.168.198.10:8858
192.168.198.10:8868
```

**管理**

```
# 启动
sh startup.sh
# 关闭
sh shutdown.sh
```



#### 发布获取配置

**发布配置**

```
curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"```
```

**获取配置**

```
curl -X GET "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test"
```



参考文档: https://nacos.io/zh-cn/docs/v2/guide/admin/cluster-mode-quick-start.html