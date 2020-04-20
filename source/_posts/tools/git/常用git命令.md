# git命令

[链接](https://www.linuxidc.com/Linux/2018-04/151805.htm)

[TOC]

### Git拉取远程分支到本地
```
git checkout -b local_branch origin/remote_branch
```
### 重命名 
```
git branch -m oldBranchName newBranchName
```

### 恢复到远程分支的最新版本

```
git fetch --all 
git reset --hard origin/branch

#只是下载远程的库的内容，不做任何的合并git reset 把HEAD指向刚刚下载的最新的版本
```
