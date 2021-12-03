#### 服务器准备

系统配置

| 主机名 | IP 地址        | 系统版本 |
| ------ | -------------- | -------- |
| master | 192.168.40.191 | CentOS-7 |
| node01 | 192.168.40.192 | CentOS-7 |
| node02 | 192.168.40.195 | CentOS-7 |

修改`/etc/hosts`, 设置主机名解析

```
192.168.40.191  master
192.168.40.192  node01
192.168.40.195  node02
```

安装工具包

```
yum install -y vim etcd lrzsz ntp
```

同步时间

```
ntpdate ntp1.aliyun.com
```

关闭 firewall 和 selinux

```
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
```



#### 安装 docker

```
# 配置yum
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装
yum install -y docker-ce docker-ce-cli containerd.io

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
systemctl start docker
systemctl enable docker
```



#### 部署 k8s

##### 准备翻墙环境

在本地 windows 电脑上开启 v2rayN 允许局域网的连接

![image-20211122143859045](在 k8s 上部署 doplat 项目.assets/image-20211122143859045.png)

设置 yum 代理

```
export http_proxy=socks5://192.168.40.200:10808
export https_proxy=socks5://192.168.40.200:10808
export no_proxy=localhost,127.0.0.1,192.168.40.200
```

修改文件 /usr/lib/systemd/system/docker.service, 添加 Environment, 设置 docker pull 代理

```
[Service]
Environment="http_proxy=socks5://192.168.40.200:10808" "https_proxy=socks5://192.168.40.200:10808" "NO_PROXY=localhost,127.0.0.1,192.168.40.200"
```

重启 docker

```
systemctl daemon-reload
systemctl restart docker
```

快速切换脚本 change-docker-service.sh

```
#!/bin/bash
grep Environment /usr/lib/systemd/system/docker.service
if grep "^#Environment" /usr/lib/systemd/system/docker.service ;then
    sed -i 's/\#Environment/Environment/g' /usr/lib/systemd/system/docker.service
elif grep "^Environment" /usr/lib/systemd/system/docker.service ;then
    sed -i 's/Environment/\#Environment/g' /usr/lib/systemd/system/docker.service
fi
grep Environment /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
```

##### 安装 kubeadm、kubelet 和 kubectl

> worker 不需要安装 kubectl

```
# 配置yum，完成安装后删除
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# 安装
update-alternatives --set iptables /usr/sbin/iptables-legacy
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
mv /etc/yum.repos.d/kubernetes.repo /tmp
```

##### 创建集群

修改 /etc/sysctl.d/99-sysctl.conf, 添加一下内容，并命令 sysctl -p 加载

```
net.bridge.bridge-nf-call-iptables = 1
```

关闭 swap，需要重启服务器

```
[root@centos7-002 ~]# cat /etc/fstab 
...
# /dev/mapper/centos-swap swap                    swap    defaults        0 0
```

查看集群需要的镜像

```
kubeadm config images list
```

拉取集群需要的镜像

```
kubeadm config images pull
```

初始化 master

> --kubernetes-version=v1.22.4 指定安装版本

```
kubeadm init --pod-network-cidr=10.244.0.0/16
```

要使非 root 用户可以运行 kubectl，请运行以下命令， 它们也是 `kubeadm init` 输出的一部分：

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

或者，如果你是 `root` 用户，则可以运行：

