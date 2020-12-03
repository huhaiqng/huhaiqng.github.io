#### 发布流程图

![image-20201126140040449](Java 微服务架构发布方案(docker-compose).assets/image-20201126140040449.png)

#### 服务器信息

> SERVER-A 与 SERVER-B、SERVER-C 之间 SSH 免密

私有云

- SERVER-A 192.168.1.10: 部署 gitlab, jenkins

公有云

- SERVER-B 172.16.1.10: 部署 maven, harbor
- SERVER-C 172.16.1.21: 部署项目A
- SERVER-D 172.16.1.22: 部署项目B