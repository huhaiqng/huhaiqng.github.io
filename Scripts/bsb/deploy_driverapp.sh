#!/bin/bash
cd /data/backup/baipao/driverapp/
# 重命名旧包
mv baipao-driver-app-rest-2.0.0.jar baipao-driver-app-rest-2.0.0.jar.`date +%Y%m%d.%H%M%S`
# 将包拷贝到 188.188.1.133
ssh -p 2222 devuser@218.17.56.50 "sh ~/scripts/get_driverapp_from_uat.sh"
# 获取测试环境的包
scp -P 2222 devuser@218.17.56.50:~/baipao-driver-app-rest-2.0.0.jar .
chmod 755 baipao-driver-app-rest-2.0.0.jar
# 删除最近5个备份包以外的包
rm -f `ls -t baipao-driver-app-rest-2.0.0.jar.* | tail -n +6`
# 在172.16.1.55发布新包
echo "------------------------------ 在 172.16.1.55 发布新包 ------------------------------"
ssh tomcat@172.16.1.55 "sh /data/scripts/deploy_driverapp_agent.sh"
# 在172.16.1.65发布新包
echo "------------------------------ 在 172.16.1.65 发布新包 ------------------------------"
ssh tomcat@172.16.1.65 "sh /data/scripts/deploy_driverapp_agent.sh"
