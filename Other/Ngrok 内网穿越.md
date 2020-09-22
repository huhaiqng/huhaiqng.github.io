##### Ngrok 服务器端

部署服务器: jpark-elk

部署路径：/usr/local/ngrok

启动命令

```
nohup /usr/local/ngrok/ngrokd -domain="zhubaogongyuan.cn" -httpAddr=":888" -httpsAddr=":999" -tunnelAddr=":4443" -tlsCrt="/usr/local/ngrok/snakeoil.crt" -tlsKey="/usr/local/ngrok/snakeoil.key" -log="none" -log-level="ERROR" >/dev/null 2>&1 &
```

##### Ngrok 客户端

部署服务器: eolk-chandao

部署路径: /data/ngrok

配置文件 config/domain.cfg

```
server_addr: "zhubaogongyuan.cn:4443"
trust_host_root_certs: false

tunnels:
    jf:
        subdomain: "jf"
        proto:
            http: "192.168.40.159:80"
    lfn-sms:
        subdomain: "sms"
        proto:
            http: "192.168.40.70:8060"
    jpark-dev-b:
        subdomain: "jpark-dev-b"
        proto:
            http: "192.168.40.56:8080"
```

配置文件 config/rdp.cfg 

```
server_addr: "zhubaogongyuan.cn:4443"
trust_host_root_certs: false

tunnels:
    zhangyanlin:
         remote_port: 20101
         proto:
             tcp: "192.168.40.58:3389"
```

配置文件 config/ssh.cfg

```
server_addr: "zhubaogongyuan.cn:4443"
trust_host_root_certs: false

tunnels:
    159:
         remote_port: 20001
         proto:
             tcp: "192.168.40.159:22"
    9:
         remote_port: 20002
         proto:
             tcp: "192.168.40.9:22"
    185:
         remote_port: 20003
         proto:
             tcp: "192.168.40.185:22"
    79:
         remote_port: 20004
         proto:
             tcp: "192.168.40.79:22"
    56:
         remote_port: 20005
         proto:
             tcp: "192.168.40.56:22"
```

启动命令

```
nohup ./ngrok -log=log -log-level=ERROR -config=CONFIG_FILE start-all >/dev/null 2>&1 &
```

