##### 说明

> kube-prometheus: https://github.com/prometheus-operator/kube-prometheus.git

在基础上做了修改:

- 添加了 dingding 报警
- 添加了 prometheus 访问地址 http://192.168.40.191:30100/
- 添加了 grafana 访问地址 http://192.168.40.191:30200/
- 添加了 alertmanager 访问地址 http://192.168.40.191:30300/

##### alertmanager 配置文件 alertmanager-secret.yaml 中添加钉钉 webbook

 ```
"receivers":
    - "name": "Default"
      webhook_configs:
      - url: http://dingding:8060/dingtalk/webhook1/send
 ```

##### 部署 kube-prometheus

```
kubectl create namespace devops
kubectl create -f ./setup
kubectl apply -f ./prometheus
kubectl apply -f ./prometheus-adapter
kubectl apply -f ./prometheus-operator
kubectl apply -f ./node-exporter
kubectl apply -f ./kube-statemetrics
kubectl apply -f ./kubernetes-controlplane
kubectl apply -f ./grafana
kubectl apply -f ./blackbox-exporter
kubectl apply -f ./alertmanager
```

##### 部署钉钉

项目地址: https://github.com/yunlzheng/alertmanaer-dingtalk-webhook

创建 configmap

> 配置文件: config.yml 模板文件: default.tmpl
>
> 需要修个钉钉 webhook

```
kubectl create configmap dingding-config -n monitoring --from-file=config.yml --from-file=default.tmpl
```

部署

```
kubectl apply -f deployment.yaml -f service.yaml
```

##### prometheus 数据持久化目录

```
mkdir -pv /data/prometheus-db/
chown 1000.1000 /data/prometheus-db/
```

##### grafana 数据持久化目录

```
mkdir /data/grafana
chown -R 65534.65534 /data/grafana
```