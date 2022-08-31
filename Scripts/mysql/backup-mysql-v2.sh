#!/bin/bash
set -e
TIME_TAG=`date +%Y%m%d%H%M%S`
MYSQL_NAME=$1
DB_NAME=$2

function dumpdb() {
    # 创建备份目录
    [ ! -d $BACKUP_DIR ] && mkdir -pv $BACKUP_DIR
    cd $BACKUP_DIR
    # 获取需要备份的数据库名
    if [ "${DB_NAME}" = "all" ]; then
        DBS=`mysql $SERVER_INFO -e 'show databases;'`
    else
        DBS=${DB_NAME}
    fi
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
            rm -f `ls -t $DB-*.gz | tail -n +30`
            ls -lh
        else
            echo "不需要备份数据库: ${DB}"
        fi
    done
}

function bkchandao() {
    echo -e "\n开始备份 chandao 的数据库"
    BACKUP_DIR="/data/backup/mysql/chandao"
    SERVER_INFO="-h 192.168.40.159 -P 3306 -u backup -pWguJX78n"
    dumpdb
}

function bkjenkins() {
    echo -e "\n开始备份 jenkins 的数据库"
    BACKUP_DIR="/data/backup/mysql/jenkins"
    SERVER_INFO="-h 192.168.40.185 -P 3306 -u backup -pYuh04j!w"
    dumpdb
}

function bkjpark() {
    echo -e "\n开始备份 jpark 的数据库"
    BACKUP_DIR="/data/backup/mysql/jpark"
    SERVER_INFO="-h 192.168.40.79 -P 3306 -u backup -pYuh04j!w"
    dumpdb
}

if [ $# -ne 2 ]; then
    echo "脚本执行方式: sh $0 all|chandao|jenkins|jpark all|DB_NAME"    
    exit  
fi

case ${MYSQL_NAME} in
    "chandao")
        bkchandao ;;
    "jenkins")
        bkjenkins ;;
    "jpark")
        bkjpark ;;
    "all")
        bkchandao
        bkjenkins
        bkjpark ;;
    *)
        echo "${MYSQL_NAME} 不存在" ;;
esac
