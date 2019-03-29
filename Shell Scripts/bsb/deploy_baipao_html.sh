#!/bin/bash
cd /data/backup/baipao/html/
# 打包旧静态文件，用于回滚
tar zcf html.tar.gz.`date +%Y%m%d.%H%M%S` index.html static --remove-files
# 获取静态文件
scp -P 2222 devuser@218.17.56.50:~/index.html .
scp -r -P 2222 devuser@218.17.56.50:~/static .
# 删除前多余5次的备份
rm -f `ls -t html.tar.gz.* | tail -n +6`

# 在172.16.1.55发布静态文件
echo "------------------------------ 在 172.16.1.55 更新静态文件 ------------------------------"
ssh root@172.16.1.55 "sh /data/scripts/deploy_baipao_html_agent.sh"
# 在172.16.1.65发布静态文件
echo "发布完成"
echo "------------------------------ 在 172.16.1.65 发布静态文件 ------------------------------"
ssh root@172.16.1.65 "sh /data/scripts/deploy_baipao_html_agent.sh"
echo "发布完成"
