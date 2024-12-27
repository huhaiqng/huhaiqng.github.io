Jenkins 上添加一下命令

```shell
PROJECT_NAME=jew-cust
NAMESPACE=test
IMAGE_TAG=`date +%Y%m%d%H%M%S`
IMAGE_NAME=harbor.lingfannao.net:4436/${NAMESPACE}/${PROJECT_NAME}:${IMAGE_TAG}
KUBE_CMD="kubectl set image deployment/${PROJECT_NAME} app=${IMAGE_NAME} -n ${NAMESPACE} --record"
cd jew-dist-customized
docker build -t ${IMAGE_NAME} -f /data/dockerfile/springboot .
docker push ${IMAGE_NAME} && docker rmi ${IMAGE_NAME}
ssh -i /root/.ssh/deploy -p 6666 pro@192.168.1.100 "${KUBE_CMD}"
```

北京时间 jdk 镜像 Dockerfile

```
# openjdk
FROM openjdk:8-jdk-alpine
ENV LANG en_US.UTF-8
RUN echo "https://mirrors.aliyun.com/alpine/v3.9/main/" > /etc/apk/repositories ;\
    apk add tzdata ;\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    echo "Asia/Shanghai" >/etc/timezone ;\
    rm -f /var/cache/apk/*

# oracle jdk
FROM centos:7.9.2009
ADD jdk-8u321-linux-x64.tar.gz /usr/local/
ENV JAVA_HOME /usr/local/jdk1.8.0_321
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin
ENV LANG en_US.UTF-8
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN sh -c echo 'Asia/Shanghai' >/etc/timezone
```

jar 包镜像 Dockerfile

> 注意启动 jar 包的用户

```
FROM harbor.lingfannao.net:4436/common/openjdk:8-alpine-cts
WORKDIR /data
RUN addgroup -S -g 1200 spring && adduser -S -u 1200 -G spring spring
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
RUN chown -R spring.spring /data
USER spring:spring
LABEL del=true
ENV LANG en_US.UTF-8
```

doployment yaml 文件

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jew-cust
  namespace: test
  labels:
    app: jew-cust
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jew-cust
  template:
    metadata:
      labels:
        app: jew-cust
    spec:
      containers:
      - name: app
        image: harbor.lingfannao.net:4436/test/jew-cust:20220412152125 
        command: ['java', '-jar', '/data/app.jar', '--spring.profiles.active=test']
        ports:
        - containerPort: 9041
        readinessProbe:
          tcpSocket:
            port: 9041
          initialDelaySeconds: 15
          periodSeconds: 10
        livenessProbe:
          tcpSocket:
            port: 9041
          initialDelaySeconds: 15
          periodSeconds: 10        
        resources:
          requests:
            memory: "256Mi"
            cpu: "50m"
          limits:
            memory: "512Mi"
            cpu: "250m"
        volumeMounts:
        - mountPath: /data/logs/jew-customized
          name: jew-cust
      nodeSelector:
        kubernetes.io/hostname: hwy-test-01
      volumes:
      - name: jew-cust
        hostPath:
          path: /data/logs/jew-customized2
          type: Directory
      imagePullSecrets:
      - name: hwy-harbor
```

service yaml 文件

```yaml
piVersion: v1
kind: Service
metadata:
  name: jew-cust
  namespace: test
  labels:
    app: jew-cust
spec:
  type: NodePort
  ports:
    - port: 9041
      nodePort: 30010
  selector:
    app: jew-cust
```

