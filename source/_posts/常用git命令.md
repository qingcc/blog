# 常用git命令

## 放弃本地修改
1. 修改且未`git add`到暂存区，放弃修改
```
#单个文件/文件夹
git checkout -- filename

#所有文件/文件夹
git checkout .
```

2. 新增且未`git add`到暂存区，放弃修改
```
#单个文件/文件夹
rm filename / rm dir -rf

#所有文件/文件夹
git clean -xdf
```

3. 已经`git add`到暂存区，放弃修改
```
#单个文件/文件夹
git reset HEAD filename

#所有文件/文件夹
git reset HEAD .
```

4. `git add` & `git commit` 之后，想要撤销此次commit

这个id是你想要回到的那个节点，可以通过git log查看，可以只选前6位
```
#撤销之后，你所做的已经commit的修改还在工作区！
git reset commit_id

#撤销之后，你所做的已经commit的修改将会清除，仍在工作区/暂存区的代码也将会清除！
git reset --hard commit_id
```

## 回滚
1. 使用revert
```
#删除最后一次远程提交（本地的working tree），且生成1次新的提交（内容回到上次提交）
git revert HEAD

#回退之后(内容回退了，历史记录都存在，且新增了1条记录)，还需要push
git push
```

2. 使用reset

把HEAD指针从指向当前commit_id改为指向上一个版本（版本信息丢存在，只是改变指针指向，远程的git HEAD还是指向最新的版本，此时只是将本地的版本回退，若修改，则需要先拉取，解决冲突，再推送到远端。（若有错误的提交，需要回退，且之后需要在回退的版本上提交，则需要使用`revert`来回滚
```
git reset --hard HEAD^

#-f 为强制推送
git push origin master -f
```