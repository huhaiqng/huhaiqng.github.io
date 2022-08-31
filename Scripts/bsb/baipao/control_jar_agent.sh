#!/bin/bash
source ~/.bash_profile 

if [ $# -ne 3 ];then
    echo "参数错误！"
    echo "正确的格式：sh deploy_jar_agent.sh start|stop|restart ***.jar jar_dir"
    exit
fi


function jar_start(){
    f_jar=$1
    f_dir=$2
    if ps -ef | grep java | grep -v grep | grep $f_jar ;then
        echo "包 $f_jar 已经在运行！"
        exit
    else
        cd $f_dir
        nohup java -Xms512m -Xmx1536m -jar $f_jar > /dev/null 2>&1 &
        if ps -ef | grep java | grep $f_jar | grep -v grep ;then
            i=`ps -ef | grep java | grep $f_jar | grep -v grep | awk '{print $2}'`
            while ! netstat -nltp | grep java | grep $i
            do
                echo "$f_jar 正在启动......"
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


a_cmd=$1
a_jar=$2
jar_dir=$3

case $a_cmd in
    start)
        jar_start $a_jar $jar_dir
    ;;
    stop)
        jar_stop $a_jar
    ;;
    restart)
        jar_stop $a_jar
        jar_start $a_jar $jar_dir
    ;;
    *)
        echo "参数错误！"
        echo "正确的格式：sh deploy_jar_agent.sh start|stop|restart ***.jar jar_dir"
    ;;
esac
