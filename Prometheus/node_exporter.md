部署
```
docker run -id --pid="host" -p 9100:9100 --name node_exporter -v "/:/host:ro,rslave" quay.io/prometheus/node-exporter:latest --path.rootfs=/host

```
在 promethues 配置文件中添加 job
```
  - job_name: 'node'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
 
    static_configs:
      - targets: ['localhost:9100']
```
