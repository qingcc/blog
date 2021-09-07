# Git 分支开发规范
> Git 是目前最流行的源代码管理工具。 为规范开发，保持代码提交记录以及 git 分支结构清晰，方便后续维护，现规范 git 的相关操作。

## 分支管理

### 主分支 master
主分支 master 主分支，所有提供给用户使用的正式版本，都在这个主分支上发布

- `master` 为主分支，也是用于部署生产环境的分支，确保`master`分支稳定性
- `master` 分支一般由`develop`以及`hotfix`分支合并，任何时间都不能直接修改代码

### 开发分支 develop
主分支只用来分布重大版本，日常开发应该在另一条分支上完成。我们把开发用的分支，叫做Develop。

这个分支可以用来生成代码的最新隔夜版本（`nightly`）。如果想正式对外发布，就在`Master`分支上，对`Develop`分支进行"合并"（`merge`）。
开发分支 `dev` 开发分支，永远是功能最新最全的分支

- `develop` 为开发分支，始终保持最新代码以及`bug`修复后的代码
- 一般开发的新功能时，`feature`分支都是基于`develop`分支下创建的

### 临时性分支
前面讲到版本库的两条主要分支：`Master` 和 `Develop`。前者用于正式发布，后者用于日常开发。其实，常设分支只需要这两条就够了，不需要其他了。

但是，除了常设分支以外，还有一些临时性分支，用于应对一些特定目的的版本开发。临时性分支主要有三种：

* 功能（`feature`）分支
* 预发布（`release`）分支
* 修补bug（`fixbug`）分支

这三种分支都属于临时性需要，使用完以后，应该删除，使得代码库的常设分支始终只有 `Master` 和 `Develop`。

#### 功能分支 feature
接下来，一个个来看这三种"临时性分支"。  
第一种是功能分支，它是为了开发某种特定功能，从Develop分支上面分出来的。开发完成后，要再并入Develop。
功能分支的名字，可以采用feature-*的形式命名。

创建一个功能分支：
```shell
git checkout -b feature-x develop
```
开发完成后，将功能分支合并到develop分支：
```shell
git checkout develop
git merge --no-ff feature-x
```
>`--no-ff`  
默认情况下，Git执行”快进式合并”（fast-farward merge），会直接将 `Master` 分支指向 `Dev` 分支。
使用 `–no–ff` 参数后，会执行正常合并，在 `Master` 分支上生成一个新节点。为了保证版本演进的清晰，我们希望采用这种做法。

删除feature分支：
```shell
git branch -d feature-x
```

#### 预发布分支 release
第二种是预发布分支，它是指发布正式版本之前（即合并到 `Master` 分支之前），我们可能需要有一个预发布的版本进行测试。

预发布分支是从 `Develop` 分支上面分出来的，预发布结束以后，必须合并进 `Develop` 和 `Master` 分支。它的命名，可以采用 `release-*` 的形式。

创建一个预发布分支：
```shell
git checkout -b release-1.2 develop
```
确认没有问题后，合并到 `master` 分支：
```shell
git checkout master
git merge --no-ff release-1.2
# 对合并生成的新节点，做一个标签
git tag -a 1.2
```
再合并到 `develop` 分支：
```shell
git checkout develop
git merge --no-ff release-1.2
```
最后，删除预发布分支：
```shell
git branch -d release-1.2
```

#### 修补bug分支 hotfix
最后一种是修补 `bug` 分支。软件正式发布以后，难免会出现 `bug`。这时就需要创建一个分支，进行`bug`修补。

修补`bug`分支是从`Master`分支上面分出来的。修补结束以后，再合并进`Master`和`Develop`分支。它的命名，可以采用`hotfix-*`的形式

- 分支命名: `hotfix-` 开头的为修复分支，它的命名规则与 `feature` 分支类似
- 线上出现紧急问题时，需要及时修复，以`master`分支为基线，创建`hotfix`分支，修复完成后，需要合并到`master`分支和`develop`分支

## git commit 规范指南
>在一个团队协作的项目中，开发人员需要经常提交一些代码去修复bug或者实现新的feature。而项目中的文件和实现什么功能、解决什么问题都会渐渐淡忘，
> 最后需要浪费时间去阅读代码。但是好的日志规范commit messages编写有帮助到我们，它也反映了一个开发人员是否是良好的协作者。

