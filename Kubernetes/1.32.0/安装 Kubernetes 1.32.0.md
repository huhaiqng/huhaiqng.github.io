#### 主机配置

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



#### 安装 containerd
> containerd 比 docker 更适合生产环境
> 
> 使用 docker 部分 Prometheus label 缺少 

```
# 配置yum
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装
yum install -y containerd.io

cd /etc/containerd/
mv config.toml config.toml.orig
containerd config default > config.toml

systemctl enable containerd --now
```

修改 `/etc/containerd/config.toml`: `SystemdCgroup = true`

修改 `/etc/containerd/config.toml`: `sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.10"`

#### 安装 kubeadm、kubelet 和 kubectl

配置 yum 源

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```

安装

```
# master
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
# node
yum install -y kubelet kubeadm --disableexcludes=kubernetes
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



#### 创建集群

初始化集群

> --kubernetes-version 指定安装版本
>
> --control-plane-endpoint 指定集群名称，可扩展为多 master 的集群。

```
kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--control-plane-endpoint=k8s-cluster \
--upload-certs \
--cri-socket=unix:///var/run/cri-dockerd.sock \
--kubernetes-version=v1.32.0
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

配置网络

> 需要先配置网络，node 状态才会是 Ready

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

节点加入集群

```
kubeadm join k8s-cluster:6443 --token yoxzkh.33hst7b0ymj57ivs --discovery-token-ca-cert-hash sha256:e44bfeb646ddbf30b30ee0192938d160cc8c62850387dafa495ac3b28d1d110d --cri-socket=unix:///var/run/cri-dockerd.sock
```

测试运行是否正常

> coredns,flannel 都为 running，则正常

```
kubectl get pods -n kube-system
```



#### Nginx Ingress Controller

安装

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/cloud/deploy.yaml
```

ingress-nginx-controller deployment

> 将80，443直接在node启动，通过node的 80 443 访问

```
      hostIPC: true
      hostNetwork: true
      hostPID: true
      nodeSelector:
        kubernetes.io/hostname: node01
```



#### Kubernetes Dashboard

##### 安装

使用 helm 安装

```
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

创建 tls 证书

```
kubectl create secret tls k8s-tls -n kubernetes-dashboard --cert=k8s.huhaiqing.com.cn.pem --key=k8s.huhaiqing.com.cn.key
```

创建 ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: k8s-ingress
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - k8s.huhaiqing.com.cn
    secretName: k8s-tls
  rules:
    - host: k8s.huhaiqing.com.cn
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-kong-proxy
                port:
                  number: 443
```

##### Metrics Server

> 用于 Dashboard 显示 pod cpu 内存数据。

安装

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

添加启动参数 `--kubelet-insecure-tls`

##### 创建用户

```yaml
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
  
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token
```

生成临时 token

```
kubectl -n kubernetes-dashboard create token admin-user
```

生成长久 token

```
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
```



#### 监控

##### 创建命名空间

```
kubectl create namespace monitoring
```

##### Grafana

创建 tls 证书

```
kubectl create secret tls grafana-tls -n monitoring --cert=grafana.huhaiqing.com.cn.pem --key=grafana.huhaiqing.com.cn.key
```

部署 grafana

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        nfs:
          server: 131d6149a1d-osm8.us-east-1.nas.aliyuncs.com
          path: /grafana

---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
  labels:
    app: grafana
spec:
  type: NodePort
  ports:
    - name: web
      port: 3000
      targetPort: 3000
      nodePort: 30000
  selector:
    app: grafana

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - grafana.huhaiqing.com.cn
    secretName: grafana-tls
  rules:
    - host: grafana.huhaiqing.com.cn
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

导入 dashboard id 21298(pod)，22523(kubernetes cluster)

##### Node Exporter

