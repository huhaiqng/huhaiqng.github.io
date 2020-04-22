#!/bin/bash
source ~/.bash_profile 
set -e
cd /data/backup/kuaidianyun/mysql/
fname=ebusbar_boss_db.`date +%Y%m%d`.dump
mysqldump ebusbar_boss_db \
--triggers \
--routines \
--events \
--set-gtid-purged=OFF \
--single-transaction \
--quick > $fname
rm -f `ls -t ebusbar_boss_db.*.dump | tail -n +8`
