统计文件中行数相同的数量

```shell
sort app.log | uniq -c | sort -r -n 
```

查看当前系统 80 端口 tcp 连接数

```shell
netstat -nt | awk '{print $4}' | sort | uniq -c | awk '{if($2=="172.16.1.52:80") print $1}'
```

同步远程文件

```shell
rsync -auvrtzopgP --progress -e "ssh -p 2222" devuser@218.17.56.50:/mntdisk/baipao/template/ /data/baipao/template/
```

查看占用 CPU 前10的进程

```shell
ps aux --sort=-pcpu | head -10
```

批量查看进程及对应的端口号

```shell
#!/bin/bash

P_IDS=`netstat -ntlp | grep tcp | awk '{print $7}' | awk -F '/' '{print $1}' | grep -v '-' | sort | uniq`

for P_ID in ${P_IDS}
do
    echo -e '\n'
    ps -ef | grep "${P_ID}" | grep -v grep
    netstat -nltp | grep "${P_ID}" | grep -v grep
done
```

