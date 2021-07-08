#!/bin/bash
set -e
PROJECT_NAME=$1
TIME_TAG=$2
VERSION_DIR="/data/wwwroot/versions/${PROJECT_NAME}-${TIME_TAG}"
TAR_FILE=/tmp/${PROJECT_NAME}-${TIME_TAG}.tar.gz

if [ $# -ne 2 ]; then
    echo "参数错误！正确格式: sh $0 PROJECT_NAME TIME_TAG"
    exit 1
fi

if [ ! -f ${TAR_FILE} ]; then
    echo "源包 ${TAR_FILE} 不存在"
    exit 1
fi

mkdir -p ${VERSION_DIR}
echo "解压包 ${TAR_FILE}"
cd ${VERSION_DIR} && tar zxf ${TAR_FILE}
chown -R www.www ${VERSION_DIR}
echo "更新软链接"
cd /data/wwwroot && ln -snf ${VERSION_DIR} ${PROJECT_NAME}

echo "清理过期包"
rm -f ${TAR_FILE}
cd /data/wwwroot/versions
EXPIRE_VERSION=`ls -td ${PROJECT_NAME}-* | tail -n +4`
if [ -n "${EXPIRE_VERSION}" ]; then
    echo "清理历史版本: ${EXPIRE_VERSION}"
    tar zcf /tmp/${PROJECT_NAME}-`date +%s`.tar.gz `ls -td ${PROJECT_NAME}-* | tail -n +4` --remove-files
else
    echo "没有需要清理的历史版本"
fi
