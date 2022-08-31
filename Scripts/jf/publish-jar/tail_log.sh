#!/bin/bash
PROJECT_NAME=$1
COUNT=$2
LOG_DATE=`date +%Y-%m-%d`

if [ "${PROJECT_NAME}" = "gem-machine-a" ]; then
    echo "开始查看测试环境 A 上的日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@47.106.230.34 "tail -n $COUNT -f /data/logs/jparklogs/jpark-gem-machineg/${LOG_DATE}.log"
elif [ "${PROJECT_NAME}" = "gem-machine-b" ]; then
    echo "开始查看测试环境 B 上的日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 pro@47.107.240.15 "tail -n $COUNT -f /data/logs/jparklogs/jpark-gem-machineg/${LOG_DATE}.log"
elif [ "${PROJECT_NAME}" = "gem-machine-prod-a" ]; then
    echo "开始查看生产环境 A 上的日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/jparklogs/jpark-gem-machineg/${LOG_DATE}.log"
elif [ "${PROJECT_NAME}" = "gem-machine-prod-b" ]; then
    echo "开始查看生产环境 B 上的日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 pro@47.106.144.86 "tail -n $COUNT -f /data/logs/jparklogs/jpark-gem-machineg/${LOG_DATE}.log"
elif [ "${PROJECT_NAME}" = "warehouse-test" ]; then
    echo "开始查看云仓测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22006 www@139.159.252.64 "tail -n $COUNT -f /data/logs/wms/wms_debug.log"
elif [ "${PROJECT_NAME}" = "warehouse-prod" ]; then
    echo "开始查看云仓生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/wms/wms_debug.log"
elif [ "${PROJECT_NAME}" = "jew-cust-test" ]; then
    echo "开始查看定制测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22006 www@139.159.252.64 "tail -n $COUNT -f /data/logs/jew-customized/jew-customized_debug.log"
elif [ "${PROJECT_NAME}" = "digitalfactory-test" ]; then
    echo "开始查看产业互联测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/digital-factory/base/base_debug.log"
elif [ "${PROJECT_NAME}" = "digitalfactory-prod" ]; then
    echo "开始查看产业互联生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22005 www@139.159.252.64 "tail -n $COUNT -f /data/logs/digital-factory/base/base_debug.log"
elif [ "${PROJECT_NAME}" = "ordermgr-test" ]; then
    echo "开始查看 ordermgr 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/ordermgr/ordermgr.log"
elif [ "${PROJECT_NAME}" = "ordermgr-prod" ]; then
    echo "开始查看 ordermgr 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/ordermgr/ordermgr.log"
elif [ "${PROJECT_NAME}" = "sysmgr-test" ]; then
    echo "开始查看 sysmgr 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/sysmgr/sysmgr.log"
elif [ "${PROJECT_NAME}" = "sysmgr-prod" ]; then
    echo "开始查看 sysmgr 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/sysmgr/sysmgr.log"
elif [ "${PROJECT_NAME}" = "productmgr-test" ]; then
    echo "开始查看 productmgr 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/productmgr/productmgr.log"
elif [ "${PROJECT_NAME}" = "productmgr-prod" ]; then
    echo "开始查看 productmgr 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/productmgr/productmgr.log"
elif [ "${PROJECT_NAME}" = "warehousing-test" ]; then
    echo "开始查看 warehousing 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/warehousingmgr/warehousingmgr.log"
elif [ "${PROJECT_NAME}" = "warehousing-prod" ]; then
    echo "开始查看 warehousing 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/warehousingmgr/warehousingmgr.log"
elif [ "${PROJECT_NAME}" = "purchase-test" ]; then
    echo "开始查看 purchase 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/purchase/purchase.log"
elif [ "${PROJECT_NAME}" = "purchase-prod" ]; then
    echo "开始查看 purchase 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22 www@47.115.115.183 "tail -n $COUNT -f /data/logs/purchase/purchase.log"
elif [ "${PROJECT_NAME}" = "3pdatasyn-test" ]; then
    echo "开始查看 3pdatasyn 测试环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 52113 test@39.98.71.133 "tail -n $COUNT -f /data/logs/3pdatasyn/spdatasyn_info.log"
elif [ "${PROJECT_NAME}" = "3pdatasyn-prod" ]; then
    echo "开始查看 3pdatasyn 生产环境日志"
    sleep 5s
    ssh -i /root/.ssh/deploy -p 22219 pro@139.159.252.64 "tail -n $COUNT -f /data/logs/3pdatasyn/spdatasyn_info.log"
else
    echo "项目 ${PROJECT_NAME} 不能查看日志"
fi
