##### TASK 1

Set configuration context $kubectl config use-context k8s. Monitor the logs of Pod foobar and Extract log lines corresponding to error unable-to-access-website . Write them to /opt/KULM00612/foobar.

命令

```
kubectl logs foobar | grep "unable-to-access-website" >> /opt/KULM00612/foobar
```

##### TASK 2

Set configuration context $kubectl config use-context k8s. List all PVs sorted by capacity, saving the full kubectl output to /opt/KUCC0006/my_volumes. Use kubectl own functionally for sorting the output, and do not manipulate it any further

命令

```
kubectl get pv --sort-by={.spec.capacity.sotrge} --all-namespaces >> /opt/KUCC0006/my_volumes
```

##### TASK 3

Set configuration context $kubectl config use-context k8s. Ensure a single instance of Pod nginx is running on each node of the Kubernetes cluster where nginx also represents the image name which has to be used. Do no override any taints currently in place. Use Daemonset to complete this task and use ds.kusc00612 as Daemonset name

yaml

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds.kusc00612 
  labels:
    k8s-app: nginx
spec:
  selector:
    matchLabels:
      name: nginx 
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

##### TASK 4

Set configuration context $kubectl config use-context k8s Perform the following tasks: Add an init container to lumpy-koala(which has been defined in spec file /opt/kucc00100/pod-specKUCC00612.yaml). The init container should create an empty file named /workdir/calm.txt. If /workdir/calm.txt is not detected, the Pod should exit. Once the spec file has been updated with the init container definition, the Pod should be created

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 1d']
    volumeMounts:
    - mountPath: /workdir
      name: cache-volume
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c', "[ -f /workdir/calm.txt ] || touch /workdir/calm.txt" ]
    volumeMounts:
    - mountPath: /workdir
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

##### TASK 5

Set configuration context $kubectl config use-context k8s. Create a pod named kucc6 with a single container for each of the following images running inside(there may be between 1 and 4 images specified):nginx +redis+memcached+consul。

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: kucc6
  labels:
    app: kucc6 
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

##### TASK 6

Set configuration context $kubectl config use-context k8s Schedule a Pod as follows: Name: nginxkusc00612 Image: nginx Node selector: disk=ssd

yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: nginxkusc00612
  labels:
    app: nginxkusc00612
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  nodeSelector:
    disk: ssd
```

##### TASK 7

Set configuration context $kubectl config use-context k8s. Create a deployment as follows: Name: nginxapp Using container nginx with version 1.11.9-alpine. The deployment should contain 3 replicas. Next, deploy the app with new version 1.12.0-alpine by performing a rolling update and record that update.Finally,rollback that update to the previous version 1.11.9-alpine.

yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginxapp 
  labels:
    app: nginx
spec:
  replicas: 3
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
        image: nginx:1.11.9-alpine
        ports:
        - containerPort: 80
```

命令

```
kubectl set image deployment/nginxapp nginx=nginx:1.12.0-alpine --record
kubectl rollout undo deployment.v1.apps/nginxapp
```

##### TASK 8

Set configuration context $kubectl config use-context k8s Create and configure the service front-endservice so it’s accessible through NodePort/ClusterIp and routes to the existing pod named nginxkusc00612

yaml

```
apiVersion: v1
kind: Service
metadata:
  name: front-endservice
spec:
  selector:
    name: nginxkusc00612
  type: NodePort
  ports:
  - name: nginx
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginxkusc00612
  labels:
    name: nginxkusc00612 
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

##### TASK 9

Set configuration context $kubectl config use-context k8s Create a Pod as follows: Name: jenkins Using image: jenkins In a new Kubernetes namespace named pro-test

yaml

```
apiVersion: v1
kind: Namespace
metadata:
  name: pro-test
---
apiVersion: v1
kind: Pod
metadata:
  name: jenkins
  namespace: pro-test
  labels:
    app: jenkins
spec:
  containers:
  - name: jenkins
    image: jenkins
```

##### TASK 10

Set configuration context $kubectl config use-context k8s Create a deployment spec file that will: Launch 7 replicas of the redis image with the label : app_enb_stage=dev Deployment name: kual00612 Save a copy of this spec file to /opt/KUAL00612/deploy_spec.yaml (or .json) When you are done,clean up(delete) any new k8s API objects that you produced during this task

yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kual00612
  labels:
    app_enb_stage: dev
spec:
  replicas: 7
  selector:
    matchLabels:
      app_enb_stage: dev
  template:
    metadata:
      labels:
        app_enb_stage: dev
    spec:
      containers:
      - name: redis
        image: redis
        ports:
        - containerPort: 6379
```

##### TASK 11

Set configuration context $kubectl config use-context k8s Create a file /opt/KUCC00612/kucc00612.txt that lists all pods that implement Service foo in Namespace production. The format of the file should be one pod name per line.

命令

```
podlabel=`kubectl describe service front-endservice | grep Selector | awk '{print $NF}'`
kubectl get pods -l $podlabel | grep -v NAME | awk '{print $1}' > /opt/KUCC00612/kucc00612.txt
```

##### TASK 12

Set configuration context $kubectl config use-context k8s Create a Kubernetes Secret as follows: Name: super-secret credential: blob, Create a Pod named pod-secrets-via-file using the redis image which mounts a secret named super-secret at /secrets. Create a second Pod named pod-secretsvia-env using the redis image, which exports credential as 

yaml

