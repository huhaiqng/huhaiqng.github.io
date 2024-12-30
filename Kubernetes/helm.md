#### 仓库 repo

添加仓库

> `bitnami`: 仓库名称

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

列出仓库

```
helm repo list
```

删除仓库

```
helm repo remove bitnami
```

列出仓库 `bitnami` 的 chart

```
helm search repo bitnami
```

更新仓库

```
helm repo update
```

#### chart

查看 chart `bitnami/mysql` 的基本信息

```
helm show chart bitnami/mysql
```

查看 chart `bitnami/mysql` 的详细信息

```
helm show all bitnami/mysql
```

仓库 chart `bitnami/wordpress` 的 values

```
helm show values bitnami/wordpress
```

指定名称部署 chart `bitnami/mysql`

```
helm install mysql bitnami/mysql
```

自动生成名称部署 chart `bitnami/mysql`

> --generate-name: 设定自动生成名称

```
helm install bitnami/mysql --generate-name
```

不同来源 chart 的安装

```
# 本地 chart 压缩包
helm install foo foo-0.1.1.tgz

# 解压后的 chart 目录
helm install foo path/to/foo

# 完整的 URL
helm install foo https://example.com/charts/foo-1.2.3.tgz
```

覆盖 values

```
helm install -f values.yaml bitnami/mysql --generate-name
helm install --set nodeSelector."kubernetes\.io/role"=master bitnami/mysql --generate-name
```

下载 chart

```
helm pull bitnami/wordpress
```

更新 chart

```
helm upgrade -f panda.yaml happy-panda bitnami/wordpress
```

仓库发布 chart 的 values

```
helm get values happy-panda
```

查看发布的 chart

```
helm list
```

查看全部的发布

```
helm list --all
```

卸载发布的 chart

```
helm uninstall mysql-1612624192
```

查看发布 chart 的状态

```
helm status mysql-1612624192
```

从 `Artifact Hub` 列出 chart

```
helm search hub wordpress
```

模糊查找 chart

```
helm search repo kash
```

