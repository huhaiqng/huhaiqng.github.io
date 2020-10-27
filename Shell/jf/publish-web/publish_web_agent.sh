#!/bin/bash
set -e
PROJECT_NAME=$1
TIME_TAG=$2
VERSION_DIR="/data/wwwroot/versions/${PROJECT_NAME}-${TIME_TAG}"
TAR_FILE=/tmp/${PROJECT_NAME}-${TIME_TAG}.tar.gz

if [ ! -f ${TAR_FILE} ]; then
    echo "源包 ${TAR_FILE} 不存在"
    exit 1
fi

mkdir -p ${VERSION_DIR}
echo "解压包 ${TAR_FILE}"
cd ${VERSION_DIR} && tar zxf ${TAR_FILE}
echo "更新软链接"
cd /data/wwwroot && ln -snf ${VERSION_DIR} ${PROJECT_NAME}
echo "清理过期包"
cd /data/wwwroot/versions && tar zcf /tmp/${PROJECT_NAME}.tar.gz `ls -td $PROJECT_NAME-* | tail -n +5` --remove-files
rm -f ${TAR_FILE}
