#### 在 CentOS 7 上部署 Kubernetes 集群 

##### 1、服务器说明和配置

> master: 188.188.1.151
>
> worker1: 188.188.1.152
>
> worker2: 188.188.1.153

在 hosts 文件中添加主机名解析

```
188.188.1.151	centos76-001
188.188.1.152	centos76-002
188.188.1.153	centos76-003
```

##### 2、在 master 和 worker 上安装 docker

```
# Install Docker CE
## Set up the repository
### Install required packages.
yum install yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update && yum install docker-ce-18.06.2.ce

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
```

##### 3、在 master 和 worker 上安装 kubernetes

```
# cat /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

# yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# systemctl enable kubelet
# systemctl start kubelet
```

##### 4、在 master 和 worker 上使用以下脚本 pull.sh 下载镜像

```
#!/bin/bash
for i in `kubeadm config images list`; do 
  imageName=${i#k8s.gcr.io/}
  docker pull registry.aliyuncs.com/google_containers/$imageName
  docker tag registry.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
  docker rmi registry.aliyuncs.com/google_containers/$imageName
done
```

##### 5、在 master 上执行初始化

> --pod-network-cidr=10.244.0.0/16 参数指定是 **flannel** 网络的网段，用于 pods 直接的通信

```
kubeadm init --pod-network-cidr=10.244.0.0/16
```

##### 6、在 master 上安装 flannel 网络

```
wget https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
kubectl apply -f kube-flannel.yml
kubectl get pods --all-namespaces # 如果 CoreDNS pod 是 up 和 running的，则安装成功
```

如果出现以下错误，则说明镜像下载失败，手动下载镜像看看是否能成功

![1566963643508](assets/1566963643508.png)

##### 7、将 woker 添加到集群中

```
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

##### 8、在 master 上查看节点

```
[root@centos76-001 ~]# kubectl get pods --all-namespaces 
NAMESPACE     NAME                                   READY   STATUS    RESTARTS   AGE
kube-system   coredns-5c98db65d4-7msm2               1/1     Running   0          51m
kube-system   coredns-5c98db65d4-qlpk9               1/1     Running   0          51m
kube-system   etcd-centos76-001                      1/1     Running   0          50m
kube-system   kube-apiserver-centos76-001            1/1     Running   0          50m
kube-system   kube-controller-manager-centos76-001   1/1     Running   0          50m
kube-system   kube-flannel-ds-amd64-bmhvr            1/1     Running   0          42m
kube-system   kube-flannel-ds-amd64-lm7hq            1/1     Running   0          73s
kube-system   kube-flannel-ds-amd64-wkwgs            1/1     Running   0          42m
kube-system   kube-proxy-8qw9v                       1/1     Running   0          47m
kube-system   kube-proxy-c79fz                       1/1     Running   0          51m
kube-system   kube-proxy-jjrtx                       1/1     Running   0          73s
kube-system   kube-scheduler-centos76-001            1/1     Running   0          50m
[root@centos76-001 ~]# kubectl get nodes
NAME           STATUS   ROLES    AGE   VERSION
centos76-001   Ready    master   52m   v1.15.3
centos76-002   Ready    <none>   47m   v1.15.3
centos76-003   Ready    <none>   80s   v1.15.3
```



#### 部署应用程序

##### 部署使用服务访问的应用程序

>**目标** 
>
>- 运行Hello World应用程序的两个实例。
>- 创建一个公开节点端口的Service对象。
>- 使用Service对象访问正在运行的应用程序。

1、创建文件 hello-application.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  selector:
    matchLabels:
      run: load-balancer-example
  replicas: 2
  template:
    metadata:
      labels:
        run: load-balancer-example
    spec:
      containers:
        - name: hello-world
          image: nginx
          ports:
            - containerPort: 80
              protocol: TCP
```

2、部署应用程序

```
kubectl apply -f hello-application.yaml 
```

3、显示部署信息

```
kubectl get deployments hello-world
kubectl describe deployments hello-world
```

4、显示 ReplicaSet 信息

```
kubectl get replicasets
kubectl describe replicasets
```

5、创建公开部署的Service对象

```
kubectl expose deployment hello-world --type=NodePort --name=example-service
```

6、显示服务信息

```
# kubectl describe services example-service
Name:                     example-service
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 run=load-balancer-example
Type:                     NodePort
IP:                       10.99.118.198
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31826/TCP
Endpoints:                10.244.1.10:80,10.244.5.11:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

7、显示 pods 信息

```
kubectl get pods --selector="run=load-balancer-example" --output=wide
```

![1566988952720](assets/1566988952720.png)

8、通过 node ip 访问集群

```
# curl -I http://188.188.1.152:31826
HTTP/1.1 200 OK
Server: nginx/1.17.3
Date: Wed, 28 Aug 2019 10:43:48 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Aug 2019 08:50:00 GMT
Connection: keep-alive
ETag: "5d5279b8-264"
Accept-Ranges: bytes
```

##### 部署指定节点和 NodePort 的应用

> nodeName 指定节点，nodePort 指定节点端口，type 指定服务类型，默认为 ClusterIP

创建部署 yaml 文件 redis-master-deployment.yaml 

```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: redis-master
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      nodeName: centos76-003
      containers:
      - name: master
        image: redis  # or just image: redis
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

创建服务 yaml 文件 redis-master-service.yaml 

```
apiVersion: v1
kind: Service
metadata:
  name: redis-master
  labels:
    app: redis
    role: master
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
    nodePort: 30001
  selector:
    app: redis
    role: master
    tier: backend
  type: NodePort
```

应用 yaml 文件

```
kubectl apply -f redis-master-deployment.yaml
kubectl apply -f redis-master-service.yaml 
```

查看 pod 信息

```
kubectl get pods --output=wide
```

![1567138061315](assets/1567138061315.png)

查看服务信息

```
# kubectl get service redis-master
NAME           TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
redis-master   NodePort   10.102.248.122   <none>        6379:30001/TCP   18m
```

测试登陆 redis

```
# redis-cli -h centos76-003 -p 30001
centos76-003:30001> set k 123456
OK
centos76-003:30001> get k
"123456"
```



#### 资料

**Kubernet**

- [Kubernetes中文指南/云原生应用架构实践手册](<https://jimmysong.io/kubernetes-handbook/>)

**Docker**

- [Docker Handbook](<https://jimmysong.io/docker-handbook/>)



#### 常用命令

通过 pod 登陆容器

```
# kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
mysql-7d7fdd478f-vvtfw              1/1     Running   0          5h18m
nginx-deployment-6f655f5d99-2twx8   1/1     Running   0          5h32m
nginx-deployment-6f655f5d99-rgmvs   1/1     Running   0          5h32m
# kubectl exec -it mysql-7d7fdd478f-vvtfw -- /bin/bash
root@mysql-7d7fdd478f-vvtfw:/# 
```

查看 pod 日志

```
kubectl logs podname
```

