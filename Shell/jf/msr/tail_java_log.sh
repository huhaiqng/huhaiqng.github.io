#!/bin/bash
PROJECT_NAME=$1
PROJECT_ENV=$2
MODULE_NAME=$3

if [ $# -ne 3 ];then
    echo "参数错误！正确格式：sh $0 DigitalFactory PROJECT_NAME PROJECT_ENV"
    exit 1
fi

if [ "${PROJECT_NAME}" = "goldtd" -a "${PROJECT_ENV}" = "test" ]; then
    if [ "${MODULE_NAME}" = "all" ];then
        sleep 10s
        ssh -i /root/.ssh/deploy www@47.112.166.147 "cd /data/goldtd && docker-compose logs -f --tail=10"
    else
        sleep 10s
        ssh -i /root/.ssh/deploy www@47.112.166.147 "cd /data/goldtd && docker-compose logs -f --tail=10 ${MODULE_NAME}"
    fi
elif [ "${PROJECT_NAME}" = "DigitalFactory" -a "${PROJECT_ENV}" = "prod" ]; then
    if [ "${MODULE_NAME}" = "all" ];then
        sleep 10s
        ssh -p 22005 -i /root/.ssh/deploy root@139.159.252.64 "cd /data/digital-factory/compose && docker-compose -p dj logs -f --tail=${TAIL_COUNT}"
    else
        sleep 10s
        ssh -p 22005 -i /root/.ssh/deploy root@139.159.252.64 "cd /data/digital-factory/compose && docker-compose -p dj logs -f --tail=${TAIL_COUNT} ${MODULE_NAME}"
    fi
else
    echo "${PROJECT_NAME} 或 ${PROJECT_ENV} 错误！"
fi