> 添加到 .bash_profile 文件中

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```

配置网络

> 使用的镜像 quay.io/coreos/flannel:v0.12.0-amd64，为了加快速度可以提前准备

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

测试运行是否正常

> coredns,flannel 都为 running，则正常

```
[root@centos7-001 ~]# kubectl get pods -n kube-system
NAME                                  READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-9bjc6              1/1     Running   0          157m
coredns-66bff467f8-wbfpl              1/1     Running   0          157m
etcd-centos7-001                      1/1     Running   0          157m
kube-apiserver-centos7-001            1/1     Running   0          157m
kube-controller-manager-centos7-001   1/1     Running   0          157m
kube-flannel-ds-amd64-577mh           1/1     Running   0          151m
kube-flannel-ds-amd64-zdv87           1/1     Running   0          92m
kube-proxy-g2592                      1/1     Running   0          92m
kube-proxy-q8hzw                      1/1     Running   0          157m
kube-scheduler-centos7-001            1/1     Running   0          157m
```

节点加入

```
# 显示加入节点命令(在 master 执行)
kubeadm token create --print-join-command
# 加入节点(在 node 执行)
kubeadm join 192.168.40.201:6443 --token qqe25f.8l45ojbosy9hxpkc     --discovery-token-ca-cert-hash sha256:84a8f25f211461cfe9c33243445e1d31d0cb81944728c44804d806a022cc01fe
```

查看节点

```
[root@centos7-001 ~]# kubectl get nodes
NAME          STATUS   ROLES    AGE   VERSION
centos7-001   Ready    master   43h   v1.18.5
centos7-002   Ready    <none>   42h   v1.18.5
centos7-003   Ready    <none>   85m   v1.18.6
```

##### 部署 Dashboard UI

下载 yaml 文件

```
https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

添加参数 --token-ttl=86400 , 延长会话超时时间

![image-20211122145819329](在 k8s 上部署 doplat 项目.assets/image-20211122145819329.png)

修改 imagePullPolicy: IfNotPresent， 以免每次重新拉取镜像

![image-20211122150030156](在 k8s 上部署 doplat 项目.assets/image-20211122150030156.png)

修改 kubernetes-dashboard services，设置 type 和 nodePort

```
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30443
```

应用

```
kubectl apply -f recommended.yaml
```

查看服务 `kubectl get service -n kubernetes-dashboard`

> 访问地址为: https://masterip:30655

![image-20211122151312396](在 k8s 上部署 doplat 项目.assets/image-20211122151312396.png)

创建访问服务账号

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```

绑定角色

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

查看 token

```
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```

##### 部署 Metrics Server

下载 yaml 文件

```
https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

修改 deployment args 添加 `--kubelet-insecure-tls`

![image-20211122152002930](在 k8s 上部署 doplat 项目.assets/image-20211122152002930.png)

修改 `imagePullPolicy: IfNotPresent`， 以免每次重新拉取镜像



应用

```
kubectl apply -f components.yaml
```

等待1分钟左右，检测

```
[root@centos7-001 ~]# kubectl top nodes
NAME          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
centos7-001   150m         7%     1539Mi          41%       
centos7-002   28m          2%     504Mi           57%       
centos7-003   24m          2%     496Mi           56% 
```

##### 部署 NGINX Ingress Controller

在部署的节点上打上标签

```
kubectl label nodes <your-node-name> ingress=ingress-nginx
```

下载 yaml 文件

```
https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/baremetal/deploy.yaml
```

修改 ingress-nginx-controller deployment, 添加 selector

```
spec:
  nodeSelector:
    ingress: ingress-nginx
```

修改 ingress-nginx-controller service, 添加`externalTrafficPolicy: Local`, 方便后端获取真实 IP

![image-20211122153821035](在 k8s 上部署 doplat 项目.assets/image-20211122153821035.png)

修改 ingress-nginx-controller service, 设置 nodePort

> 设置固定的 nodeport，方便 nginx 反向代理

```
  ports:
    - name: http
      ...
      nodePort: 31080
    - name: https
      ...
      nodePort: 31443
```

修改 ingress-nginx-controller ConfigMap，实现获取 real ip

> 因为使用了 nginx 做反向代理，需要添加配置才能获取真实 IP

```
data:
  allow-snippet-annotations: 'true'
  proxy-real-ip-cidr: '192.168.40.0/24'
  use-forwarded-headers: "true"
```

应用

```
kubectl apply -f deploy.yaml
```

查看服务 `kubectl get service -n ingress-nginx`

![image-20211122155916978](在 k8s 上部署 doplat 项目.assets/image-20211122155916978.png)

##### 部署 Nginx 反向代理 NGINX Ingress Controller

