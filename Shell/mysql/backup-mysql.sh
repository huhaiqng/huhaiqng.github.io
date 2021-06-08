#!/bin/bash
set -e
TIME_TAG=`date +%s`

function dumpdb() {
    # 创建备份目录
    [ ! -d $BACKUP_DIR ] && mkdir -pv $BACKUP_DIR
    cd $BACKUP_DIR
    # 获取需要备份的数据库名
    DBS=`mysql $SERVER_INFO -e 'show databases;' | grep -Ev 'information_schema|performance_schema|sys|Database'`
    echo -e "需要备份的数据库:\n$DBS"
    # 备份数据库
    for DB in $DBS
    do
        # 创建备份目录
        DB_DIR="$BACKUP_DIR/$DB"
        [ ! -d $DB_DIR ] && mkdir -pv $DB_DIR
        cd $DB_DIR 

        echo "开始备份数据库: $DB"
        mysqldump $SERVER_INFO $DB --triggers --routines --events --single-transaction --quick | gzip > $DB-${TIME_TAG}.gz
        # 删除过期备份
        rm -f `ls -t $DB-*.gz | tail -n +8`
    done
}

echo -e "\n开始备份 192.168.40.159 的数据库"
BACKUP_DIR="/data/backup/mysql/192.168.40.159"
SERVER_INFO="-h 192.168.40.159 -P 3306 -u backup -pWguJX78n"
dumpdb

echo -e "\n开始备份 192.168.40.185 的数据库"
BACKUP_DIR="/data/backup/mysql/192.168.40.185"
SERVER_INFO="-h 192.168.40.185 -P 3306 -u backup -pYuh04j!w"
dumpdb
