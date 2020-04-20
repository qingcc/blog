[原文链接](https://blog.gmem.cc/go-program-profiling)

[TOC]

# 简介
Go SDK自带了Profiling库，可以用来识别程序的缺陷、性能瓶颈。内置以下剖析能力：

1. CPU剖析（profile）：报告CPU的使用情况，定位到热点（消耗CPU周期最多的）代码。默认情况下Go以100HZ的频率进行CPU采样

2. 内存剖析（heap）：报告堆内存当前分配（存活对象）情况。默认情况下每分配512KB进行内存采样。你可以使用URL参数gc，提示报告前进行GC

3. 内存剖析（allocs）：报告所有内存分配历史

4. 线程创建（threadcreate）：报告导致新OS线程创建的代码片段，分析阻塞式系统调用

5. 协程剖析（goroutine）：报告所有Goroutine的调用栈

6. 阻塞剖析（block）：报告Goroutine在哪些同步原语（包括定时器通道）上阻塞，显示调用栈。必须显式调用 runtime.SetBlockProfileRate来启用此特性。默认每发生一次阻塞均采样

7. 互斥量剖析（mutex）：报告锁竞争情况，显示持有互斥量的代码的调用栈。当你认为CPU英文锁竞争而没有被完全使用时，显式调用 runtime.SetMutexProfileFraction 来启用此特性

8. 执行追踪（trace）：追踪当前应用程序的执行栈

此外，Go还允许定制自己的剖析，在代码中手工报告性能分析数据。

# 数据采集

要采集一个Go应用的剖析数据，有两种方式：

1. 利用 `runtime/pprof` 包，进行剖析数据采集，并且在应用退出时将剖析数据写入到文件
2. 利用 `net/http/pprof` 包，进行剖析数据采集，支持连接到HTTP服务实时分析

不管使用那种方式，都需要增加一些代码。

## 采集CPU

进行 `CPU` 剖析，添加如下代码：

```
f, err := os.Create(*cpuprofile)
if err != nil {
    log.Fatal("could not create CPU profile: ", err)
}
defer f.Close()
if err := pprof.StartCPUProfile(f); err != nil {
    log.Fatal("could not start CPU profile: ", err)
}
// 停止采样，并将剖析概要信息记录到文件
// 此方法实际上会将采样率设置为0
defer pprof.StopCPUProfile()
```

## 采集内存

进行内存剖析，添加如下代码：

```
// 设置采样率，默认每分配512*1024字节采样一次。如果设置为0则禁止采样，只能设置一次
runtime.MemProfileRate = *memProfileRate
 
 
f, err := os.Create(*memprofile)
if err != nil {
    log.Fatal("could not create memory profile: ", err)
}
defer f.Close()
runtime.GC() // 执行GC，避免垃圾对象干扰
// 将剖析概要信息记录到文件
if err := pprof.WriteHeapProfile(f); err != nil {
    log.Fatal("could not write memory profile: ", err)
}
```

## 采集阻塞

调用下面的方法启用此功能：

```
runtime.SetBlockProfileRate(5)
```

参数5表示，每发生5次Goroutine阻塞事件则采样一次。默认值1。 

下面的代码演示了如何将阻塞剖析概要信息记录到文件：

```
func stopBlockProfile() {
    if *blockProfile != "" && *blockProfileRate >= 0 {
        f, err := os.Create(*blockProfile)
        if err = pprof.Lookup("block").WriteTo(f, 0); err != nil {
            fmt.Fprintf(os.Stderr, "Can not write %s: %s", *blockProfile, err)
        }
        f.Close()
    }
} 
```

## 采集互斥锁
从Go 1.8开始，支持采集处于竞态条件的互斥锁，调用下面的方法启用此功能：

```
runtime.SetMutexProfileFraction(5)
```

此调用允许你捕获处于竞态条件的Goroutine的调用栈的一部分。

在进行测试时，不需要上述显式的调用，使用命令行参数即可：

```
go test -mutexprofile=mutex.out 
```

## 通过HTTP暴露

包 `net/http/pprof` 能够将实时剖析数据通过HTTP暴露为pprof可视化工具能识别的格式。

要使用此包，需要导入：

```
import _ "net/http/pprof"
```

你需要为 `pprof` 提供一个 `HTTP` 服务器：

```
go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

如果你不使用 `http.DefaultServeMux（如上代码）`，则需要手工注册路由规则：

```
r.HandleFunc("/debug/pprof/", pprof.Index)
r.HandleFunc("/debug/pprof/cmdline", pprof.Cmdline)
r.HandleFunc("/debug/pprof/profile", pprof.Profile)
r.HandleFunc("/debug/pprof/symbol", pprof.Symbol)
r.HandleFunc("/debug/pprof/trace", pprof.Trace) 
```

# pprof

## 读取剖析数据

### 通过HTTP

要连接到HTTP服务进行实时分析，使用如下命令：

```
# 设置剖析摘要信息存放目录
export PPROF_TMPDIR=/tmp/pprof
 
# 获取堆快照
go tool pprof http://localhost:6060/debug/pprof/heap
# 获取从启动依赖的内存分配历史
go tool pprof http://localhost:6060/debug/pprof/allocs
 
# 30秒CPU分析，需要等待30秒才能看到命令提示符
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30
 
# Goroutine阻塞分析
go tool pprof http://localhost:6060/debug/pprof/block
 
# 收集5秒的执行调用栈
wget http://localhost:6060/debug/pprof/trace?seconds=5
 
# 互斥锁分析
go tool pprof http://localhost:6060/debug/pprof/mutex
```

要查看所有可用的剖析， 访问 `http://localhost:6060/debug/pprof/` 。

### 通过文件

```
#  可执行文件路径
#  保存的剖析摘要文件
go tool pprof bin/Temp mutex.mprof
```

## 交互式命令

通过工具 `go tool pprof` 打开 `URL` 或文件后，会显示一个  `(pprof)` 提示符，你可以使用以下命令：

|命令|参数|	说明|
|:---|:---|:---|
|gv	|[focus]	|将当前概要文件以图形化和层次化的形式显示出来。当没有任何参数时，在概要文件中的所有采样都会被显示 如果指定了focus参数，则只显示调用栈中有名称与此参数相匹配的函数或方法的采样。 focus参数应该是一个正则表达式需要dot、gv命令，执行下面的命令安装：`sudo apt-get install graphviz sudo apt-get install gv `|
|web|	[focus]|	与gv命令类似，web命令也会用图形化的方式来显示概要文件。但不同的是，web命令是在一个Web浏览器中显示它|
|list|	[routine_regexp]|	列出名称与参数 routine_regexp代表的正则表达式相匹配的函数或方法的相关源代码|
|weblist|	[routine_regexp]|	 在Web浏览器中显示与list命令的输出相同的内容。它与list命令相比的优势是，在我们点击某行源码时还可以显示相应的汇编代码 |
|top[N]|	[--cum]|	top命令可以以本地采样计数为顺序列出函数或方法及相关信息 如果存在标记 --cum则以累积采样计数为顺序 默认情况下top命令会列出前10项内容。但是如果在top命令后面紧跟一个数字，那么其列出的项数就会与这个数字相同|
|traces||	 	打印所有采集的样本|
|disasm|	[routine_regexp]|	显示名称与参数 routine_regexp相匹配的函数或方法的反汇编代码。并且，在显示的内容中还会标注有相应的采样计数|
|callgrind|	[filename]|	利用callgrind工具生成统计文件。在这个文件中，说明了程序中函数的调用情况。如果未指定 filename参数，则直接调用kcachegrind工具。kcachegrind可以以可视化的方式查看callgrind工具生成的统计文件|
|help||	 	显示帮助|
|quit||	 	退出 |

## Web UI

调用 `pprof` 时，可以选择启动一个 `Web UI` ，指定 `-http` 选项即可：

```
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/heap
```

你可以访问Web UI来查看烈焰图等高级图表。

# 数据分析

## 分析CPU

### 测试代码

这里使用一段CPU密集型代码来学习CPU剖析：

```
package main
 
import (
    "net/http"
    _ "net/http/pprof"
    "sync"
    "time"
)
 
var wg sync.WaitGroup
 
func main() {
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()
 
    wg.Add(1)
    go calculte(wg)
    wg.Wait()
}
 
func calculte(wg sync.WaitGroup) {
    for i := 0; i < 100000000; i++ {
        time.Sleep(time.Millisecond)
        cpuBound(i)
    }
    wg.Done()
}
 
func cpuBound(i int) {
    factorial(i)
    sieveOfEratosthenes(i)
}
func sieveOfEratosthenes(N int) (primes []int) {
    b := make([]bool, N)
    for i := 2; i < N; i++ {
        if b[i] == true {
            continue
        }
        primes = append(primes, i)
        for k := i * i; k < N; k += i {
            b[k] = true
        }
    }
    return
}
 
func factorial(x int) int {
    if x == 0 {
        return 1
    }
 
    return x * factorial(x-1)
}
```

### top


```
(pprof) top10
Showing nodes accounting for 24630ms, 83.75% of 29410ms total
Dropped 107 nodes (cum <= 147.05ms)
Showing top 10 nodes out of 31
      flat  flat%   sum%        cum   cum%
    4720ms 16.05% 16.05%     4990ms 16.97%  main.sieveOfEratosthenes
    4510ms 15.33% 31.38%    19440ms 66.10%  runtime.gentraceback
    3550ms 12.07% 43.45%    23490ms 79.87%  main.factorial
    2810ms  9.55% 53.01%     8460ms 28.77%  runtime.getStackMap
    2130ms  7.24% 60.25%     3220ms 10.95%  runtime.funcdata
    2070ms  7.04% 67.29%     2630ms  8.94%  runtime.findfunc
    1540ms  5.24% 72.53%     1740ms  5.92%  runtime.pcvalue
    1400ms  4.76% 77.29%     1400ms  4.76%  runtime.add
    1000ms  3.40% 80.69%     9610ms 32.68%  runtime.adjustframe
     900ms  3.06% 83.75%     1070ms  3.64%  runtime.pcdatastart
...
         0     0% 97.18%      5.01s 17.04%  main.calculte
         0     0% 97.18%      4.99s 16.97%  main.cpuBound
```

使用top命令可以直接看到消耗CPU最多的方法，各列含义如下：

1. flat：在采样期间，此函数正在执行的次数 * 10ms。 可以用来粗略估计函数的运行耗时，不包含当前函数调用其它函数并等待返回的时间

2. flat%：flat / 总采样时间。估算函数运行耗CPU占比

3. sum%：当前行加上前面所有行的flat%总和

4. cum：在采样期间，此函数出现在调用栈的次数*10ms。和flat相比，该指标包含子函数耗时

5. cum%：cum/总采样时间

要以cum降序输出，执行 `top10 -cum`。

上面的例子中，`factorial` 是自递归调用，其 `cum` 值不知道为何比父例程 `cpuBound` 还要大得多，不符合只觉。

### list

通过 `top` 定位到耗时函数后，可以进一步使用该命令，分析函数每一行代码消耗多少时间。

函数 `cpuBound` 调用两个子例程 `factorial`、`sieveOfEratosthenes`，它们都是非常耗时的：

```
(pprof) list cpuBound
Total: 29.41s
ROUTINE ======================== main.cpuBound in /home/alex/Go/workspaces/default/src/git.gmem.cc/alex/go-study/golang/profile.go
         0      4.99s (flat, cum) 16.97% of Total
         .          .     27:    wg.Done()
         .          .     28:}
         .          .     29:
         .          .     30:func cpuBound(i int) {
         .          .     31:    factorial(i)
         .      4.99s     32:    sieveOfEratosthenes(i)
         .          .     33:}
         .          .     34:func sieveOfEratosthenes(N int) (primes []int) {
         .          .     35:    b := make([]bool, N)
         .          .     36:    for i := 2; i < N; i++ {
         .          .     37:        if b[i] == true {
```

从上面的输出可以看到， `cpuBound`的全部时间均消耗在对`sieveOfEratosthenes`的调用上，而`factorial`这个自递归调用的耗时无法体现。

### web 

使用此命令可以生成一个SVG图片，清晰的显示调用关系图。图中越红的节点消耗CPU越多： 
![Image](https://gmem.site/wp-content/uploads/2019/09/pprof001.svg)

从图中可以看到factorial函数引发的调用链最耗时，calculte其次。由于factorial是自递归调用，calculte到factorial的调用关系没有识别出来。

## 分析内存

### 测试代码

这里使用一段内存消耗型代码来学习CPU剖析：

```
package main
 
import (
    "net/http"
    _ "net/http/pprof"
    "time"
)
 
type pkg struct {
    blob
}
type blob struct {
    data [1024]int
}
 
func main() {
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()
    consume()
}
 
func consume() {
    for i := 0; i < 100000000; i++ {
        time.Sleep(time.Millisecond * 1)
        b100 := createBlob(100)
        println(b100)
        p100 := createPkg(100)
        println(p100)
    }
}
 
func createPkg(i int) interface{} {
    ps := make([]pkg, 0)
    for x := 0; x < i; x++ {
        ps = append(ps, pkg{})
    }
    return ps
}
 
func createBlob(i int) []blob {
    bs := make([]blob, 0)
    for x := 0; x < i; x++ {
        bs = append(bs, blob{})
    }
    return bs
}
```

### heap

执行下面的命令，可以获取一个堆快照，快照中包含所有存活对象：


```
go tool pprof http://localhost:6060/debug/pprof/heap
```

使用 `top` 命令可以看到哪些方法分配了最多的内存：

```
(pprof) top
Showing nodes accounting for 1.95MB, 100% of 1.95MB total
      flat  flat%   sum%        cum   cum%
    1.95MB   100%   100%     1.95MB   100%  main.createPkg
         0     0%   100%     1.95MB   100%  main.consume
         0     0%   100%     1.95MB   100%  main.main
         0     0%   100%     1.95MB   100%  runtime.main
```

可以看到，在本次快照中，`createPkg` 分配的内存最多。

使用 `list` 命令，可以进一步定位到 `createPkg` 的哪一行代码分配了这些内存：

```
(pprof) list createPkg
Total: 1.95MB
ROUTINE ======================== main.createPkg in /home/alex/Go/workspaces/default/src/git.gmem.cc/alex/go-study/golang/heap.go
    1.95MB     1.95MB (flat, cum)   100% of Total
         .          .     31:}
         .          .     32:
         .          .     33:func createPkg(i int) interface{} {
         .          .     34:   ps := make([]pkg, 0)
         .          .     35:   for x := 0; x < i; x++ {
    1.95MB     1.95MB     36:           ps = append(ps, pkg{})
         .          .     37:   }
         .          .     38:   return ps
         .          .     39:}
         .          .     40:
         .          .     41:func createBlob(i int) []blob {
```

可以看到，全部内存均由于代码 `ps = append(ps, pkg{})` 分配。 

类似的，使用web命令可以展示出内存分配的调用栈。

### allocs

执行下面的命令，可以获取程序运行依赖，所有内存分配的历史：

```
go tool pprof http://localhost:6060/debug/pprof/allocs
```

用 `top` 命令看，分配内存的量明显比 `heap` 剖析大的多：

```
(pprof) top
Showing nodes accounting for 5.69TB, 100% of 5.69TB total
Dropped 33 nodes (cum <= 0.03TB)
      flat  flat%   sum%        cum   cum%
    2.85TB 50.00% 50.00%     2.85TB 50.00%  main.createPkg
    2.85TB 50.00%   100%     2.85TB 50.00%  main.createBlob
         0     0%   100%     5.69TB   100%  main.consume
         0     0%   100%     5.69TB   100%  main.main
         0     0%   100%     5.69TB   100%  runtime.main
```

使用 `web` 命令，可以展示出内存分配的调用栈：

![Image]()

### 内存泄漏

所谓内存泄漏，意味着占用的内存一直无法释放。在 `pprof` 中，泄漏的内存一直存在于 `heap` 剖析的输出中，并且随着运行时间的增加，迟早会出现在 `top` 命令的输出中。

## 分析阻塞

### 测试代码

这里使用一段内存消耗型代码来学习阻塞剖析：

```
package main
 
import (
    "net/http"
    _ "net/http/pprof"
    "runtime"
    "sync"
    "time"
)
 
var mutex sync.Mutex
 
func main() {
    // rate = 1：统计所有的 block event,
    // rate <=0：关闭block profiling
    // rate > 1：阻塞时间t>rate那秒的event 一定会被统计，小于rate则有t/rate 的几率被统计
    runtime.SetBlockProfileRate(1 * 1000 * 1000)
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()
    var wg sync.WaitGroup
    for ; ; {
        wg.Add(1)
        mutex.Lock()
        go worker(&wg)
        time.Sleep(2 * time.Millisecond)
        mutex.Unlock()
        wg.Wait()
    }
}
func worker(wg *sync.WaitGroup) {
    defer wg.Done()
    mutex.Lock()
    time.Sleep(1 * time.Millisecond)
    mutex.Unlock()
}
```

### top

执行下面的命令，可以获取所有录制的阻塞事件：

```
go tool pprof http://localhost:6060/debug/pprof/block
```

`top` 显示的是阻塞时间最长的方法：

```
(pprof) top
Showing nodes accounting for 2.99mins, 100% of 2.99mins total
Dropped 9 nodes (cum <= 0.01mins)
      flat  flat%   sum%        cum   cum%
  1.95mins 65.37% 65.37%   1.95mins 65.37%  sync.(*Mutex).Lock
  1.03mins 34.63%   100%   1.03mins 34.63%  sync.(*WaitGroup).Wait
         0     0%   100%   1.03mins 34.63%  main.main
         0     0%   100%   1.95mins 65.37%  main.worker
         0     0%   100%   1.03mins 34.63%  runtime.main
(pprof)
```

这里可以看到阻塞时间都消耗在互斥量的 `Lock` 和等待组的 `Wait` 方法上。 

### web 

使用 `top` 无法感知什么代码导致了阻塞，你可以使用 `web` ，展示导致阻塞的调用栈。 

## 分析互斥锁

### 测试代码

```
package main
 
import (
    "math/rand"
    "net/http"
    _ "net/http/pprof"
    "runtime"
    "sync"
    "time"
)
 
var mutex sync.Mutex
 
func main() {
    // rate = 0：关闭 mutex prof
    // rate = 1：记录所有的 mutex event
    // rate > 1：随机记录 1/rate 的 mutex event
    runtime.SetMutexProfileFraction(1)
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()
 
    go worker()
    go worker()
    var wg sync.WaitGroup
    wg.Add(1)
    wg.Wait()
}
func worker() {
    for ; ; {
        mutex.Lock()
        time.Sleep(time.Duration(rand.New(rand.NewSource(time.Now().Unix())).Intn(10)) * time.Second)
        mutex.Unlock()
    }
}
```

### top
执行下面的命令，可以获取所有录制的互斥锁事件：

```
go tool pprof http://localhost:6060/debug/pprof/mutex
```

使用 `top` 命令，可以看到锁竞争的位置。

## 分析Goroutine

可以执行：

```
curl -s  http://localhost:6060/debug/pprof/goroutine?debug=2
```

来获取所有 `Goroutine` 的状态、调用栈。

如果 `Goroutine` 因为读写通道而阻塞，可以看到类似下面的输出：

```
goroutine 1 [chan receive, 7 minutes]:
main.main()
    /home/alex/Go/workspaces/default/src/git.gmem.cc/alex/go-study/golang/goroutine.go:21 +0x71
```


在这个例子中，主协程已经等待达7分钟。这种在通道上的等待是无法通过阻塞分析看到的。

如果Goroutine正在等待（包括网络）IO完成，可以看到类似下面的输出：

```
goroutine 436 [IO wait]:
internal/poll.runtime_pollWait(0x7ff9056e2dd8, 0x72, 0xb)
```

# 定制剖析

Go允许开发人员扩展自己的Profile，来跟踪任何资源的创建/释放。

假设你负责编写某个Blob服务器的客户端库，用户的需求是随时了解某个客户端实例打开了多少Blob。 你可以使用定制剖析满足此需求：

```
package blobstore
 
import "runtime/pprof"
 
// 定制剖析
var openBlobProfile = pprof.NewProfile("blobstore.Open")
 
// 打开一个Blob，所有Blob不再使用之后需要关闭
func Open(name string) (*Blob, error) {
    blob := &Blob{name: name}
 
    // ... 在这里加载并初始化Blob
 
 
    // 此方法将当前调用栈加入到剖析中，并且将此栈关联到对象blob
    // 信息存放在内部的一个map中，以blob为key，这意味着：
    //   1.blob必须适合用作key，而且它
    //   2.在显示调用Remove之前不会被GC
    // 如果剖析已经包含blob的调用栈，则panic
 
    // 2 表示跳过的栈帧数量，对于调用栈
    //   Add
    //   called from rpc.NewClient
    //   called from mypkg.Run
    //   called from main.main
    //  skip=0 从rpc.NewClient中的Add调用处开始记录
    //  skip=1 从mypkg.Run的NewClient调用处开始记录 
    openBlobProfile.Add(blob, 2)
    return blob, nil
}
 
// 关闭Blob并释放底层资源
func (b *Blob) Close() error {
    // 从Profile中移除对象b关联的调用栈
    openBlobProfile.Remove(b)
    return nil
}
```

如果此客户端库的使用者，想知道自己的程序当前打开了多少Blob，在什么地方（代码位置）打开的，可以这样编写：

```
package main
 
import (
    "fmt"
    "math/rand"
    "net/http"
    _ "net/http/pprof"
    "time"
 
    "myproject.org/blobstore"
)
 
func main() {
    for i := 0; i < 1000; i++ {
        name := fmt.Sprintf("task-blob-%d", i)
        go func() {
            // 打开Blob，会导致剖析记录数据
            b, err := blobstore.Open(name)
            if err != nil {
            }
            defer b.Close()
        }()
    }
    http.ListenAndServe("localhost:6060", nil)
}
```

程序运行期间，使用如下命令即可看到打开了哪些Blob：

```
go tool pprof http://localhost:6060/debug/pprof/blobstore.Open
 
(pprof) top
Showing nodes accounting for 800, 100% of 800 total
      flat  flat%   sum%        cum   cum%
       800   100%   100%        800   100%  main.main.func1 /Users/jbd/src/hello/main.go
```




