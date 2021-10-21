#!/usr/bin/env python3
# encoding: utf-8
import argparse
import mysql.connector
import os

parser = argparse.ArgumentParser(description='发布 war 包')
parser.add_argument('-p', required=True, dest='project_name', action='store',  help='项目名称')
parser.add_argument('-m', required=True, dest='module_name', action='store',  help='模块名称')
parser.add_argument('-e', required=True, dest='publish_env', action='store',  help='发布环境')
parser.add_argument('-v', required=True, dest='war_version', action='store',  help='版本')
args = parser.parse_args()

project_name = args.project_name
module_name = args.module_name
publish_env = args.publish_env
war_version = args.war_version

# 执行 sql
def exec_sql(sql):
    cnx = mysql.connector.connect(user='doplat', password='z4gjyi%P', buffered=True, host='192.168.40.185', database='doplat')
    crs = cnx.cursor()
    crs.execute(sql)
    result = crs.fetchall()
    return result

def publish_jar():
    publish_host_select = "SELECT h.outside_ip, outside_port, p.user, pm.deploy_dir, pm.pkg_name, pm.port FROM project_project p " \
                          "INNER JOIN project_project_hosts ph ON p.id = ph.project_id " \
                          "INNER JOIN project_host h ON ph.host_id = h.id " \
                          "INNER JOIN project_env e ON h.env = e.NAME " \
                          "INNER JOIN project_projectmodule pm ON p.id = pm.project_id " \
                          "WHERE p.alias = '%s' AND pm.name = '%s' AND e.alias like '%s%%'" % (project_name, module_name, publish_env)
    publish_hosts = exec_sql(publish_host_select)
    if len(publish_hosts) != 0:
        for publish_host_ip, publish_host_port, publish_user, deploy_dir, war_name, check_port in publish_hosts:
            publish_cmd = "sh /data/scripts/publish-war/deploy_war.sh %s %s %s %s %s %s %s" \
                    % (publish_host_ip, publish_host_port, publish_user, deploy_dir, war_name, war_version, check_port)
            print(publish_cmd)
            stat = os.system(publish_cmd)
            if stat != 0:
                print('发布失败')
                raise SystemExit(1)
    else:
        print('项目 %s 在环境 %s 未分配部署的服务器！' % (project_name, publish_env))
        raise SystemExit(1)

if __name__ == "__main__":
    publish_jar()
