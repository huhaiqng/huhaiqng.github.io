安装 nfs

```
yum install -y nfs-utils
```

修改 /etc/exports  文件添加共享目录

```
/nfsdisk        192.168.1.0/24(rw,sync,no_root_squash)
```

启动 nfs

```
systemctl start nfs
```

客户端挂载 nfs 目录

> 注意：如果不加vers=3选项，则客户端root用户修改所属属性时报错
>
> chown: changing ownership of `/zabbixdb/was': Invalid argument

```
mount -o vers=3 192.168.1.10:/nfsdisk /nfsdisk
```

不重启加载

```
exportfs -arv
```

