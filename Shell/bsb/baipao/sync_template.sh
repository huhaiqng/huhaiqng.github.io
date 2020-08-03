#!/bin/bash
# 备份目录
tar zcvf /tmp/template.`date +%s`.tar.gz /data/baipao/template/
rm -f `ls -t /tmp/template.*.tar.gz | tail -n +6`
# 同步目录
rsync -auvrtzopgP -e "ssh -p 2222" devuser@218.17.56.50:/mntdisk/baipao/template/ /data/baipao/template/
chown -R tomcat.tomcat /data/baipao/template/
