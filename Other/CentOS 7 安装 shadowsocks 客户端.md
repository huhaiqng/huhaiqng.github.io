参考文档：[CentOS 7 安装 shadowsocks 客户端](https://brickyang.github.io/2017/01/14/CentOS-7-%E5%AE%89%E8%A3%85-Shadowsocks-%E5%AE%A2%E6%88%B7%E7%AB%AF/)

安装 pip

```
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
```

安装 Shadowsocks 客户端

```
pip install --upgrade pip
pip install shadowsocks
```

新建 Shadowsocks 配置文件 

```
# cat /etc/shadowsocks.json 
{
  "server":"162.245.239.66",            
  "server_port":34567,                
  "local_address": "127.0.0.1",  
  "local_port":1985,                 
  "password":"dongtaiwang.com",        
  "timeout":300,                  
  "method":"aes-256-cfb",        
  "workers": 1                   
}
```

启动 Shadowsocks

```
nohup sslocal -c /etc/shadowsocks.json /dev/null 2>&1 &
```

运行 curl --socks5 127.0.0.1:1985 http://httpbin.org/ip，如果返回你的 ss 服务器 ip 则测试成功

```
{
  "origin": "x.x.x.x"       #你的 ss 服务器 ip
}
```

安装 Privoxy

```
wget http://www.privoxy.org/sf-download-mirror/Sources/3.0.28%20%28stable%29/privoxy-3.0.28-stable-src.tar.gz
tar -zxvf privoxy-3.0.28-stable-src.tar.gz
cd privoxy-3.0.28-stable
useradd privoxy
yum install autoconf automake libtool
autoheader && autoconf
./configure
make && make install
```

修改配置文件 /usr/local/etc/privoxy/config

```
forward-socks5t / 127.0.0.1:1985 .
```

启动

```
privoxy --user privoxy /usr/local/etc/privoxy/config
```

启用代理

```
export http_proxy=http://127.0.0.1:8118      
export https_proxy=http://127.0.0.1:8118
```

测试

```
curl -I www.google.com
```