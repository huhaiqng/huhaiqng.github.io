**注意: Deployment 没有此特征**

nginx.yaml 文件

```
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  # clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 6
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.19.1 
        ports:
        - containerPort: 80
          name: web

```

查看镜像版本

```
# for p in 0 1 2 3 4 5; do kubectl get pod "web-$p" --template 'web-$p {{range $i, $c := .spec.containers}}{{$c.image}}{{end}}'; echo; done 
web-$p nginx:1.19.1
web-$p nginx:1.19.1
web-$p nginx:1.19.1
web-$p nginx:1.19.1
web-$p nginx:1.19.1
web-$p nginx:1.19.1
```

部署

```
kubectl apply -f nginx.yaml
```

配置 Pod 序号大于等于 4 的升级

```
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":4}}}}'
```

执行升级

```
kubectl patch statefulset web --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"nginx:1.20.1"}]'
```

查看镜像版本

```
# for p in 0 1 2 3 4 5; do kubectl get pod "web-$p" --template '{{range $i, $c := .spec.containers}}{{$c.image}}{{end}}'; echo; done
nginx:1.19.1
nginx:1.19.1
nginx:1.19.1
nginx:1.19.1
nginx:1.20.1
nginx:1.20.1
```

完成全部升级

```
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":0}}}}'
```

