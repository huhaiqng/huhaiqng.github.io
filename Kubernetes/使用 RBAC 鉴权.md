##### 创建服务账号 tom 对 dev 命名空间有读写权限

创建命名空间 dev

```
kubectl create namespace dev
```

创建服务账号 jim

```
kubectl create serviceaccount tom -n dev
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
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - pods
  - deployments
  verbs:
  - get
  - list
  - watch
  - create
```

创建 rolebinding.yaml

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

获取 jim 的密钥

```
kubectl get secret -n dev |grep jim
kubectl get secret jim-token-5gpl4 -n dev -oyaml |grep ca.crt:|awk '{print $2}' |base64 -d > ca.crt
```

配置集群

```
# 内网访问
kubectl config set-cluster default-cluster --server=https:https://192.168.40.191:6443 --certificate-authority=ca.crt --embed-certs=true --kubeconfig=config
# 外网访问
kubectl config set-cluster default-cluster --server=https:https://192.168.40.191:6443 --kubeconfig=config --insecure-skip-tls-verify=true
```

获取 jim 的 token

```
token=$(kubectl describe secret jim-token-5gpl4 -n dev | awk '/token:/{print $2}')
```

配置上下文 admin@dev

```
kubectl config set-context admin@dev --cluster=default-cluster --namespace=dev --user=admin --kubeconfig=config
```

设置当前上下文

```
kubectl config use-context admin@dev --kubeconfig=config
```

验证

```
# 非 root 用户
cp -i config $HOME/.kube/config
kubectl get pod -n dev
```



参考文档: https://support.huaweicloud.com/bestpractice-cce/cce_bestpractice_00221.html