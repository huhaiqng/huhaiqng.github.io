#!/bin/bash
set -e
cmdtype=$1
username=$2
jarname=$3
jardir=$4
port=$5

if [ "$username" != "tomcat" ];then
    echo "请使用 tomcat 用户执行!"
    exit
fi

if [ -d $jardir ];then
    cd $jardir
else
    echo "$jardir 上没有部署 $jarname！"
    exit
fi

case $cmdtype in
    "check")
        if netstat -ntlp | grep $port ;then
            ps -ef | grep "java -jar $jarname" | grep -v grep
            echo "$jarname 正在运行！"
        else
            echo "$jarname 没有运行！"
        fi
     ;;
     "start")
        if netstat -ntlp | grep $port ;then
            ps -ef | grep "java -jar $jarname" | grep -v grep
            echo "$jarname 已经在运行！"
        else
            nohup java -jar $jarname >/dev/null 2>&1 &
            sleep 5s
            while ! netstat -ntlp | grep $port 
            do
                echo "$jarname 正在启动......"
                sleep 5s
                if ! ps -ef | grep "java -jar $jarname" | grep -v grep ;then
                    echo "$jarname 启动失败！"
                    break
                fi
            done
            echo "$jarname 启动成功！"
        fi
    ;;
    "restart")
        if netstat -ntlp | grep $port ; then
            jarpid=`ps -ef | grep "java -jar $jarname" | grep -v grep | awk '{print $2}'`
            kill -9 $jarpid
            sleep 5s
            if netstat -ntlp | grep $port ;then
                echo "停止 $jarname 失败！"
                exit
            else
                echo "停止 $jarname 成功！"
            fi
        else
            echo "$jarname 没有运行！"
        fi
        nohup java -jar $jarname >/dev/null 2>&1 &
        sleep 5s
        while ! netstat -ntlp | grep $port 
        do
            echo "$jarname 正在启动......"
            sleep 5s
            if ! ps -ef | grep "java -jar $jarname" | grep -v grep ;then
                echo "$jarname 启动失败！"
                break
            fi
        done
        echo "$jarname 重启成功！"
    ;;
    "stop")
       if netstat -ntlp | grep $port ;then
           jarpid=`ps -ef | grep "java -jar $jarname" | grep -v grep | awk '{print $2}'`
           kill -9 $jarpid
           sleep 5s
           if netstat -ntlp | grep $port ;then
               echo "停止 $jarname 失败！"
           else
               echo "停止 $jarname 成功！"
           fi
       else
           echo "$jarname 没有运行！"
       fi
   ;;
   *)
       echo "操作不存在！"
   ;;
esac
