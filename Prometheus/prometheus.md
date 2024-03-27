安装
```
cd /opt
wget wget https://github.com/prometheus/prometheus/releases/download/v2.45.4/prometheus-2.45.4.linux-amd64.tar.gz
gzip -d prometheus-2.45.4.linux-amd64.tar.gz
tar xf prometheus-2.45.4.linux-amd64.tar
mv prometheus-2.45.4.linux-amd64/ prometheus
useradd -s /sbin/nologin prometheus
chown -R prometheus.prometheus prometheus/
```
启动
```
nohup /opt/prometheus/prometheus --config.file=prometheus.yml >/dev/null 2>&1 &
```
