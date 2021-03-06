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


`git reflog` 是整个本地仓库的最近提交，包括所有分支。

### 修改上一次 `commit` 的提交信息 

```
使用一次新的commit，替代上一次提交
# 如果代码没有任何新变化，则用来改写上一次commit的提交信息
$ git commit --amend -m [message]

# 重做上一次commit，并包括指定文件的新变化
$ git commit --amend [file1] [file2] ...
```


### 选择一个`commit`，合并进当前分支

```

# 选择一个commit，合并进当前分支
$ git cherry-pick [commit]

```

### win下修改文件的权限并提交

```
#git 查看文件权限
git ls-tree HEAD

#git 修改文件权限
git update-index --chmod=+x build.sh

#修改之后git add & git commit之后，再次查看
git ls-tree HEAD

#会发现由100644变为100755，已经有执行查找权限了，推送
git push
```

## git merge 将另一分支上多条commit合并成1条merge到目标分支

```
git merge --squash branchname
```

注意：使用该命令的标准是， 待合并分支上的历史是否有意义