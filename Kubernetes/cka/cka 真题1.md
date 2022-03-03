##### TASK 1

Create a service account name dev-sa in default namespace, dev-sa can create below components in dev namespace:

- Deployment

- StatefulSet

- DaemonSet

命令

```shell
kubectl create sa dev-sa -n defalut
kubectl create role sa-role -n dev --resource=deployment,statefulset,daemonset --verb=create
kubectl create rolebinding sa-rolebinding -n dev --role=sa-role --serviceaccount=default:dev-sa
kubectl auth can-i create deployment -n dev --as=system:serviceaccount:default:dev-sa
```

yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-sa 
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: sa-role
  namespace: dev
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "daemonsets"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sa-rolebinding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: dev-sa
  namespace: default
roleRef:
  kind: Role 
  name: sa-role 
  apiGroup: rbac.authorization.k8s.io
```

##### TAKS 2

Create a pod name log, container name log-pro use image busybox, output the important information at /log/data/output.log. Then another container name log-cus use image busybox, load the output.log at /log/data/output.log and print it. Note, this log file only can be share within the pod.

yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: log
spec:
  template:
    spec:
      containers:
      - name: log-pro
        image: busybox
        volumeMounts:
        - mountPath: /log/data
          name: log-volume
        command: ['sh', '-c', 'echo "Hello, Kubernetes!" >> /log/data/output.log && sleep 1d']
      - name: log-cus
        image: busybox
        volumeMounts:
        - mountPath: /log/data
          name: log-volume
        command: ['sh', '-c', 'cat /log/data/output.log && sleep 1d']  
      restartPolicy: OnFailure
      volumes:
      - name: log-volume
        emptyDir: {}
```

##### TASK 3

Only pods that in the internal namespace can access to the pods in mysql namespace via port 8080/TCP.

设置 label

```
kubectl label namespace mysql nwname=mysql
kubectl get namespace --show-labels | grep mysql
```

yaml

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mysql
  namespace: mysql
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          nwname: mysql
    ports:
    - protocol: TCP
      port: 8080 
```

##### TASK 4

Count the ready node in this cluster that without have a taint, and output the number to the file lrootlckalreadtyNode.txt.

```
kubectl get nodes
kubectl describe nodes | grep Taint
```

##### TASK 5

Output the pod name that uses most CPU resource to file /root/cka/name.txt

##### TASK 6

There is pod name pod-nginx, create a service name service-nginx, use nodePort to expose the pod. Then create a pod use image busybox to nslookup the pod pod-nginx and service service-nginx.