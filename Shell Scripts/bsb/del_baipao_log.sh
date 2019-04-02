#!/bin/bash

name=`date +%Y-%m-%d -d "-1day"`
# 压缩删除 manager 日志
cd /usr/local/baipao/manager/applog
tar zcvf ${name}.tar.gz $name --remove-files
rm -f `ls -t *.tar.gz | tail -n +15`

# 压缩删除 driverapp 日志
cd /usr/local/baipao/driverapp/applog
tar zcvf ${name}.tar.gz $name --remove-files
rm -f `ls -t *.tar.gz | tail -n +15`
