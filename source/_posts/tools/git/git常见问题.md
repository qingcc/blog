# git出现Your branch and 'origin/master' have diverged解决方法
如果不需要保留本地的修改，只要执行下面两步：
```
git fetch origin
git reset --hard origin/master
```
当我们在本地提交到远程仓库的时候，如果遇到上述问题，我们可以首先使用如下命令：
```
git rebase origin/master
```
然后使用
```
git pull --rebase
```
最后使用
```
git push origin master
```
把内容提交到远程仓库上。

`windows`下 `git`操作时，我的`go.mod`文件没有修改，为什么git老是提示是修改状态呢？
这个问题一般出现在`windows`系统上，是换行符导致(类`Unix`系统一般使用`LF`换行符，`windows`系统使用`CRLF`换行符，
而`go.mod`文件一般是使用`LF`换行符，`windows`系统上`git`默认会将`LF`换行符转换成`CRLF`换行符)。
解决方法：在项目根目录下添加或更新`.gitattributes`文件，写入这样语句：

```
go.mod text eol=lf
```