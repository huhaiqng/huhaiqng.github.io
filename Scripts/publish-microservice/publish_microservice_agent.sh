#!/bin/bash
set -e

SERVICE_NAME=$1
IMAGE_TAG=$2

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 SERVICE_NAME IMAGE_TAG"
    exit 1
fi

cd /data/microservice
sed -i "/${SERVICE_NAME}tag/d" .env
echo "${SERVICE_NAME}tag=${IMAGE_TAG}" >> .env

docker-compose up -d ${SERVICE_NAME}
