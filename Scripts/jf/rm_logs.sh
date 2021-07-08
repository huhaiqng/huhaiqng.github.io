#!/bin/bash
echo "开始执行时间：`date`"
# 清理 jpark 日志
for log_dir in `ls /data/logs/jparklogs/`
do
    echo "------------------ /data/logs/jparklogs/$log_dir ------------------"
    if [ -n "$log_dir" ]; then
        cd /data/logs/jparklogs/$log_dir && tar zcvf /tmp/${log_dir}.tar.gz `ls -t *.log | tail -n +15` --remove-files
    fi
done
# 清理 tomcat 日志
cd /usr/local/tomcat/logs && tar zcvf /tmp/catalina.log.tar.gz `ls -t catalina.*.log | tail -n +8` --remove-files
cd /usr/local/tomcat/logs && tar zcvf /tmp/host-manager.log.tar.gz `ls -t host-manager.*.log | tail -n +8` --remove-files
cd /usr/local/tomcat/logs && tar zcvf /tmp/localhost.log.tar.gz `ls -t localhost.*.log | tail -n +8` --remove-files
cd /usr/local/tomcat/logs && tar zcvf /tmp/localhost_access_log.txt.tar.gz `ls -t localhost_access_log.*.txt | tail -n +8` --remove-files
cd /usr/local/tomcat/logs && tar zcvf /tmp/manager.log.tar.gz `ls -t manager.*.log | tail -n +8` --remove-files
# 清理临时文件
cd /tmp && tar zcvf tomcat-tmp.tar.gz `ls -td tomcat.* | tail -n +10` --remove-files
cd /tmp && tar zcvf tomcat-docbase-tmp.tar.gz `ls -td tomcat-docbase* | tail -n +10` --remove-files
