#!/usr/bin/env python3
# encoding: utf-8
import argparse
import mysql.connector
import os
import time

parser = argparse.ArgumentParser(description='发布 jar 包')
parser.add_argument('-p', required=True, dest='project_name', action='store',  help='项目名称')
parser.add_argument('-e', required=True, dest='publish_env', action='store',  help='发布环境')
args = parser.parse_args()

project_name = args.project_name
publish_env = args.publish_env
image_tag = publish_env + time.strftime("-%Y%m%d%H%M%S", time.localtime())


# 执行 sql
def exec_sql(sql, select_type):
    cnx = mysql.connector.connect(user='yunwei', password='L1^pd0tX&Y9P', buffered=True, host='192.168.40.185', database='yunwei')
    crs = cnx.cursor()
    crs.execute(sql)
    if select_type == 'all':
        result = crs.fetchall()
    elif select_type == 'one':
        result = crs.fetchone()
    else:
        result = None
    return result


def create_image():
    deploy_obj_select = "SELECT deploy_obj FROM project_project WHERE alias = '%s'" % project_name
    select_type = 'one'
    deploy_obj = exec_sql(deploy_obj_select, select_type)
    if deploy_obj is not None:
        jar_path, = deploy_obj
    else:
        print('项目 %s 不存在！' % project_name)
        raise SystemExit(1)
    create_image_cmd = "sh /data/scripts/publish-microservice/create_image.sh %s %s %s" \
                       % (project_name, jar_path, image_tag)
    stat = os.system(create_image_cmd)
    if stat == 0:
        print('创建成功！')
    else:
        print('创建失败！')
        raise SystemExit(1)


def publish_jar():
    publish_host_select = "SELECT h.outside_ip, outside_port, p.user FROM project_project p " \
                          "INNER JOIN project_project_hosts ph ON p.id = ph.project_id " \
                          "INNER JOIN project_host h ON ph.host_id = h.id " \
                          "INNER JOIN project_env e ON h.env = e.NAME " \
                          "WHERE p.alias = '%s' AND e.alias = '%s'" % (project_name, publish_env)
    select_type = 'all'
    publish_hosts = exec_sql(publish_host_select, select_type)
    if len(publish_hosts) != 0:
        for publish_host_ip, publish_host_port, publish_user in publish_hosts:
            publish_cmd = "sh /data/scripts/publish-microservice/deploy_jar_service.sh %s %s %s %s %s" \
                % (project_name, publish_host_ip, publish_host_port, publish_user, image_tag)
            stat = os.system(publish_cmd)
            if stat == 0:
                print('发布成功！')
            else:
                print('发布失败')
                raise SystemExit(1)
    else:
        print('项目 %s 在环境 %s 没有分配的服务器或项目不存在！' % (project_name, publish_env))


create_image()
publish_jar()