> 如果使用阿里云负载均衡访问服务，则不需要部署 nginx，可以将负载均衡的80端口号映射到 NGINX Ingress Controller 的 NodePort。
>
> 如果使用 NAT 或主机公网 IP 访问服务，则需要 Nginx 做反向代理。

配置 nginx yum 源

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgkey=http://nginx.org/keys/nginx_signing.key
gpgcheck=0
enabled=1
```

安装

```
yum install -y nginx
```

nignx 反向代理配置

```
upstream nginxingresscontroller {
    server nginx_ingress_controller_ip:http_nodeport;
    ...
}

server {
	listen       80;
    server_name  _;
	
    location / {
        proxy_pass http://nginxingresscontroller;
        proxy_redirect     off;
        proxy_set_header   Host             $http_host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_connect_timeout      120;
        proxy_send_timeout         120;
        proxy_read_timeout         120;
    }
}
```

##### 测试实例 hello (nginx + ingress nginx)

yaml 文件

```
apiVersion: v1
kind: Namespace
metadata:
  name: hello

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: hello
spec:
  selector:
    matchLabels:
      app: hello
  replicas: 3
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
        - name: hello
          image: "gcr.io/google-samples/hello-go-gke:1.0"
          ports:
            - name: http
              containerPort: 80

---

apiVersion: v1
kind: Service
metadata:
  name: hello
  namespace: hello
spec:
  selector:
    app: hello
  ports:
  - protocol: TCP
    port: 80
    targetPort: http

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  namespace: hello
spec:
  ingressClassName: nginx
  rules:
    - host: www.hello.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hello
                port:
                  number: 80
```

应用

```
kubectl apply -f hello.yaml
```

本地 hosts 文件添加一条记录

```
192.168.40.191 www.hello.io
```

访问地址: http://www.hello.io/



#### 运行应用

##### 部署 MySQL 服务

yaml 文件 doplat-mysql.yaml

> 数据目录 /var/lib/mysql 挂载到 /data/doplat-mysql/data
>
> 自定义配置 /etc/mysql/conf.d 挂载到 /data/doplat-mysql/conf
>
> nodeSelector 指定部署到 node01 节点

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: doplat

---

apiVersion: v1
kind: Service
metadata:
  name: doplat-mysql
  namespace: doplat
  labels:
    app: mysql
spec:
  type: NodePort
  ports:
    - port: 3306
      nodePort: 32001
  selector:
    app: mysql

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: doplat-mysql
  namespace: doplat
  labels:
    app: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - image: mysql:5.7
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "MySQL5.7"
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-volume
          mountPath: /var/lib/mysql
          subPath: data
        - name: mysql-volume
          mountPath: /etc/mysql/conf.d
          subPath: conf
      volumes:
      - name: mysql-volume
        hostPath:
              path: /data/doplat-mysql
              type: DirectoryOrCreate
      nodeSelector:
        kubernetes.io/hostname: node01
```

应用

```
kubectl apply -f doplat-mysql.yaml
```

##### 部署 Redis

yaml 文件 doplat-redis.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: doplat-redis
  namespace: doplat
  labels:
    app: redis
spec:
  type: NodePort
  ports:
    - port: 6379
      nodePort: 32002
  selector:
    app: redis

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-mysql
  namespace: doplat
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
  serviceName: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - image: redis:6.0
        name: redis
        ports:
        - containerPort: 6379
          name: mysql
      nodeSelector:
        kubernetes.io/hostname: node01
```

应用

```
kubectl apply -f doplat-redis.yaml
```

##### 部署 doplat 方式一: nginx, django 分别使用 deployment

> 不同一 pod 容器之间的通信使用服务，需要将 nginx 反向代理 django 的地址设置为 django 的服务名

创建拉取阿里云镜像的

```
kubectl create secret docker-registry aliyun --docker-server=registry.cn-shenzhen.aliyuncs.com --docker-username=胡海青2020 --docker-password=****** -n doplat
```

nginx yaml 文件 doplat-nginx.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doplat-nginx
  namespace: doplat
spec:
  selector:
    matchLabels:
      app: doplat-nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: doplat-nginx
    spec:
      containers:
      - name: nginx
        image: registry.cn-shenzhen.aliyuncs.com/huhaiqing/doplat-nginx:1.0
        imagePullPolicy: Always
        ports:
          - name: nginx
            containerPort: 90
      imagePullSecrets:
      - name: aliyun

---

apiVersion: v1
kind: Service
metadata:
  name: doplat-nginx
  namespace: doplat
spec:
  selector:
    app: doplat-nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: nginx

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: doplat
  namespace: doplat
spec:
  ingressClassName: nginx
  rules:
    - host: www.doplat.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: doplat-nginx
                port:
                  number: 80
```

