#!/bin/bash
if [ $# -ne 2 ] ;then
    echo "输入错误！输入格式：sh mysql.sh start|stop|restart 3306|3307|3308"
fi
mysql_port=$2
cd /usr/local/mysql
function start_mysql() {
    echo "bin/mysqld_safe --defaults-file=conf/my$1.cnf --user=mysql"
    bin/mysqld_safe --defaults-file=conf/my$1.cnf --user=mysql &
    while ! netstat -ntlp | grep $1
    do
        echo "$1 正在启动..."
        sleep 10s
    done
}

function stop_mysql() {
    if ! netstat -ntlp | grep $1 >/dev/null 2>&1 ;then
        echo "$1 没有启动！"
        exit
    fi
    bin/mysqladmin -S /tmp/my$1.sock shutdown
}

case $1 in
    start)
        start_mysql $mysql_port
    ;;
    stop)
        stop_mysql $mysql_port
    ;;
    restart)
        stop_mysql $mysql_port
        start_mysql $mysql_port
    ;;
    *)
        echo "输入错误！输入格式：sh mysql.sh start|stop|restart 3306|3307|3308"
    ;;
esac
