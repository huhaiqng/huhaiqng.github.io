#!/bin/bash
cd /data/backup/baipao/manager
# 重命名旧包
mv baipao-manager-rest-2.0.0.jar baipao-manager-rest-2.0.0.jar.`date +%Y%m%d.%H%M%S`
# 获取测试环境的包
scp -P 2222 devuser@218.17.56.50:~/baipao-manager-rest-2.0.0.jar .
chmod 755 baipao-manager-rest-2.0.0.jar
# 删除最近5个备份包以外的包
rm -f `ls -t baipao-manager-rest-2.0.0.jar.* | tail -n +6`
# 在172.16.1.55发布新包
echo "------------------------------ 在 172.16.1.55 发布新包 ------------------------------"
ssh tomcat@172.16.1.55 "sh /data/scripts/deploy_manager_agent.sh"
# 在172.16.1.65发布新包
echo "------------------------------ 在 172.16.1.65 发布新包 ------------------------------"
ssh tomcat@172.16.1.65 "sh /data/scripts/deploy_manager_agent.sh"