django yaml 文件 doplat-django.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doplat-django
  namespace: doplat
spec:
  selector:
    matchLabels:
      app: doplat-django
  replicas: 3
  template:
    metadata:
      labels:
        app: doplat-django
    spec:
      containers:
      - name: django
        image: registry.cn-shenzhen.aliyuncs.com/huhaiqing/doplat-django:1.0
        # image: nginx
        imagePullPolicy: Always
        ports:
          - name: django
            containerPort: 8000
      imagePullSecrets:
      - name: aliyun

---

apiVersion: v1
kind: Service
metadata:
  name: doplat-django
  namespace: doplat
spec:
  selector:
    app: doplat-django
  ports:
  - protocol: TCP
    port: 80
    targetPort: django
```

应用

```
kubectl apply -f doplat-nginx.yaml
kubectl apply -f doplat-django.yaml
```

##### 部署 doplat 方式二: nginx, django 使用同一个 StatefulSet

> 同一 pod 容器之间的通信使用 localhost，需要将 nginx 反向代理 django 的地址设置为 localhost

yaml 文件 doplat.yaml

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: doplat
  namespace: doplat
spec:
  selector:
    matchLabels:
      app: doplat
  replicas: 4
  serviceName: doplat
  template:
    metadata:
      labels:
        app: doplat
    spec:
      containers:
      - name: nginx
        image: registry.cn-shenzhen.aliyuncs.com/huhaiqing/doplat-nginx:1.0
        imagePullPolicy: Always
        ports:
          - name: nginx
            containerPort: 90
      - name: django
        image: registry.cn-shenzhen.aliyuncs.com/huhaiqing/doplat-django:1.0
        imagePullPolicy: Always
        ports:
          - name: django
            containerPort: 8000
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: log-dir
          mountPath: /doplat/logs
          subPathExpr: $(POD_NAME)
      imagePullSecrets:
      - name: aliyun
      volumes:
      - name: log-dir
        hostPath:
          path: /data/logs/doplat
          type: DirectoryOrCreate

---

apiVersion: v1
kind: Service
metadata:
  name: doplat
  namespace: doplat
spec:
  selector:
    app: doplat
  ports:
  - protocol: TCP
    port: 80
    targetPort: nginx

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: doplat
  namespace: doplat
spec:
  ingressClassName: nginx
  rules:
    - host: www.doplat.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: doplat
                port:
                  number: 80
```



#### 备份恢复

##### etcd

> snapshotdb 为备份文件

备份

```
ETCDCTL_API=3 etcdctl \
--endpoints 127.0.0.1:2379 \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
snapshot save snapshotdb
```

恢复

> 需要移走目录 /var/lib/etcd

```
ETCDCTL_API=3 etcdctl \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--name=master \
--initial-cluster=master=https://192.168.40.191:2380 \
--initial-advertise-peer-urls=https://192.168.40.191:2380 \
--data-dir=/var/lib/etcd \
snapshot restore snapshotdb
```

##### master

备份

1. /etc/kubernetes/目录下的所有文件(证书，manifest文件)
2. 用户主目录下.kube/config文件(kubectl连接认证)
3. /var/lib/kubelet/目录下所有文件(plugins容器连接认证)

恢复

1. 按之前的安装脚本进行全新安装。
2. 停止系统服务 systemctl stop kubelet.service。
3. 删除相关插件容器 (coredns,flannel,dashboard)。
4. 恢复etcd数据。
5. 将之前备份的三个目录依次还原。
6. 重启系统服务 systemctl start kubelet.service。