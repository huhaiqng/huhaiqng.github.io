

在 /etc/kubernetes/manifests/kube-apiserver.yaml 文件中添加

```
spec:
  containers:
  - command:
    ...
    - --feature-gates=RemoveSelfLink=false
```

创建存储类

> deployment 中的 namespace 需要与 rbac 中的一致

```
kubectl create namespace prod
kubectl apply -f class.yaml
kubectl apply -f deployment.yaml
kubectl apply -f rbac.yaml
```

创建 pvc 测试

```
kubectl apply -f test-claim.yaml
kubectl get pv -n prod 
kubectl get pv -n prod
```

创建 statefulset，动态绑定 pvc

```
kubectl apply -f test-statefulset.yaml
```

参考文档：

https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/tree/master/deploy

[Kubernetes 创建 pvc error getting claim reference: selfLink was empty, can‘t make refere](https://blog.csdn.net/weixin_41806245/article/details/114368843)