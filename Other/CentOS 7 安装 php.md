### 安装 epel 和 remi 源
```
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y remi-release-7.rpm
```

### 安装 yum 管理工具

```
yum install -y yum-utils
```

### 启用 remi-php

```
# 安装 php5.6
yum-config-manager --enable remi-php56
# 安装 php5.5
yum-config-manager --enable remi-php55   [Install PHP 5.5]
# 安装 php7.2
yum-config-manager --enable remi-php72   [Install PHP 7.2]
```

### 安装 php

```
yum install -y php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-odbc php-pear php-xml php-xmlrpc php-mbstring php-bcmath php-mhash
```

参考博文：<https://www.tecmint.com/install-php-5-6-on-centos-7/>