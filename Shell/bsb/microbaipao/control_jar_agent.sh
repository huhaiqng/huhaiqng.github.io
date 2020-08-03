#!/bin/bash
# set -e
source ~/.bash_profile 

pkg_dir=/usr/local/baipao/$2
pkg_name=baipao-$2.jar

cd $pkg_dir
if [ ! -f $pkg_name ]; then
    echo "输入错误，包 $pkg_name 不存在！"
    exit
fi

if [ $# -ne 2 ];then
    echo "参数错误！"
    echo "正确的格式：sh control_jar_agent.sh start|stop|restart app"
    exit
fi


function jar_start(){
    f_jar=$1
    if ps -ef | grep java | grep -v grep | grep $f_jar ;then
        echo "包 $f_jar 已经在运行！"
        exit
    else
#        nohup java -Xms512m -Xmx1024m -Dspring.profiles.active=prod -jar $f_jar > /dev/null 2>&1 &
#        sleep 3s

        case $1 in
            contract)
                nohup java -Xms512M -Xmx2048M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
            ;;
            manager)
                nohup java -Xms512M -Xmx2048M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
            ;;
            *)
                nohup java -Xms512M -Xmx1536M -Dspring.profiles.active=prod -jar $pkg_name >/dev/null 2>&1 &
            ;;
        esac

        sleep 3s

        if ps -ef | grep java | grep $f_jar | grep -v grep ;then
            i=`ps -ef | grep java | grep $f_jar | grep -v grep | awk '{print $2}'`
            while ! sudo netstat -nltp | grep java | grep $i
            do
                # echo "$f_jar 正在启动......"
                sleep 10s
            done
            echo "$f_jar 启动成功！"
        else
            echo "$f_jar 启动失败!"
        fi
    fi
}

function jar_stop(){
    f_jar=$1
    if ! ps -ef | grep java | grep -v grep | grep $f_jar ;then
        echo "包 $f_jar 没有在运行！"
    else
        # 删除临时目录
        psid=`ps -ef | grep java | grep $f_jar | grep -v grep | awk '{print $2}'`
        port=`netstat -ntlp | grep java | grep $psid | awk '{print $4}' | awk -F ':' '{print $NF}'`
        tar zcf /tmp/tomcat-tmp-$port.tar.gz /tmp/tomcat*.$port/ --remove-files
        # kill 进程
        kill -9 `ps -ef | grep java | grep $f_jar | grep -v grep | awk '{print $2}'`
        if ! ps -ef | grep java | grep -v grep | grep $f_jar ;then
            echo "包 $f_jar 停止成功！"
        fi
    fi
}

case $1 in
    start)
        jar_start $pkg_name
    ;;
    stop)
        jar_stop $pkg_name
    ;;
    restart)
        jar_stop $pkg_name
        sleep 10s
        jar_start $pkg_name
    ;;
    *)
        echo "参数错误！"
        echo "正确的格式：sh control_jar_agent.sh start|stop|restart app"
    ;;
esac
