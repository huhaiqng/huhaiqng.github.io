创建 chart

```
mkdir -pv /data/charts
cd /data/charts
helm create nginx
```

打包

```
cd /usr/share/nginx/html
helm package /data/charts/nginx
helm repo index . --url http://192.168.40.171:90
```

添加仓库

```
helm repo add myrepo http://192.168.40.171:90
```

查询 chart

```
helm search repo
```

安装

```
helm install nginx1 myrepo/nginx
```

更新

```
helm upgrade nginx1 myrepo/nginx
```

下载

```
helm pull myrepo/nginx
```

查看

> -n 可指定命令空间

```
helm list
```

