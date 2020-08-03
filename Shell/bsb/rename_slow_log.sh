#!/bin/bash
set -e
cp /var/lib/mysql/slow.log /data/slowlog/slow.log.`date +%Y-%m-%d`
cat /dev/null > /var/lib/mysql/slow.log
