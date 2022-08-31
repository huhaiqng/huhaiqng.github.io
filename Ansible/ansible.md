### 安装

配置阿里 epel 源

```
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

安装 ansible

```
yum install -y ansible
```

### 配置主机和组

在主机文件 /etc/ansible/hosts  中添加主机和组

```
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com ansible_ssh_port=88
two.example.com ansible_ssh_user=webuser ansible_ssh_pass=password
three.example.com
```

主机的常用参数

```
ansible_ssh_port
# ssh端口号.如果不是默认的端口号,通过此变量设置.
ansible_ssh_user
# 默认的 ssh 用户名
ansible_ssh_pass
# ssh 密码(这种方式并不安全,我们强烈建议使用 --ask-pass 或 SSH 密钥)
ansible_ssh_private_key_file
# ssh 使用的私钥文件.适用于有多个密钥,而你不想使用 SSH 代理的情况.
```

### 常用命令

检查所有主机是否在线

```
ansible all -m ping
```

在远程主机执行 shell 命令

```
ansible webservers -m shell -a 'hostname'
```

### 实例

```
some_host         ansible_ssh_port=2222     ansible_ssh_user=manager
aws_host          ansible_ssh_private_key_file=/home/example/.ssh/aws.pem
freebsd_host      ansible_python_interpreter=/usr/local/bin/python
ruby_module_host  ansible_ruby_interpreter=/usr/bin/ruby.1.9.3
```

### 常见问题

#### 无法连接远程主机

使用用户名密码连接远程主机，报以下错误

```
Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host.
```

处理方法，在配置文件中取消以下注释

```
host_key_checking = False
```

