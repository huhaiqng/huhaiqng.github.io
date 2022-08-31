#!/bin/bash
TOP15_PROC="/tmp/proc"
TOP15_THRD="/tmp/thrd"

top -d 5 -n 1 -b | grep java | grep www | grep -v grep | head -n 15 >${TOP15_PROC}

cat ${TOP15_PROC} | while read PROC
do
    PROC_ID=`echo $PROC | awk '{print $1}'`
    PROC_CPU=`echo $PROC | awk '{print $9}'`
    if [ `echo "$PROC_CPU > 50.0" | bc` -eq 1 ]; then
        echo -e "\n\n\n`date`"
        echo -e "\n进程 ${PROC_ID} 的 CPU 使用率为 ${PROC_CPU}%"
        ps -ef | grep ${PROC_ID} | grep -v grep

        top -d 5 -n 1 -b -Hp ${PROC_ID} | grep java | grep www | grep -v grep | head -n 15 >${TOP15_THRD}

        cat ${TOP15_THRD} | while read THRD
        do
            THRD_ID=`echo $THRD | awk '{print $1}'`
            THRD_CPU=`echo $THRD | awk '{print $9}'`
            if [ `echo "$THRD_CPU > 20.0" | bc` -eq 1 ]; then
                OX_TID=`printf "%x\n" ${THRD_ID}`
                echo -e "\n进程 ${PROC_ID} 的线程 ${THRD_ID}($OX_TID) 的 CPU 使用率为 ${THRD_CPU}%"
                /usr/local/jdk1.7.0_79/bin/jstack ${PROC_ID} | sed "/0x${OX_TID}/, /^$/!d"
            fi
        done
    fi
done
