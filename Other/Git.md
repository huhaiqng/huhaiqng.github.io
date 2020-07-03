#### 记住 git 用户名和密码

```
# 执行下面的命令（如果不执行下面的命令，可能会导致设置无效）
git config --global user.email "你的git的注册邮箱"
git config --global user.user "你的git用户名"
# 长期存储密码
git config --global credential.helper store
```



#### 常见问题解决方法

##### .git 目录过大解决方法

> 产生原因: 提交了过大的文件
>
> 操作前提：删除所有的分支，只留下一个master

查看 .git 目录中前5的大文件

```
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -5 | awk '{print$1}')"
```

删除过大的文件

> filter-branch 命令可以用来重写Git仓库中的提交 
> --index-filter 参数用来指定一条Bash命令，然后Git会检出（checkout）所有的提交， 执行该命令，然后重新提交。 
> –all 参数表示我们需要重写所有分支（或引用）。 
> YOU-FILE-NAME 你查找出来的大文件名字

```
git filter-branch --force --prune-empty --index-filter 'git rm -rf --cached --ignore-unmatch "YOU-FILE-NAME"' --tag-name-filter cat -- --all
```



强制 push，回收空间

```
git push --force --all
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
```
