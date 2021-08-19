#!/bin/bash
set -e
TIME_TAG=`date +%Y%m%d%H%M%S`

function dumpdb() {
    # 创建备份目录
    [ ! -d $BACKUP_DIR ] && mkdir -pv $BACKUP_DIR
    cd $BACKUP_DIR
    # 获取需要备份的数据库名
    DBS=`mysql $SERVER_INFO -e 'show databases;'`
    # 不需要备份的数据库
    IGNORE_DBS="information_schema performance_schema sys Database"
    for DB in $DBS
    do
        IGNORE_STATUS="no"
        for IGNORE_DB in ${IGNORE_DBS}
        do
            if [ "${DB}" = "${IGNORE_DB}" ]; then
                IGNORE_STATUS="yes"
            fi
        done
        if [ "${IGNORE_STATUS}" = "no" ]; then
            # 创建备份目录
            DB_DIR="$BACKUP_DIR/$DB"
            [ ! -d $DB_DIR ] && mkdir -pv $DB_DIR
            cd $DB_DIR
            echo "$(date) 开始备份数据库: $DB"
            mysqldump $SERVER_INFO $DB --set-gtid-purged=OFF --triggers --routines --events --single-transaction --quick | gzip > $DB-${TIME_TAG}.gz
            # 删除过期备份
            rm -f `ls -t $DB-*.gz | tail -n +8`
			ls -lh
        else
            echo "不需要备份数据库: ${DB}"
        fi
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

echo -e "\n开始备份 192.168.40.79 的数据库"
BACKUP_DIR="/data/backup/mysql/192.168.40.79"
SERVER_INFO="-h 192.168.40.79 -P 3306 -u backup -pYuh04j!w"
dumpdb
