#!/usr/bin/env python
# encoding: utf-8
import argparse
import mysql.connector
import os

parser = argparse.ArgumentParser(description='发布 jar 包')
parser.add_argument('-p', required=True, dest='project_name', action='store',  help='项目名称')
parser.add_argument('-e', required=True, dest='publish_env', action='store',  help='发布环境')
args = parser.parse_args()

project_name = args.project_name
publish_env = args.publish_env


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
    # crs.close()
    # cnx.close()
    return result


def build_jar():
    build_host_select = "SELECT h.outside_ip, h.outside_port, bh.user FROM project_buildhost bh " \
                        "INNER JOIN project_project p ON bh.project_id = p.id " \
                        "INNER JOIN project_host h ON bh.host_id = h.id " \
                        "INNER JOIN project_env e ON bh.env_id = e.id " \
                        "WHERE p.alias = '%s' AND e.alias = '%s'" % (project_name, publish_env)
    select_type = 'one'
    build_host = exec_sql(build_host_select, select_type)
    if build_host is not None:
        build_server_ip, build_server_port, build_user = build_host
        build_cmd = "sh /data/scripts/publish-jar-v2/build_jar.sh %s %s %s %s %s" \
                    % (project_name, publish_env, build_server_ip, build_server_port, build_user)
        print(build_cmd)
        stat = os.system(build_cmd)
        if stat == 0:
            print('打包成功！')
        else:
            print('打包失败')
            raise SystemExit(1)
    else:
        print('项目 %s 不存在或在环境 %s 没有打包服务器！' % (project_name, publish_env))


def publish_jar():
    publish_host_select = "SELECT h.outside_ip, outside_port, p.deploy_obj, p.user FROM project_project p " \
                          "INNER JOIN project_project_hosts ph ON p.id = ph.project_id " \
                          "INNER JOIN project_host h ON ph.host_id = h.id " \
                          "INNER JOIN project_env e ON h.env = e.NAME " \
                          "WHERE p.alias = '%s' AND e.alias = '%s'" % (project_name, publish_env)
    select_type = 'all'
    publish_hosts = exec_sql(publish_host_select, select_type)
    if len(publish_hosts) != 0:
        for publish_host_ip, publish_host_port, deploy_obj, publish_user in publish_hosts:
            publish_cmd = "sh /data/scripts/publish-jar-v2/deploy_jar.sh %s %s %s %s %s %s" \
                    % (project_name, publish_env, publish_host_ip, publish_host_port, deploy_obj, publish_user)
            print(publish_cmd)
            stat = os.system(publish_cmd)
            if stat == 0:
                print('发布成功！')
            else:
                print('发布失败')
                raise SystemExit(1)
    else:
        print('项目 %s 在环境 %s 分配部署的服务器！' % (project_name, publish_env))


build_jar()
publish_jar()
