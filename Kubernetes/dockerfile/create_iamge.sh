#!/bin/bash
PROJECT_NAME=tdrendering-web
NAMESPACE=prod
IMAGE_TAG=`date +%Y%m%d%H%M%S`
IMAGE_NAME=harbor.lingfannao.net:4436/${NAMESPACE}/${PROJECT_NAME}:${IMAGE_TAG}
# KUBE_CMD="kubectl set image statefulset/${PROJECT_NAME} app=${IMAGE_NAME} -n ${NAMESPACE} --record"
cd /data/jenkins/workspace/lfn-3drendering-web-production && docker build -t ${IMAGE_NAME} -f /data/dockerfile/nginx .
docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}
# ssh -i /root/.ssh/deploy -p 22219 pro@139.159.252.64 "${KUBE_CMD}"
