##### 服务端客户端准备程序文件

> windows 下载: https://github.com/fatedier/frp/releases/download/v0.37.1/frp_0.37.1_windows_amd64.zip

```shell
wget https://github.com/fatedier/frp/releases/download/v0.37.1/frp_0.37.1_linux_amd64.tar.gz
tar zxvf frp_0.37.1_linux_amd64.tar.gz
mv frp_0.37.1_linux_amd64 frp
```

##### 服务端配置文件 `frps.ini`

> 服务端需要公网 IP

```
[common]
bind_port = 7000
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = A4Pul92AKIOY
authentication_method = token
token = 0dcf22c6-5c92-4dd3-b517-43af475ee665
allow_ports = 2000-2010
max_pool_count = 10
```

##### 启动服务端

> 监控查看地址: http://server_ip:7500

```
./frps -c ./frps.ini
```

##### 客户端配置文件 `frpc.ini`

```.
[common]
server_addr = x.x.x.x
server_port = 7000
authentication_method = token
token = 0dcf22c6-5c92-4dd3-b517-43af475ee665
admin_addr = 0.0.0.0
admin_port = 7400
admin_user = admin
admin_pwd = oZAS07zI

[ssh]
type = tcp
local_ip = 192.168.1.11
local_port = 22
remote_port = 2000
use_encryption = true
use_compression = true

[web]
type = tcp
local_ip = 192.168.1.12
local_port = 80
remote_port = 2002
use_encryption = true
use_compression = true

[mysql]
type = tcp
local_ip = 192.168.1.13
local_port = 3306
remote_port = 2003
use_encryption = true
use_compression = true
```

##### 启动客户端

> 客户端配置地址: http://client_ip:7400

```
./frpc -c ./frpc.ini 
```



##### 说明：服务端可能结合 nginx 方向代理实现 web 穿透