yaml 文件

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    name: node-exporter
spec:
  selector:
    matchLabels:
      name: node-exporter
  template:
    metadata:
      labels:
        name: node-exporter
    spec:
      hostPID: true
      hostIPC: true
      hostNetwork: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v0.16.0
        ports:
        - containerPort: 9100
        resources:
          requests:
            cpu: 0.15
        securityContext:
          privileged: true
        args:
        - --path.procfs
        - /host/proc
        - --path.sysfs
        - /host/sys
        - --collector.filesystem.ignored-mount-points
        - '"^/(sys|proc|dev|host|etc)($|/)"'
        volumeMounts:
        - name: dev
          mountPath: /host/dev
        - name: proc
          mountPath: /host/proc
        - name: sys
          mountPath: /host/sys
        - name: rootfs
          mountPath: /rootfs
      tolerations:  # 添加容忍的声明
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: dev
          hostPath:
            path: /dev
        - name: sys
          hostPath:
            path: /sys
        - name: rootfs
          hostPath:
            path: /
```

##### kube-state-metrics

下载

```
git clone https://github.com/kubernetes/kube-state-metrics.git
```

安装

```
cd kube-state-metrics
kubectl apply -f examples/standard
```

##### Prometheus

部署 yaml 文件

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 15s
    scrape_configs:
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    - job_name: 'kubernetes-node-exporter' 
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      # 新增集群 label
      - target_label: cluster
        replacement: k8s-cluster
      - source_labels: [__address__]
        regex: '(.*):10250' 
        replacement: '${1}:9100' 
        target_label: __address__ 
        action: replace
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
    - job_name: 'kubernetes-node-cadvisor'
      kubernetes_sd_configs:
      - role:  node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      # 新增集群 label
      - target_label: cluster
        replacement: k8s-cluster
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
    - job_name: "kube-state-metrics"
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_endpoints_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: kube-system;kube-state-metrics;http-metrics

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  ports:
    - port: 9090
      targetPort: 9090
  selector:
    app: prometheus

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: prometheus.huhaiqing.com.cn
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus
                port:
                  number: 9090

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccount: prometheus
      containers:
        - name: prometheus
          image: prom/prometheus
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--storage.tsdb.retention.time=180d"
            - "--storage.tsdb.path=/prometheus"
          ports:
            - containerPort: 9090
          resources:
            limits:
              cpu: 250m
              memory: 400Mi
            requests:
              cpu: 100m
              memory: 200Mi
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus/
            - name: prometheus-storage
              mountPath: /prometheus
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
        - name: prometheus-storage
          nfs:
            server: 131d6149a1d-osm8.us-east-1.nas.aliyuncs.com
            path: /prometheus
```

#### 日志

##### loki

yaml 文件

```yaml
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: logging
spec:
  selector:
    app: loki
  ports:
    - protocol: TCP
      port: 3100
      targetPort: 3100

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
        - name: loki
          image: grafana/loki:latest
          ports:
            - containerPort: 3100
              name: http
          volumeMounts:
            - name: loki-storage
              mountPath: /loki
      volumes:
        - name: loki-storage
          nfs:
            server: 131d6149a1d-osm8.us-east-1.nas.aliyuncs.com
            path: /loki
```

使用域名`http://loki.logging.svc.cluster.local:3100`接 grafana

> 与 grafana 不同命名空间

##### alloy

> 使用 api 读取 pod 日志

yaml 文件

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alloy
  namespace: logging

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: alloy
rules:
- apiGroups: [""]
  resources:
  - pods
  - pods/log
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: alloy
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
  - kind: ServiceAccount
    name: alloy
    namespace: logging

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alloy-config
  namespace: logging
data:
  config.alloy: |
    discovery.kubernetes "pod" {
      role = "pod"

      namespaces {
        names = ["logging"]
      }
    }

    loki.source.kubernetes "pod" {
      targets    = discovery.kubernetes.pod.targets
      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "http://loki.logging.svc.cluster.local:3100/loki/api/v1/push"
      }
    }

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: alloy
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alloy
  template:
    metadata:
      labels:
        app: alloy
    spec:
      serviceAccount: alloy
      containers:
        - name: alloy
          image: grafana/alloy:latest
          volumeMounts:
            - name: alloy-config
              mountPath: /etc/alloy
      volumes:
        - name: alloy-config
          configMap:
            name: alloy-config
```

