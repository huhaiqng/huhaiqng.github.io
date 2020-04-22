#!/bin/bash
source ~/.bash_profile 
set -e
cd /data/backup/baipao-mysql-database/
fname=ebusbar_baipao.`date +%Y%m%d`.dump
mysqldump ebusbar_baipao \
--triggers \
--routines \
--events \
--set-gtid-purged=OFF \
--single-transaction \
--quick > $fname
rm -f `ls -t ebusbar_baipao.*.dump | tail -n +15`
