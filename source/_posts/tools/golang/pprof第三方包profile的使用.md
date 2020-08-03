[原文链接](https://www.jianshu.com/p/043533eec401)

[TOC]

## 简介
`Golang` 内置 `cpu` 、`mem` 、`block` 三种 `profiler` 采样工具，允许程序在运行时使用 `profiler` 进行数据采样，生成采样文件。通过 
`go tool pprof` 工具可以交互式分析采样文件，得到高可读性的输出信息，帮助开发者快速分析及定位各种性能问题，如 `CPU` 消耗、内存分配及阻塞分析。

## 数据采样

### 1. 安装第三方性能分析来分析代码包

`runtime.pprof` 提供基础的运行时分析的驱动，但是这套接口使用起来还不是太方便，例如：输出数据使用 `io.Writer` 接口，虽然扩展性很强，但是对于实际使用不够方便，不支持写入文件，默认配置项较为复杂。

很多第三方的包在系统包 `runtime.pprof` 的技术上进行便利性封装，让整个测试过程更为方便。这里使用 `github.com/pkg/profile` 包进行例子展示，使用下面代码安装这个包：

```
$ go get github.com/pkg/profile
```

### 2. 增加性能分析代码

引入 github.com/pkg/profile 包，在需要测试的程序代码前面加入下面代码：
```
import(
    "github.com/pkg/profile"
    ...
)

func Pprof2File(f func())  {
	stopper := profile.Start(profile.CPUProfile, profile.ProfilePath("."))// 开始性能分析, 返回一个停止接口
	defer stopper.Stop()    // 在被测试程序结束时停止性能分析
	f()
}
```

使用 `profile.Start` 调用 `github.com/pkg/profile` 包的开启性能分析接口。这个 `Start` 函数的参数都是可选项，这里需要指定的分析项目是 `profile.CPUProfile`，也就是 `CPU` 耗用。如果分析内存分配情况，则所传参数改为 `profile.MemProfile`。

`profile.ProfilePath(".")`指定输出的分析文件路径，这里指定为当前文件夹。`profile.Start()` 函数会返回一个 `Stop` 接口，方便在程序结束时结束性能分析。

为了保证性能分析数据的合理性，分析的最短时间是 1 秒，使用 `time.Sleep()` 在程序结束前等待 1 秒。如果你的程序默认可以运行 1 秒以上，这个等待可以去掉。

### 3. 执行生成概要文件

性能分析需要可执行配合才能生成分析结果，因此使用命令行对程序进行编译，代码如下：

```
 go build -o cpu cpu.go
 ./cpu
```

第 1 行将 `cpu.go` 编译为可执行文件 `cpu`，第 2 行运行可执行文件，在当前目录输出 `cpu.pprof` 文件，即 `CPU` 概要文件，用于后面分析。

## 性能分析

### 1. 安装第三方图形化显式分析数据工具（Graphviz）

`go pprof` 工具链配合 `Graphviz` 图形化工具可以将 `runtime.pprof` 包生成的数据转换为 `PDF` 格式，以图片的方式展示程序的性能分析结果。安装 `graphviz` 软件包，在 `ubuntu` 系统可以使用下面的命令：

```
sudo apt-get install -y graphviz
```

> NOTE：`Windows` 下安装完后需将 [`Graphviz`](https://graphviz.gitlab.io/_pages/Download/Download_windows.html) 的可执行目录添加到环境变量 `PATH` 中。

### 2. 分析概要文件

现在准备工作做好了，我们目前生成了 `cpu` 二进制可执行文件，`cpu_profile` 性能分析需要的 `cpu.pprof`，接下来我们要正式进入 `cpu.pprof` 进行分析了。

`go tool pprof cpu cpu_pprof` 执行这个命令就进入了 `profile` 文件了，这时候我们已经可以开始分析代码了。输入 `help` ，可以查看都支持哪些操作，有很多命令可以根据需要进行选择，我们只介绍4个我自己比较喜欢用的命令 `web` ，`top`，`peek`，`list`。

`*web ------` 在交互模式下输入 `web` ，就能自动生成一个 `.svg` 文件，并跳转到浏览器打开，生成了一个函数调用图（需要安装`graphviz`），如下图：

![Image](https://upload-images.jianshu.io/upload_images/13986876-30333a08f242abb2.png?imageMogr2/auto-orient/strip|imageView2/2/w/735/format/webp)

> NOTE：获取的 `Profiling` 数据是动态的，要想获得有效的数据，请保证应用处于较大的负载（比如正在生成中运行的服务，或者通过其他工具模拟访问压力）。否则如果应用处于空闲状态，得到的结果可能没有任何意义。

输入 web 命令回车后自动打开浏览器出现如下内容：

![Image](https://upload-images.jianshu.io/upload_images/13986876-6504e1229e657d69.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

这个调用图包含了更多的信息，而且可视化的图像能让我们更清楚地理解整个应用程序的全貌。图中每个方框对应一个函数，方框越大代表执行的时间越久（包括它调用的子函数执行时间，但并不是正比的关系）；方框之间的箭头代表着调用关系，箭头上的数字代表被调用函数的执行时间。

`*top ------` 在交互模式下输入 `topN`，`N`为可选整形数值，指列出前 `N` 个最耗时的操作：

![Image](https://upload-images.jianshu.io/upload_images/13986876-0ec63c4e66fa5d43.png?imageMogr2/auto-orient/strip|imageView2/2/w/700/format/webp)

每一行表示一个函数的信息。

前两列表示函数在 `CPU` 上运行的时间以及百分比；

第三列是当前所有函数累加使用 `CPU` 的比例；

第四列和第五列代表这个函数以及子函数运行所占用的时间和比例（也被称为累加值 `cumulative`），应该大于等于前两列的值；

最后一列就是函数的名字。

如果应用程序有性能问题，上面这些信息应该能告诉我们时间都花费在哪些函数的执行上了。

`*peek，list ------` `peek` 是用来查询 函数名字的(这个名字是 `list` 需要使用的名字，并不完全等于函数名)，`list` 是用来将函数时间消耗列出来的：


1）`list main.main`

![](https://upload-images.jianshu.io/upload_images/13986876-0bdcc7465830eef6.png?imageMogr2/auto-orient/strip|imageView2/2/w/700/format/webp)

2)  `peek findMapMax` (因为根据1可以看出来消耗都在 `findMapMax`)

[](https://upload-images.jianshu.io/upload_images/13986876-0f07c2eeddc5c0b7.png?imageMogr2/auto-orient/strip|imageView2/2/w/700/format/webp)


3）list main.findMapMax (根据2可以看出来名字是 main.findMapMax)

![](https://upload-images.jianshu.io/upload_images/13986876-31076f0c67600b46.png?imageMogr2/auto-orient/strip|imageView2/2/w/700/format/webp)


> 妙用 `peek list` 指令可以很直观的看出来，我们的代码问题在 `m[i] = i`, 这就说明了就是 `map` 的写操作耗费了 `38.75s`, 而44行的读操作只用了`2.35s`, 针对这个 `demo` ，我们要优化的就是 `m[i] = i` ，因为这句操作已经语言级别的，我们是没有能力对他进行优化的，所以这时候如果需求只能用 `map` ，那么这个程序几乎没有优化空间了，如果需求可以使用其他的数据结构，那我们肯定会把 `map` 修改为 `slice` ，众所周知 `map` 每次存一个函数都要进行 `hash` 计算，而且存的多了到达一定的数量，还要重新对 `map` 进行重新分配空间的操作，所以肯定是耗时的。

## 总结

`Profiling` 一般和性能测试一起使用，这个原因在前文也提到过，只有应用在负载高的情况下 `Profiling` 才有意义。`memory` 也是同样的分析方法，在调用 `profile.Start(profile.CPUProfile, profile.ProfilePath("."))` 时将第一个参数改为 `profile.MemProfile` 就可以了，其它步骤都一样。另外还可以传 `block`，`trace` 等参数，可以用来分析和查找死锁等性能瓶颈以及阻塞分析，具体使用查看 `profile.Start()` 函数内部实现。


[火焰图--待学习](http://lihaoquan.me/2017/1/1/Profiling-and-Optimizing-Go-using-go-torch.html)



除了上面讲到的两种方式（报告生成、命令行交互），还可以在浏览器里进行交互。先生成 profile 文件，再执行命令：

```
go build -o cpu main.go # -o 参数指定生成的可执行文件的名字
 ./cpu
go tool pprof --http=:8080 cpu.pprof
```

进入一个可视化操作界面：

![Image](https://user-images.githubusercontent.com/7698088/68528770-214a7f80-0332-11ea-9ed9-b3b80a244fb5.png)

点击菜单栏可以在：Top/Graph/Peek/Source 之间进行切换，甚至可以看到火焰图（Flame Graph）：

![Image](https://user-images.githubusercontent.com/7698088/68528787-48a14c80-0332-11ea-8e9f-1cf730a02083.png)



补充阅读：
https://segmentfault.com/a/1190000019825563
https://cloud.tencent.com/developer/article/1596810