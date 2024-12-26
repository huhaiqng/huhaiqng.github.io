
#### 创建阿里云传统型负载均衡CLB

<img src="https://github.com/user-attachments/assets/ac79326c-5422-419c-8f5d-7e0375a1073a" width="600">

#### 修改 nginx ingress controller service
> `externalTrafficPolicy: Local`: 当通过 nodePort 访问服务的时候，只能访问当前node的 pod。
> 
> `nodePort: 32080`: 固定 http port
> 
> `nodePort: 32443`: 固定 https port
>
> `service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id`: 修改成新建的实例 ID
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id: 'lb-0xisk2930qsd6ipl86pl0'
    service.beta.kubernetes.io/alicloud-loadbalancer-force-override-listeners: 'true'
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.12.0-beta.0
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  # externalTrafficPolicy: Local
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - appProtocol: http
    name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 32080
  - appProtocol: https
    name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 32443
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: LoadBalancer
```

#### 服务 ingress-nginx-controller 修改完成后可以看到负载均衡自动创建的监听

<img src="https://github.com/user-attachments/assets/a4e74c18-0bd5-4aa9-8fbb-84cd3c761c2c" width="600">

#### 修改服务器组，添加后端 node

<img src="https://github.com/user-attachments/assets/7b01a6cb-1d91-411b-84bf-77c6cdcc9525" width="600">
