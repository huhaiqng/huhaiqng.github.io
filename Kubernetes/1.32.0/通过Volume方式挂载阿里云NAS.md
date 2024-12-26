#### 创建NAS文件系统

<img src="https://github.com/user-attachments/assets/a2e3cc07-6dea-4b71-b64f-ffad715b112c" width="600">

#### 获取挂载点地址

<img src="https://github.com/user-attachments/assets/b5a00769-c2c4-4626-b69d-5b6c668e274c" width="800">

#### node 上安装 nfs-utils

```
sudo yum install nfs-utils
```

#### 配置/etc/nfsmount.conf文件添加以下内容

```
cat <<EOF >> /etc/nfsmount.conf
[ Server "file-system-id.region.nas.aliyuncs.com" ]
vers=3
Proto=tcp
Lock=False
resvport=False
rsize=1048576
wsize=1048576
hard=True
timeo=600
retrans=2
EOF
```

#### 在 nginx pod 中挂载 NAS

```
cat  << EOF > ./nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /data
          name: test-nfs
      volumes:
      - name: test-nfs
        nfs:
          server: file-system-id.region.nas.aliyuncs.com    # 阿里云NAS文件系统挂载点地址，请根据实际值替换。例如，7bexxxxxx-xxxx.ap-southeast-1.nas.aliyuncs.com。
          path: /    # NAS文件系统目录路径。该目录必须为已经存在的目录或根目录。通用型NAS的根目录为“/”，极速型NAS的根目录为“/share”。
EOF
```