目前，社区有多种 `Commit message` 的写法规范。`Angular` 规范是目前使用最广的写法，比较合理和系统化，并且有配套的工具。前前端框架`Angular.js`采用的就是该规范

### Commit message 的作用
- 提供更多的历史信息，方便快速浏览。
```shell
git log <last tag> HEAD --pretty=format:%s
```
- 可以过滤某些commit（比如文档改动），便于快速查找信息
```shell
git log <last release> HEAD --grep feature
```
- 可以直接从commit生成Change log
- 可读性好，清晰，不必深入看代码即可了解当前commit的作用。
- 为 Code Reviewing做准备
- 方便跟踪工程历史
- 让其他的开发者在运行 git blame 的时候想跪谢
- 提高项目的整体质量，提高个人工程素质

### Commit message 的格式
每次提交，`Commit message` 都包括三个部分：`header`，`body` 和 `footer`。
```shell
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```
其中，`header` 是必需的，`body` 和 `footer` 可以省略。
不管是哪一个部分，任何一行都不得超过72个字符（或100个字符）。这是为了避免自动换行影响美观。

#### Header
`Header` 部分只有一行，包括三个字段：`type`（必需）、`scope`（可选）和 `subject`（必需）。

+ type  
用于说明 commit 的类别，只允许使用下面7个标识。
    - feat：新功能（feature）
    - fix：修补bug
    - docs：文档（documentation）
    - style： 格式（不影响代码运行的变动）
    - refactor：重构（即不是新增功能，也不是修改bug的代码变动）
    - test：增加测试
    - chore：构建过程或辅助工具的变动

如果`type`为`feat`和`fix`，则该 `commit` 将肯定出现在 `Change log` 之中。其他情况（`docs`、`chore`、`style`、`refactor`、`test`）由你决定，
要不要放入 `Change log`，建议是不要。

+ scope  
scope用于说明 commit 影响的范围，比如数据层、控制层、视图层等等，视项目不同而不同。

例如在`Angular`，可以是`$location`, `$browser`, `$compile`, `$rootScope`, `ngHref`, `ngClick`, `ngView`等。

如果你的修改影响了不止一个`scope`，你可以使用`*`代替。

+ subject  
`subject` 是 `commit` 目的的简短描述，不超过50个字符。  
其他注意事项：
    - 以动词开头，使用第一人称现在时，比如change，而不是changed或changes
    - 第一个字母小写
    - 结尾不加句号（.）

+ Body  
`Body` 部分是对本次 `commit` 的详细描述，可以分成多行。下面是一个范例。
```shell
More detailed explanatory text, if necessary.  Wrap it to
about 72 characters or so.

Further paragraphs come after blank lines.

- Bullet points are okay, too
- Use a hanging indent
```
有两个注意点:  
    - 使用第一人称现在时，比如使用change而不是changed或changes。  
    - 永远别忘了第2行是空行

应该说明代码变动的动机，以及与以前行为的对比。

+ Footer  
Footer 部分只用于以下两种情况：

- 不兼容变动
如果当前代码与上一个版本不兼容，则 Footer 部分以BREAKING CHANGE开头，后面是对变动的描述、以及变动理由和迁移方法。    
```shell
BREAKING CHANGE: isolate scope bindings definition has changed.

    To migrate the code follow the example below:

    Before:

    scope: {
      myAttr: 'attribute',
    }

    After:

    scope: {
      myAttr: '@',
    }

    The removed `inject` wasn't generaly useful for directives so there should be no code using it.
```

#### Revert
还有一种特殊情况，如果当前 `commit` 用于撤销以前的 `commit`，则必须以`revert:`开头，后面跟着被撤销 `Commit` 的 `Header`。
```shell
revert: feat(pencil): add 'graphiteWidth' option

This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
```
`Body`部分的格式是固定的，必须写成`This reverts commit <hash>.`其中的 `hash` 是被撤销 `commit` 的 `SHA` 标识符。

如果当前 `commit` 与被撤销的 `commit`，在同一个发布（`release`）里面，那么它们都不会出现在 `Change log` 里面。如果两者在不同的发布，那么当前 `commit`，会出现在 `Change log` 的`Reverts`小标题下面。

[Git分支管理策略](http://www.ruanyifeng.com/blog/2012/07/git.html)
[git commit 规范指南](https://www.ruanyifeng.com/blog/2016/01/commit_message_change_log.html)  
