#### 安装

##### 主机配置

在 /etc/hosts 文件中添加主机解析

> k8s-cluster: k8s master 集群名称

```
192.168.1.10 k8s-master k8s-cluster
192.168.1.11 k8s-node01
192.168.1.12 k8s-node02
```

配置 br_netfilter 模块

```
# 检查 br_netfilter 是否已加载，没有输出则没有加载
lsmod | grep br_netfilter

# 创建文件 /etc/modules-load.d/k8s.conf 服务器服务器启动时自动加载
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# 手动加载
modprobe overlay
modprobe br_netfilter
```

修改内核参数文件 /usr/lib/sysctl.d/00-system.conf，应用更新 `sysctl --system`

```
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
```

##### 安装 docker

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

##### 安装 cri-dockerd

下载 rpm 包

```
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.6/cri-dockerd-0.2.6-3.el7.x86_64.rpm
```

安装

```
rpm -ivh cri-dockerd-0.2.6-3.el7.x86_64.rpm
```

修改文件 /usr/lib/systemd/system/cri-docker.service，在启动命令添加 `--pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.8`

> --pod-infra-container-image 默认的是 registry.k8s.io/pause:3.6，无法下载

```
ExecStart=/usr/bin/cri-dockerd --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.8 --container-runtime-endpoint fd://
```

启动

```
systemctl daemon-reload
systemctl start cri-docker
systemctl enable cri-docker
```

##### 安装 kubeadm、kubelet 和 kubectl

配置 yum 源

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

安装

```
# master
yum install -y \
kubelet-1.25.2-0.x86_64 kubeadm-1.25.2-0.x86_64 kubectl-1.25.2-0.x86_64 --disableexcludes=kubernetes
systemctl enable --now kubelet
# node
yum install -y kubelet-1.25.2-0.x86_64 kubeadm-1.25.2-0.x86_64 --disableexcludes=kubernetes
systemctl enable --now kubelet
```

启用 kubectl shell 自动补全功能 

```
# 安装 bash-completion
yum install -y bash-completion
# 加载
source /usr/share/bash-completion/bash_completion
# 验证
type _init_completion
# 添加 kubectl 补全功能
kubectl completion bash | tee /etc/bash_completion.d/kubectl
```

##### 创建集群

初始化集群

> --kubernetes-version 指定安装版本
>
> --control-plane-endpoint 指定集群名称，可扩展为多 master 的集群。

```
kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--image-repository=registry.aliyuncs.com/google_containers \
--control-plane-endpoint=k8s-cluster \
--upload-certs \
--cri-socket=unix:///var/run/cri-dockerd.sock \
--kubernetes-version=v1.25.2
```

配置 config file

```
# 非 root 用户
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# root 用户添加到 .bash_profile 文件中
export KUBECONFIG=/etc/kubernetes/admin.conf
```

节点加入集群

```
kubeadm join k8s-cluster:6443 --token yoxzkh.33hst7b0ymj57ivs --discovery-token-ca-cert-hash sha256:e44bfeb646ddbf30b30ee0192938d160cc8c62850387dafa495ac3b28d1d110d --cri-socket=unix:///var/run/cri-dockerd.sock
```

配置网络

> 需要先配置网络，node 状态才会是 Ready
>
> 使用的镜像 quay.io/coreos/flannel:v0.12.0-amd64，为了加快速度可以提前准备

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

测试运行是否正常

> coredns,flannel 都为 running，则正常

```
kubectl get pods -n kube-system
```

##### 部署 Dashboard UI

下载 yaml 文件

```
https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

添加参数 --token-ttl=86400 , 延长会话超时时间

![image-20211122145819329](C:\Users\haiqi\Desktop\devops-note\Kubernetes\assets\image-20211122145819329.png)

修改 imagePullPolicy: IfNotPresent， 以免每次重新拉取镜像

![image-20211122150030156](C:\Users\haiqi\Desktop\devops-note\Kubernetes\assets\image-20211122150030156.png)

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

> 访问地址为: https://masterip:30443

![image-20211122151312396](C:\Users\haiqi\Desktop\devops-note\Kubernetes\assets\image-20211122151312396.png)

创建用户 admin-user.yaml

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
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

应用

```
kubectl apply -f admin-user.yaml
```

创建用户 token

```
kubectl -n kubernetes-dashboard create token admin-user --duration=0s
```

##### 部署 Metrics Server

> 如果要部署 kube-prometheus，则不需要部署 Metrics Server

下载 yaml 文件

```
https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

修改 deployment args 添加 `--kubelet-insecure-tls`

![image-20211122152002930](C:\Users\haiqi\Desktop\devops-note\Kubernetes\assets\image-20211122152002930.png)

修改 `imagePullPolicy: IfNotPresent`， 以免每次重新拉取镜像

修改镜像

```
image: bitnami/metrics-server:0.6.1
```

应用

```
kubectl apply -f components.yaml
```

等待1分钟左右，检测

```
kubectl top nodes
```



#### 注意

1、1.24，1.25后的版本 nodeport 的端口号，用 netstat 命令查看不到。