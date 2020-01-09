---
title: 常用git命令
date: 2019-12-25 19:52:20
type: "about"
tags: [git]
---
# 常用git命令

[TOC]

## 放弃本地修改
1. 修改且未`git add`到暂存区，放弃修改
```
#单个文件/文件夹
git checkout -- filename

#所有文件/文件夹
git checkout .
```
<!-- more -->
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

## 合并多次提交
在分支中多次提交，最后合并到master分支时，会展示所有的增量修改历史。我们的改动应该就是增加或者删除，给别人看开发过程的增量反而太乱。于是我们可以将分支的提交合并后然后再merge到主干这样看起来就清爽多了。
### rebase命令
rebase的作用简要概括为：可以对某一段线性提交历史进行编辑、删除、复制、粘贴；因此，合理使用rebase命令可以使我们的提交历史干净、简洁！

但是需要注意的是：

<font color="#dd0000">不要通过rebase对任何已经提交到公共仓库中的commit进行修改</font>（你自己一个人玩的分支除外）<br /> 


```
git rebase -i  [startpoint]  [endpoint]
```
其中`-i`的意思是`--interactive`，即弹出交互式的界面让用户编辑完成合并操作，`[startpoint]` `[endpoint]`则指定了一个编辑区间，如果不指定`[endpoint]`，则该区间的终点默认是当前分支HEAD所指向的commit(注：该区间指定的是一个前开后闭的区间)。 在查看到了log日志后，我们运行以下命令：
```
git rebase -i 36224db

#or
git rebase -i HEAD~3 
```
然后我们会看到如下界面:
```
pick 4750fd0 fix: 合并提交
pick 4778d21 commit 4
pick 28b2f50 commit 5
pick 03a1f8c commit 6

# Rebase f0ba60b..03a1f8c onto 03a1f8c (4 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
# .       create a merge commit using the original merge commit's
# .       message (or the oneline, if no original merge commit was
# .       specified). Use -c <commit> to reword the commit message.
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out

```
上面未被注释的部分列出的是我们本次rebase操作包含的所有提交，下面注释部分是git为我们提供的命令说明。每一个commit id 前面的pick表示指令类型，git 为我们提供了以下几个命令:

> pick：保留该commit（缩写:p）
> 
> reword：保留该commit，但我需要修改该commit的注释（缩写:r）
> 
> edit：保留该commit, 但我要停下来修改该提交(不仅仅修改注释)（缩写:e）
> 
> squash：将该commit和前一个commit合并（缩写:s）
> 
> fixup：将该commit和前一个commit合并，但我不要保留该提交的注释信息（缩写:f）
> 
> exec：执行shell命令（缩写:x）
> 
> drop：我要丢弃该commit（缩写:d）

commit合并之前的log日志：
```
$ git log --oneline
03a1f8 (HEAD -> dev) commit 6
28b2f5 commit 5
4778d2 commit 4
4750fd fix: 合并提交
```
运行命令, 将4条commit的信息合并为1条：
```
git rebase -i HEAD~4
```
根据需要，修改commit：
> pick 4750fd0 fix: 合并提交
> 
> s 4778d21 commit 4
> 
> s 28b2f50 commit 5
> 
> s 03a1f8c commit 6

上面的意思就是把第二次、第三次提交都合并到第一次提交上

保存退出后是注释修改界面:
```
# This is a combination of 4 commits.
# This is the 1st commit message:

fix: 合并提交

# This is the commit message #2:

commit 4

# This is the commit message #3:

commit 5

# This is the commit message #4:

commit 6

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# Date:      Thu Jan 9 10:30:32 2020 +0800
#
# interactive rebase in progress; onto f0ba60b
# Last commands done (4 commands done):
#    squash 28b2f50 commit 5
#    squash 03a1f8c commit 6
# No commands remaining.
# You are currently rebasing branch 'dev' on 'f0ba60b'.
#
# Changes to be committed:
#       modified:   README.md
#
```

编辑未注释内容，保存即可完成commit的合并了（如：fix:合并提交）。保存之后的信息提示：
```
$ git rebase -i HEAD~4
[detached HEAD 8bef24a] fix: 合并提交
 Date: Thu Jan 9 10:30:32 2020 +0800
 1 file changed, 10 insertions(+), 2 deletions(-)
Successfully rebased and updated refs/heads/dev.
```
最后log查看：
```
$ git log --oneline
8bef24a (HEAD -> dev) fix: 合并提交
f0ba60b (origin/master, origin/HEAD, master) git rollback test 2
c6791b5 git rollback test 1
```
合并到主分支：
```
git checkout master
git merge dev
```
查看主分支合并之后的日志：
```
$ git log --oneline
8bef24a (HEAD -> master, dev) fix: 合并提交
f0ba60b (origin/master, origin/HEAD) git rollback test 2
c6791b5 git rollback test 1
```
可以看到，主分支合并之后只有1条记录，而不是dev分支之前的4次commit日志记录。在开发中比较实用，例如：在分支测试之后，分支会有大量的测试提交日志，但主分支并不需要查看这些日志，只需要一条记录最终修改好的已通过测试的日志。

rebase命令适合本地独自开发的分支合并commit，当协同开发时需要慎用。

参考博客：[rebase](https://juejin.im/entry/5ae9706d51882567327809d0)