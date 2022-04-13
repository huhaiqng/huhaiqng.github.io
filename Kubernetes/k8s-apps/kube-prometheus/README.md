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

##### 部署

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
kubectl apply -f ./dingding
```

##### prometheus 数据持久化目录

```
mkdir -pv /data/prometheus-db/
chown 1000.1000 /data/prometheus-db/
```

