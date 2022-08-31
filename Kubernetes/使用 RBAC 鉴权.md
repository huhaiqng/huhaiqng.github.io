##### 服务账号 jim 在 dev 命名空间的权限设置

创建命名空间 dev

```
kubectl create namespace dev
```

创建服务账号 jim

```
kubectl create serviceaccount jim -n dev
```

创建 role.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: myrole
  namespace: dev
rules:
- apiGroups: ["apps",""]
  resources: ["deployments", "statefulsets", "services", "pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

创建 rolebinding.yaml，绑定自定义  myrole role

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myrolebinding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: myrole
subjects:
- kind: ServiceAccount
  name: jim
  namespace: dev
```

或创建 rolebinding.yaml，绑定  clusterrole admin

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myrolebinding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
  name: view
subjects:
- kind: ServiceAccount
  name: jim
  namespace: dev
```

或创建 rolebinding.yaml，绑定  clusterrole edit

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myrolebinding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- kind: ServiceAccount
  name: jim
  namespace: dev
```

或创建 rolebinding.yaml，绑定  clusterrole view

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myrolebinding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: jim
  namespace: dev
```

获取 jim 的密钥

```
kubectl get secret -n dev |grep jim
kubectl get secret jim-token-5gpl4 -n dev -oyaml |grep ca.crt:|awk '{print $2}' |base64 -d > ca.crt
```

配置集群

```
# 内网访问
kubectl config set-cluster default-cluster --server=https://192.168.40.191:6443 --certificate-authority=ca.crt --embed-certs=true --kubeconfig=config
# 外网访问
kubectl config set-cluster default-cluster --server=https://192.168.40.191:6443 --kubeconfig=config --insecure-skip-tls-verify=true
```

获取 jim 的 token

```
token=$(kubectl describe secret jim-token-5gpl4 -n dev | awk '/token:/{print $2}')
```

设置用户

```
kubectl config set-credentials admin --token=$token --kubeconfig=config
```

配置上下文 admin@dev

```
kubectl config set-context admin@dev --cluster=default-cluster --namespace=dev --user=admin --kubeconfig=config
```

设置当前上下文

```
kubectl config use-context admin@dev --kubeconfig=config
```

将文件 config 拷贝到用户目录下

```
cp -i config $HOME/.kube/config
```

验证

```
kubectl get pod -n dev
```



参考文档: https://support.huaweicloud.com/bestpractice-cce/cce_bestpractice_00221.html