```
apiVersion: v1
kind: Secret
metadata:
  name: super-secret
type: Opaque
stringData:
  credential: blob
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-secrets-via-file 
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: super-secret
      mountPath: "/secrets"
  volumes:
  - name: super-secret
    secret:
      secretName: super-secret
---
apiVersion: v1
kind: Pod
metadata:
  name: redis2
spec:
  containers:
  - name: redis
    image: redis
    envFrom:
    - secretRef:
        name: super-secret
```

##### TASK 13

Set configuration context $kubectl config use-context k8s Create a pod as follows: Name: nonpersistent-redis Container image: redis Named-volume with name: cache-control Mount path : /data/redis It should launch in the pre-prod namespace and the volume MUST NOT be persistent.

yaml

```
apiVersion: v1
kind: Namespace
metadata:
  name: pre-prod
---
apiVersion: v1
kind: Pod
metadata:
  name: nonpersistent-redis 
  namespace: pre-prod
spec:
  containers:
  - image: redis 
    name: redis 
    volumeMounts:
    - mountPath: /data/redis 
      name: cache-control
  volumes:
  - name: cache-control
    emptyDir: {}
```

##### TASK 14

Set configuration context $kubectl config use-context k8s Scale the deployment webserver to 6 pods

命令

```
kubectl scale deployment.v1.apps/webserver --replicas=6
```

##### TASK 15

Set configuration context $kubectl config use-context k8s Check to see how many nodes are ready (not including nodes tainted NoSchedule) and write the number to /opt/nodenum.

命令

```
kubectl describe nodes | grep Taints
kubectl get nodes | grep Ready
```

##### TASK 16

Set configuration context $kubectl config use-context k8s Create a deployment as follows: Name: nginxdns Exposed via a service : nginx-dns Ensure that the service & pod are accessible via their respective DNS records The container(s) within any Pod(s) running as a part of this deployment should use the nginx image. Next, use the utility nslookup to look up the DNS records of the service & pod and write the output to /opt/service.dns and /opt/pod.dns respectively. Ensure you use the busybox:1.28 image (or earlier) for any testing, an the latest release has an upstream bug which impacts the use of nslookup

yaml

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-dns
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginxdns 
  labels:
    app: nginx
spec:
  replicas: 1
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
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - image: busybox:1.28
    command:
      - sleep
      - "1d"
    imagePullPolicy: IfNotPresent
    name: busybox
```

命令

```
kubectl exec busybox -- nslookup nginx-dns >> /opt/service.dns
kubectl exec busybox -- nslookup 10.244.2.35 >> /opt/pod.dns
```

##### TASK 17

No configuration context change required for this item Create a snapshot of the etcd instance running at https://127.0.0.1:2379 saving the snapshot to the file path /data/backup/etcd-snapshot.db The etcd instance is running etcd version 3.2.18 The following TLS certificates/key are supplied for connecting to the server with etcdctl CA certificate: /opt/KUCM0612/ca.crt Client certificate: /opt/KUCM00612/etcdclient.crt Client key: /opt/KUCM00612/etcd-client.key

```
ETCDCTL_API=3 etcdctl \
--endpoints=https://127.0.0.1:2379 \
--cacert=/opt/KUCM0612/ca.crt \
--cert= /opt/KUCM00612/etcdclient.crt \
--key=/opt/KUCM00612/etcdclient.crt \
snapshot save /data/backup/etcd-snapshot.db

ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshotdb
```

##### TASK 18

Set configuration context $kubectl config use-context ek8s Set the node labelled with name=ek8s-node-1 as unavailable and reschedule all the pods running on it.

命令

```
kubectl get nodes -l name=ek8s-node-1 --show-labels
kubectl cordon <node name>
kubectl drain <node name>
```

##### TASK 19

Set configuration context $kubectl config use-context wk8s A Kubernetes worker node,labelled with name=wk8s-node-0 is in state NotReady. Investigate why this is the case, and perform any appropriate steps to bring the node to a Ready state, Ensuring that any changes are made permanent. Hints: You can ssh to the failed node using $ssh wk8s-node-0. You can assume elevated privileges on the node with the following command $sudo -i

命令

```
kubectl get nodes -l name=wk8s-node-0 --show-labels
ssh <node name>
sudo -i
systemctl start kubelet
systemctl enable kubelet
```

##### TASK 20

Set configuration context $kubectl config use-context wk8s Configure the kubelet system managed service,on the node labelled with name=wk8s-node-1, to Launch a Pod containing a single container of image nginx named myservice automatically. Any spec files required should be placed in the /etc/kubernetes/manifests directory on the node. Hints: You can ssh to the failed node using $ssh wk8snode-1. You can assume elevated privileges on the node with the following command $sudo -i

yaml

```
apiVersion: v1
kind: Service
metadata:
  name: myservice
spec:
  selector:
    name: nginx
  ports:
  - name: nginx 
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx 
  labels:
    name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    ports:
    - containerPort: 80
```

##### TASK 21

Set configuration context $kubectl config use-context hk8s Create a persistent volume with name appconfig of capacity 1Gi and access mode ReadWriteMany. The type of volume is hostPath and its locationis /srv/app-config

yaml

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: appconfig
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/srv/app-config"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: appconfig-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 0.5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: task-pv-pod
  labels:
    name: nginx
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: appconfig-claim
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
---
apiVersion: v1
kind: Service
metadata:
  name: myservice
spec:
  selector:
    name: nginx
  ports:
  - name: nginx 
    port: 80
    targetPort: 80
```



