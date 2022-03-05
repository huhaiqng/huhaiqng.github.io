##### Task 1
创建一个名为deployment-clusterrole且仅允许创建以下资源类型的新ClusterRole :

- Deployment
- statefulSet

- DaemonSet

  在现有的namespace app-team1中创建一个名为cicd-token的新ServiceAccount 。
  限于namespace app-team1，将新的ClusterRole deployment-clusterrole绑定到新的serviceAccount cicd-token 。

yaml

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-token
  namespace: app-team1
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployment-clusterrole
  namespace: app-team1
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: deployment-clusterrolebinding
  namespace: app-team1
subjects:
- kind: ServiceAccount
  name: cicd-token
  namespace: app-team1
roleRef:
  kind: ClusterRole
  name: deployment-clusterrole 
  apiGroup: rbac.authorization.k8s.io
```

命令

```
kubectl auth can-i create daemonset -n app-team1 --as=system:serviceaccount:app-team1:cicd-token
```

##### TASK 2

Set the node named ek8s-node-1 as unavailableand reschedule all the pods running on it.

命令

```
kubectl get pods -o wide
kubectl get nodes
kubectl drain ek8s-node-1
```

##### TASK 3

Given an existing Kubernetes cluster runningversion 1.18.8 , upgrade all of the Kubernetescontrol plane and node components on themaster node only to version 1.19.0 . You are also expected to upgrade kubelet andkubectl on the master node.

##### TASK 4

首先，为运行在https://127.0.0.1:2379上的现有etcd 实例创建快照并将快照保存到/data/backup/etcd-snapshot.db 。然后还原位于/srv/data/etcd-snapshot-previous.db 的现有先前快照。

命令

```
# 备份
ETCDCTL_API=3 etcdctl \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
snapshot save /data/backup/etcd-snapshot.db
# 还原
ETCDCTL_API=3 etcdctl \
--endpoints=https://127.0.0.1:2379 \
# --initial-advertise-peer-urls=https://192.168.40.191:2380 \
# --initial-cluster=default=https://192.168.40.191:2380 \
# --data-dir /var/lib/etcd \
snapshot restore snap
```

##### TASK 5

Create a new NetworkPolicy named allow-port-from-namespace that allows Podsin the existing namespace internal to connectto port 8080 of other Pods in the same namespace. Ensure that the new NetworkPolicy :

- does not allow access to Pods not listening on port 8080
- does not allow access from Pods not in namespace internal

yaml

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: internal
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: internal
    ports:
    - protocol: TCP
      port: 8080
```

##### TASK 6

Reconfigure the existing deployment front-endand add a port specification named http exposing port 80/tcp of the existing container nginx.
Create a new service named front-end-svc exposing the container port http.
Configure the new service to also expose the individual Pods via a NodePort on the nodes on which they are scheduled.

yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front-endand
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name:  front-end-svc
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: my-nginx
---
apiVersion: v1
kind: Service
metadata:
  name:  front-end-svc-nodeport
  labels:
    run: my-nginx
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: my-nginx
```

##### TASK 7

Create a new nginx Ingress resource asfollows:

- Name: ping
- Namespace: ing-internal
-  Exposing service hi on path /hi using service port 5678

yaml

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ping
  namespace: ing-internal
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /hi
        pathType: Prefix
        backend:
          service:
            name: hi
            port:
              number: 5678
```

##### TASK 8

Scale the deployment presentation to 3 pods.

命令

```
kubectl scale deployment.v1.apps/presentation --replicas=3
```

##### TASK 9

schedule a pod as follows:

- Name: nginx-kusc00401 
- lmage: nginx
- Node selector: disk=spinning

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-kusc00401
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disk: spinning
```

##### TASK 10

check to see how many nodes are ready (notincluding nodes tainted Noschedule ) andwrite the number to
/opt/KUSC00402/kusc00402.txt .

命令

``` 
kubectl describe nodes | grep Taints
kubectl get nodes
echo 2 > /opt/KUSC00402/kusc00402.txt
```

##### TASK 11

Create a pod named kucc8 with a single appcontainer for each of the following imagesrunning inside (there may be between 1 and 4images specified): nginx + redis + memcached + consul .

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: kucc8 
spec:
  containers:
  - name: nginx
    image: nginx
  - name: redis
    image: redis
  - name: memcached
    image: memcached
  - name: consul
    image: consul
```

##### TASK 12

create a persistent volume with name app-config , of capacity 1Gi and access mode ReadOnlyMany . The type of volume is hostPath and its location is /srv/app-config .

yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-config 
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadOnlyMany
  hostPath:
    path: "/srv/app-config"
```

##### TASK 13

Create a new PersistentvolumeClaim :

- Name: pv-volume

- Class: csi-hostpath-sc

- capacity: 10Mi

  create a new Pod which mounts the PersistentvolumeClaim as a volume:

- Name: web-server
- lmage: nginx
- Mount path: /usr/share/nginx/html
configure the new Pod to have
Readwriteonce access on the volume.
Finally, using kubectl edit or kubectl patchexpand the PersistentVolumeClaim to acapacity of 70Mi and record that change.

yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: csi-hostpath-sc
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-volume
spec:
  storageClassName: csi-hostpath-sc
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: pv-volume
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
```

命令

```
kubectl edit pvc pv-volume --record
```

##### TASK 14

Monitor the logs of pod bar and:

- Extract log lines corresponding to error unable-to-access-website
- Write them to /opt/KUTR00101/bar

命令

```
kubectl logs bar | grep unable-to-access-website > /opt/KUTR00101/bar
```

##### TASK 15

Add a busybox sidecar container to the existing Pod big-corp-app . The new sidecar container has to run the following command:

Use a volume mount named logs to make thefile /var/log/big-corp-app.log available to thesidecar container.

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: big-corp-app
spec:
  containers:
  - image: busybox
    command: ['sh', '-c', 'while true; do   date >> /var/log/big-corp-app.log;   sleep 1s; done'] 
    name: log-pro
    volumeMounts:
    - mountPath: /var/log
      name: cache-volume
  - image: busybox 
    command: ['sh', '-c', 'tail -n+1 /var/log/big-corp-app.log']
    name: log-cus
    volumeMounts:
    - mountPath: /var/log
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

