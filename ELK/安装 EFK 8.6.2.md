##### 安装 elasticsearch-8.6.2

配置 yum 源 es.repo

```
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=0
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

安装

```
yum install -y elasticsearch
```

记录安装输出信息

```
--------------------------- Security autoconfiguration information ------------------------------

Authentication and authorization are enabled.
TLS for the transport and HTTP layers is enabled and configured.

The generated password for the elastic built-in superuser is : KggwDV4vLdVr9wPZ2voP

If this node should join an existing cluster, you can reconfigure this with
'/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <token-here>'
after creating an enrollment token on your existing cluster.

You can complete the following actions at any time:

Reset the password of the elastic built-in superuser with 
'/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic'.

Generate an enrollment token for Kibana instances with 
 '/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana'.

Generate an enrollment token for Elasticsearch nodes with 
'/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node'.
```

启动

```
systemctl start elasticsearch
```



##### 安装 kibana-8.6.2

配置 yum 源 kibana.yml

```
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=0
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

安装

```
yum install -y kibana
```

修改配置文件

```
server.host: 0.0.0.0
```

启动

```
systemctl start kibana
```

浏览器打开 http://kibana_host_ip:5601，按提示设置。



##### 安装 filebeat-8.6.2

下载安装

```
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.6.2-x86_64.rpm
rpm -vi filebeat-8.6.2-x86_64.rpm
```

查看 ca_trusted_fingerprint

> ca_trusted_fingerprint 也可以在 kibana 文件中查看

```
openssl x509 -fingerprint -sha256 -in /etc/elasticsearch/certs/http_ca.crt | grep Fingerprint | tr '[A-Z]' '[a-z]' | sed 's/://g'
```

修改配置文件

```
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  index: "filebeat-%{[event.module]}-%{[fileset.name]}-%{+yyyy.MM.dd}"
  username: "elastic"
  password: "KggwDV4vLdVr9wPZ2voP"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "7e00ab52e13cc5a3eefac40ea47a09a809dba93f1dd49a658655db3ffb53d44e"
setup.template.name: "filebeat"
setup.template.pattern: "filebeat"
```

启动

```
systemctl start filebeat
```

