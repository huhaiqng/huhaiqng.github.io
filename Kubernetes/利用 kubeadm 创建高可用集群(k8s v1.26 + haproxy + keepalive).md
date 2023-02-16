##### 配置主机

host 解析

> vip:	192.168.198.10
>
> 集群名:	cluster.myk8s.io

```
# 集群
192.168.198.10  cluster.myk8s.io
# master
192.168.198.11  master01
192.168.198.12  master02
192.168.198.13  master03
# node
192.168.198.21  node01
192.168.198.22  node02
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

##### 安装 keepalive

安装

```
yum install -y keepalived
```

判断脚本 /etc/keepalived/check_apiserver.sh

```
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:8443/ -o /dev/null || errorExit "Error GET https://localhost:8443/"
if ip addr | grep -q 192.168.198.10; then
    curl --silent --max-time 2 --insecure https://192.168.198.10:8443/ -o /dev/null || errorExit "Error GET https://192.168.198.10:8443"
fi
```

master01 配置文件 /etc/keepalived/keepalived.conf

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 101
    authentication {
        auth_type PASS
        auth_pass 111222
    }
    virtual_ipaddress {
        192.168.198.10
    }
    track_script {
        check_apiserver
    }
}
```

master02配置文件 /etc/keepalived/keepalived.conf

> priority 越大越容易获取 vip

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 100
    authentication {
        auth_type PASS
        auth_pass 111222
    }
    virtual_ipaddress {
        192.168.198.10
    }
    track_script {
        check_apiserver
    }
}
```

master03 配置文件 /etc/keepalived/keepalived.conf

> priority 越大越容易获取 vip

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 51
    priority 99
    authentication {
        auth_type PASS
        auth_pass 111222
    }
    virtual_ipaddress {
        192.168.198.10
    }
    track_script {
        check_apiserver
    }
}
```

##### 安装 haproxy

安装

```
yum install -y haproxy
```

配置文件 /etc/haproxy/haproxy.cfg

```
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server 1 192.168.198.11:6443 check
        server 2 192.168.198.12:6443 check
        server 3 192.168.198.13:6443 check
```

##### 安装 docker

```
# 配置yum
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装
yum install -y containerd.io-1.6.16-3.1.el7.x86_64 docker-ce-cli-23.0.1-1.el7.x86_64 docker-ce-23.0.1-1.el7.x86_64

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
systemctl enable docker --now
```

##### 安装 cri-dockerd

下载 rpm 包

```
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.1/cri-dockerd-0.3.1-3.el7.x86_64.rpm
```

安装

```
rpm -ivh cri-dockerd-0.3.1-3.el7.x86_64.rpm
```

查看 pause 版本

```
kubeadm config images list
```

修改文件 /usr/lib/systemd/system/cri-docker.service，在启动命令添加 --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.9

> --pod-infra-container-image 默认的是 registry.k8s.io/pause:3.6，无法下载。

```
ExecStart=/usr/bin/cri-dockerd --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.9 --container-runtime-endpoint fd://
```

启动

```
systemctl daemon-reload
systemctl enable cri-docker --now
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
kubectl-1.26.1-0.x86_64 kubelet-1.26.1-0.x86_64 kubeadm-1.26.1-0.x86_64 --disableexcludes=kubernetes
systemctl enable --now kubelet
# node
yum install -y kubelet-1.26.1-0.x86_64 kubeadm-1.26.1-0.x86_64 --disableexcludes=kubernetes
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
>
> --control-plane-endpoint 指定负载均衡 DNS 和 端口号。

```
kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--image-repository=registry.aliyuncs.com/google_containers \
--control-plane-endpoint=cluster.myk8s.io:8443 \
--upload-certs \
--cri-socket=unix:///var/run/cri-dockerd.sock \
--kubernetes-version=v1.26.1
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

master 加入集群

```
kubeadm join cluster.myk8s.io:8443 --token fzws8f.xtqd66r02qfvmwvq \
	--discovery-token-ca-cert-hash sha256:12fba602021602c52bf256e4891c8b02494ff66f867c5fe8eee18fd8e0938ab0 \
	--control-plane --certificate-key 12ff398725ba1225b6e47441698ba5698390beb6365d24f23198034d6c238a5b \
	--cri-socket=unix:///var/run/cri-dockerd.sock
```

节点加入集群

```
join cluster.myk8s.io:8443 --token fzws8f.xtqd66r02qfvmwvq \
	--discovery-token-ca-cert-hash sha256:12fba602021602c52bf256e4891c8b02494ff66f867c5fe8eee18fd8e0938ab0 \
    --cri-socket=unix:///var/run/cri-dockerd.sock
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

查看节点加入命令

```
kubeadm token create --print-join-command
```

重新生成 certificate-key

> certificate-key 会过期，添加 master 节点需要该 key

```
# 获取初始化集群的默认配置
kubeadm config print init-defaults > config.yaml
# 将默认配置的 criSocket 改为 unix:///var/run/cri-dockerd.sock
# 生成 certificate-key
kubeadm init phase upload-certs --config config.yaml --upload-certs
```

##### 部署 Dashboard UI

下载 yaml 文件

```
https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

修改 deployment，添加参数 --token-ttl=86400 , 延长会话超时时间

修改 deploymen，imagePullPolicy: IfNotPresent， 以免每次重新拉取镜像

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

> 访问地址为: [https://cluster.myk8s.io:30443](https://masterip:30443/)

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
kubectl -n kubernetes-dashboard create token admin-user --duration 525600m
```

##### 部署 Metrics Server

> 如果要部署 kube-prometheus，则不需要部署 Metrics Server

下载 yaml 文件

```
https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

修改 deployment args 添加 `--kubelet-insecure-tls`

修改 `imagePullPolicy: IfNotPresent`， 以免每次重新拉取镜像

修改镜像

```
image: bitnami/metrics-server:0.6.2
```

应用

```
kubectl apply -f components.yaml
```

等待1分钟左右，检测

```
kubectl top nodes
```

参考文档：

https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/high-availability/

https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing