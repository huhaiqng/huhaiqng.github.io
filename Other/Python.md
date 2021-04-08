#### 创建虚拟环境

确定要放置它的目录，并将 [`venv`](https://docs.python.org/zh-cn/3/library/venv.html#module-venv) 模块作为脚本运行目录路径

> python3.3  之前的版本没有这个功能
>
> tutorial-env 为虚拟环境的目录

```
python3 -m venv tutorial-env
```

在 Windows 上激活

```
tutorial-env\Scripts\activate.bat
```

在 Linux 或 MacOS 上激活

```
source tutorial-env/bin/activate
```



#### pip 命令

安装最新版本的包

```
pip install novas
```

安装指定版本的包

```
pip install requests==2.6.0
```

升级 pip 

```
pip install --upgrade pip
```

显示虚拟环境中安装的所有软件包

```
pip list
```

显示有关特定包的信息

```
pip show requests
```

生成一个已安装包列表

```
pip freeze > requirements.txt
```

从 requirements.txt 安装所需要的包

```
pip install -r requirements.txt
```

