生成证书

```
git clone https://github.com/rabbitmq/tls-gen tls-gen
cd tls-gen/basic
# private key password
make PASSWORD=bunnies
make verify
make info
ls -l ./result
cp -R ./result /data/rabbitmq/ssl
chown -R rabbitmq.rabbitmq /data/rabbitmq/ssl
```

创建配置文件 /etc/rabbitmq/rabbitmq.conf

```
listeners.ssl.default = 5671

ssl_options.cacertfile = /data/rabbitmq/ssl/ca_certificate.pem
ssl_options.certfile   = /data/rabbitmq/ssl/server_rabbitmq_certificate.pem
ssl_options.keyfile    = /data/rabbitmq/ssl/server_rabbitmq_key.pem
ssl_options.verify     = verify_peer
ssl_options.fail_if_no_peer_cert = true
ssl_options.password   = bunnies
```

重启

```
systemctl restart rabbitmq-server
```

java 客户端导入证书

```
keytool -import -alias server1 -file /data/rabbitmq/ssl/server_rabbitmq_certificate.pem -keystore rabbitmqTrustStore
```

springboot 配置文件

> 目录相对于 resources

```
spring:
  rabbitmq:
    host: rbmq.lflogistics.net
    port: 5671
    username: rabbitmq
    password: rabbitmq
    ssl:
      enabled: true
      key-store: classpath:ssl/client_rabbitmq.p12
      trust-store: classpath:ssl/rabbitmqTrustStore
      key-store-password: bunnies
      trust-store-password: changeit
      verify-hostname: false
      trust-store-type: JKS
    virtual-host: /
    publisher-confirm-type: correlated
```

参考文档:

https://www.rabbitmq.com/ssl.html#java-client

http://www.codebaoku.com/it-java/it-java-234011.html#:~:text=RabbitMQ%20%E5%BC%80%E5%90%AFSSL%E4%B8%8ESpringBoot%E8%BF%9E%E6%8E%A5%E7%9A%84%E9%85%8D%E7%BD%AE%E6%96%B9%E6%B3%95%20%E8%BF%91%E6%9C%9F%E5%85%AC%E5%8F%B8%E7%A8%8B%E5%BA%8F%E8%A2%AB%E5%AE%89%E5%85%A8%E6%89%AB%E6%8F%8F%E5%87%BA%20%E8%BF%9C%E7%A8%8B%E4%B8%BB%E6%9C%BA%E5%85%81%E8%AE%B8%E6%98%8E%E6%96%87%E8%BA%AB%E4%BB%BD%E9%AA%8C%E8%AF%81%20%E4%B8%AD%E9%A3%8E%E9%99%A9%E6%BC%8F%E6%B4%9E%EF%BC%8C%E6%9F%A5%E4%BA%86%E4%B8%8B%E4%BF%AE%E5%A4%8D%E6%96%B9%E6%A1%88%EF%BC%8CRabbitMQ%E5%AE%98%E6%96%B9%E6%8F%90%E4%BE%9B%E4%BA%86SSL%E8%BF%9E%E6%8E%A5%E6%96%B9%E5%BC%8F%EF%BC%8C%E8%80%8C%E4%B8%94%20SpringBoot%20AMQP,%E4%B9%9F%E6%94%AF%E6%8C%81%20SSL%20%E8%BF%9E%E6%8E%A5%E3%80%82%20%E4%BB%A5%E4%B8%8B%E5%B0%86%E9%85%8D%E7%BD%AERabbitMQ%E5%BC%80%E5%90%AFSSL%20%E5%B9%B6%E4%BD%BF%E7%94%A8%20SpringBoot%20Demo%20%E6%B5%8B%E8%AF%95%E8%BF%9E%E6%8E%A5%E3%80%82