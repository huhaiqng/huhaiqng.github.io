#!/bin/bash
log_d=`date +%Y-%m-%d -d "-1day"`
for d in `ls /usr/local/baipao`
do
    cd /usr/local/baipao/$d/applog
    [[ -d $log_d ]] && tar zcvf ${log_d}.tar.gz $log_d --remove-files
    rm -f `ls -t *.tar.gz | tail -n +15`
    pwd
    ls -l
done

abclog_f=`date +%Y%m%d -d "-1day"`
if [ -d /usr/local/baipao/contract/abclog ];then
    cd /usr/local/baipao/contract/abclog
    [[ -f TrxLog.${abclog_f}.log ]] && tar zcvf TrxLog.${abclog_f}.log.tar.gz TrxLog.${abclog_f}.log --remove-files
    rm -f `ls -t *.tar.gz | tail -n +15`
fi
