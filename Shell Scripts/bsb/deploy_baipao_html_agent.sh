#!/bin/bash
# 停止 nginx
nginx -s stop
cd /var/www/html/
# 备份旧静态文件
tar zcf /tmp/html.tar.gz.`date +%Y%m%d.%H%M%S` index.html static --remove-files
# 获取静态文件
cp /data/backup/baipao/html/index.html .
cp -R /data/backup/baipao/html/static .
# 删除多余5次的备份
rm -f `ls -t /tmp/html.tar.gz.* | tail -n +6`
ls -tl
# 重启 nginx
nginx -t
nginx
while ! netstat -ntlp | grep nginx | grep 80
do
    echo "nginx 正在启动..."
    sleep 5s
done
echo "nginx 启动成功!"
