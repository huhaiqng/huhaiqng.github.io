#!/bin/bash

# 在172.16.1.55回滚包
echo "------------------------------ 在 172.16.1.55 回滚包 ------------------------------"
ssh tomcat@172.16.1.55 "sh /data/scripts/rollback_manager_agent.sh"
# 在172.16.1.65回滚包
echo "------------------------------ 在 172.16.1.65 回滚包 ------------------------------"
ssh tomcat@172.16.1.65 "sh /data/scripts/rollback_manager_agent.sh"
