#### Jenkins 获取 Git Message

安装 Jenkins 插件 Git Changelog、Hudson Post build task

配置 Git Changelog 打包分支

![1562140442449](assets/1562140442449.png)

配置时区

![1562140476022](assets/1562140476022.png)

在工作空间生成获取 git 提交信息的文件

![1562140551346](assets/1562140551346.png)配置 Git Changelog

![1562140604523](assets/1562140604523.png)



#### 没有登陆的情况访问一个Jenkins URL 返回 404 ，没有跳转到登陆界面

##### 问题

当没有登陆Jenkins，直接在浏览器中输入一个Jenkins URL，例如：https://Jenkins:8080/job/sample_1/
 系统没有跳转到登陆界面提示用户登录，而是直接报告 HTTP 404。

**原因**
 这是由于 ‘Job Discover’ 的权限没有打开。
 如果你用 Role-based Authorization Strategy 插件， 在 [Jenkins]=>[Manage And Assign Role]=>[Manage and Assign Roles] 页面你会发现 Job 中有一个 ‘Discover’ 项目，选中它，就可以实现匿名用户访问 Jenkins URL 跳转到登陆界面。

Reference
 "Job DISCOVER" means
 "This permission grants discover access to jobs. Lower than read permissions, it allows you to redirect anonymous users to the login page when they try to access a job url. Without it they would get a 404 error and wouldnt be able to discover project names.

