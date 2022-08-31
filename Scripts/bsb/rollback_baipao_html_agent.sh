#!/bin/bash

cd /var/www/html
tar zcf html.tar.gz.`date +%Y%m%d.%H%M%S`.with.problem index.html static --remove-files

ls -tl /data/backup/baipao/html/html.tar.gz.*  | awk '{print $NF}'
echo "请输入回滚到哪一个包："
read package
# 重命名有问题的包名
tar zxf $package
echo "回滚完成！"
