##### 使用容器部署 consul

拉取镜像

```
docker pull consul
```

创建启动容器(dev 模式)

> --network 指定与微服务同一网络

```
docker run -id --name micro-consul -h micro-consul -p 8500:8500 --network micro -e 'CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' consul agent -dev -ui -client=0.0.0.0 -bind=0.0.0.0 -datacenter=dc
```

注册测试服务

```
curl -X PUT -d '{"id": "jetty","name": "jetty","address": "192.168.1.200","port": 8080,"tags": ["dev"],"checks": [{"http": "http://192.168.1.104:9020/health","interval": "5s"}]}' http://192.168.1.100:8500/v1/agent/service/register
```

通过 ui 访问地址 http://ip:8500/ui 查看注册的服务