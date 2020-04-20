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