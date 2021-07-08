#!/bin/bash

# 在172.16.1.55回滚静态文件
echo "------------------------------ 在 172.16.1.55 回滚包 ------------------------------"
ssh root@172.16.1.55 "sh /data/scripts/rollback_baipao_html_agent.sh"
# 在172.16.1.65回滚静态文件
echo "------------------------------ 在 172.16.1.65 回滚包 ------------------------------"
ssh root@172.16.1.65 "sh /data/scripts/rollback_baipao_html_agent.sh"
