#### 使用 docker-compose 部署

自定义配置文件 custom.cnf

MySQL8.0 docker-compose.yml 文件

> 数据文件目录: /data/mysql8.0/data
>
> 配置文件目录: /data/mysql8.0/conf

```
version: '3.8'

services:
  mysql8.0:
    image: mysql:8.0.25
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: MySQL8.0
    volumes:
       - /data/mysql8.0/data:/var/lib/mysql
       - /data/mysql8.0/conf:/etc/mysql/conf.d
    ports:
      - "3306:3306"
```

MySQL5.7 docker-compose.yml 文件

> 数据文件目录: /data/mysql5.7/data
>
> 配置文件目录: /data/mysql5.7/conf

```
version: '3.8'

services:
  mysql5.7:
    image: mysql:5.7.34
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: MySQL5.7
    volumes:
       - /data/mysql5.7/data:/var/lib/mysql
       - /data/mysql5.7/conf:/etc/mysql/conf.d
    ports:
      - "3306:3306"
```

MySQL5.6 docker-compose.yml 文件

> 数据文件目录: /data/mysql5.6/data
>
> 配置文件目录: /data/mysql5.6/conf

```
version: '3.8'

services:
  mysql5.6:
    image: mysql:5.6.51
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: MySQL5.6
    volumes:
       - /data/mysql5.6/data:/var/lib/mysql
       - /data/mysql5.6/conf:/etc/mysql/conf.d
    ports:
      - "3306:3306"
```

