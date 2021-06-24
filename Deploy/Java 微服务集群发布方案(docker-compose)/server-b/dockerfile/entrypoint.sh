#!/bin/sh
SERVICE_NAME=$1
SERVICE_PORT=$2

while ! curl -I --connect-timeout 5 http://${SERVICE_NAME}:${SERVICE_PORT} >/dev/null 2>&1
do
    echo "等待启动 ${SERVICE_NAME}:${SERVICE_PORT} ......"
    sleep 5s
done

shift 2
cmd="$@"
$cmd
