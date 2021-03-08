# Golang GC

GC(Garbage Collection) 即垃圾收集


## GC算法简介
三种经典的 GC 算法：引用计数（reference counting）、标记-清扫（mark & sweep）、节点复制（Copying Garbage Collection），分代收集（Generational Garbage Collection）。

###引用计数
引用计数的思想非常简单：每个单元维护一个域，保存其它单元指向它的引用数量（类似有向图的入度）。当引用数量为 0 时，将其回收。
引用计数是渐进式的，能够将内存管理的开销分布到整个程序之中。C++ 的 share_ptr 使用的就是引用计算方法。

引用计数算法实现一般是把所有的单元放在一个单元池里，比如类似 free list。这样所有的单元就被串起来了，就可以进行引用计数了。
新分配的单元计数值被设置为 1（注意不是 0，因为申请一般都说 ptr = new object 这种）。每次有一个指针被设为指向该单元时，
该单元的计数值加 1；而每次删除某个指向它的指针时，它的计数值减 1。当其引用计数为 0 的时候，该单元会被进行回收。虽然这里
说的比较简单，实现的时候还是有很多细节需要考虑，比如删除某个单元的时候，那么它指向的所有单元都需要对引用计数减 1。
那么如果这个时候，发现其中某个指向的单元的引用计数又为 0，那么是递归的进行还是采用其他的策略呢？递归处理的话会导致系统颠簸。
关于这些细节这里就不讨论了，可以参考文章后面的给的参考资料。

#### 优点
1. 渐进式。内存管理与用户程序的执行交织在一起，将 GC 的代价分散到整个程序。不像标记-清扫算法需要 STW (Stop The World，GC 的时候挂起用户程序)。
2. 算法易于实现。
3. 内存单元能够很快被回收。相比于其他垃圾回收算法，堆被耗尽或者达到某个阈值才会进行垃圾回收。

#### 缺点
1. 原始的引用计数不能处理循环引用。大概这是被诟病最多的缺点了。不过针对这个问题，也出了很多解决方案，比如强引用等。
2. 维护引用计数降低运行效率。内存单元的更新删除等都需要维护相关的内存单元的引用计数，相比于一些追踪式的垃圾回收算法并不需要这些代价。
3. 单元池 free list 实现的话不是 cache-friendly 的，这样会导致频繁的 cache miss，降低程序运行效率。

### 标记-清扫
标记-清扫算法是第一种自动内存管理，基于追踪的垃圾收集算法。算法思想在 70 年代就提出了，是一种非常古老的算法。
内存单元并不会在变成垃圾立刻回收，而是保持不可达状态，直到到达某个阈值或者固定时间长度。这个时候系统会挂起用户程序，
也就是 STW，转而执行垃圾回收程序。垃圾回收程序对所有的存活单元进行一次全局遍历确定哪些单元可以回收。算法分两个部分：
标记（mark）和清扫（sweep）。标记阶段表明所有的存活单元，清扫阶段将垃圾单元回收。可视化可以参考下图。 
 
![Image](https://upload.wikimedia.org/wikipedia/commons/4/4a/Animation_of_the_Naive_Mark_and_Sweep_Garbage_Collector_Algorithm.gif)

标记-清扫算法的优点也就是基于追踪的垃圾回收算法具有的优点：避免了引用计数算法的缺点（不能处理循环引用，需要维护指针）。缺点也很明显，需要 STW。

### 三色标记算法

三色标记算法是对标记阶段的改进，原理如下：

1. 起初所有对象都是白色。
2. 从根出发扫描所有可达对象，标记为灰色，放入待处理队列。
3. 从队列取出灰色对象，将其引用对象标记为灰色放入队列，自身标记为黑色。
4. 重复 3，直到灰色对象队列为空。此时白色对象即为垃圾，进行回收。  

可视化如下。

![Image](https://upload.wikimedia.org/wikipedia/commons/1/1d/Animation_of_tri-color_garbage_collection.gif)

三色标记的一个明显好处是能够让用户程序和 mark 并发的进行，具体可以参考论文：
《On-the-fly garbage collection: an exercise in cooperation.》。
Golang 的 GC 实现也是基于这篇论文，后面再具体说明。

### 节点复制

节点复制也是基于追踪的算法。其将整个堆等分为两个半区（semi-space），一个包含现有数据，另一个包含已被废弃的数据。
节点复制式垃圾收集从切换（flip）两个半区的角色开始，然后收集器在老的半区，也就是 Fromspace 中遍历存活的数据结构，
在第一次访问某个单元时把它复制到新半区，也就是 Tospace 中去。在 Fromspace 中所有存活单元都被访问过之后，收集器在
 `Tospace` 中建立一个存活数据结构的副本，用户程序可以重新开始运行了。
 
#### 优点
1. 所有存活的数据结构都缩并地排列在 Tospace 的底部，这样就不会存在内存碎片的问题。
2. 获取新内存可以简单地通过递增自由空间指针来实现。
#### 缺点
1. 内存得不到充分利用，总有一半的内存空间处于浪费状态。

### 分代收集

基于追踪的垃圾回收算法（标记-清扫、节点复制）一个主要问题是在生命周期较长的对象上浪费时间（长生命周期的对象是不需要频繁扫描的）。
同时，内存分配存在这么一个事实 “most object die young”。基于这两点，分代垃圾回收算法将对象按生命周期长短存放到堆上的两个（或者更多）区域，
这些区域就是分代（generation）。对于新生代的区域的垃圾回收频率要明显高于老年代区域。

分配对象的时候从新生代里面分配，如果后面发现对象的生命周期较长，则将其移到老年代，这个过程叫做 promote。随着不断 promote，
最后新生代的大小在整个堆的占用比例不会特别大。收集的时候集中主要精力在新生代就会相对来说效率更高，STW 时间也会更短。

#### 优点
1. 性能更优。

#### 缺点
1. 实现复杂

## Golang GC

### Overview

在说 Golang 的具体垃圾回收流程时，我们先来看一下几个基本的问题。

#### 1. 何时触发 GC  

在堆上分配大于 32K byte 对象的时候进行检测此时是否满足垃圾回收条件，如果满足则进行垃圾回收。
```go
func mallocgc(size uintptr, typ *_type, needzero bool) unsafe.Pointer {
    ...
    shouldhelpgc := false
    // 分配的对象小于 32K byte
    if size <= maxSmallSize {
        ...
    } else {
        shouldhelpgc = true
        ...
    }
    ...
    // gcShouldStart() 函数进行触发条件检测
    if shouldhelpgc && gcShouldStart(false) {
        // gcStart() 函数进行垃圾回收
        gcStart(gcBackgroundMode, false)
    }
}
```
上面是自动垃圾回收，还有一种是主动垃圾回收，通过调用 `runtime.GC()`，这是阻塞式的。

```go
// GC runs a garbage collection and blocks the caller until the
// garbage collection is complete. It may also block the entire
// program.
func GC() {
    gcStart(gcForceBlockMode, false)
}
```

#### 2. GC 触发条件

触发条件主要关注下面代码中的中间部分：forceTrigger || memstats.heap_live >= memstats.gc_trigger 。forceTrigger 是 forceGC 的标志；
后面半句的意思是当前堆上的活跃对象大于我们初始化时候设置的 GC 触发阈值。在 malloc 以及 free 的时候 heap_live 会一直进行更新，这里就不再展开了。

```go
// gcShouldStart returns true if the exit condition for the _GCoff
// phase has been met. The exit condition should be tested when
// allocating.
//
// If forceTrigger is true, it ignores the current heap size, but
// checks all other conditions. In general this should be false.
func gcShouldStart(forceTrigger bool) bool {
    return gcphase == _GCoff && (forceTrigger || memstats.heap_live >= memstats.gc_trigger) && memstats.enablegc && panicking == 0 && gcpercent >= 0
}

//初始化的时候设置 GC 的触发阈值
func gcinit() {
    _ = setGCPercent(readgogc())
    memstats.gc_trigger = heapminimum
    ...
}
// 启动的时候通过 GOGC 传递百分比 x
// 触发阈值等于 x * defaultHeapMinimum (defaultHeapMinimum 默认是 4M)
func readgogc() int32 {
    p := gogetenv("GOGC")
    if p == "off" {
        return -1
    }
    if n, ok := atoi32(p); ok {
        return n
    }
    return 100
}
```

### 3. 垃圾回收的主要流程

三色标记法，主要流程如下：

1. 所有对象最开始都是白色。
2. 从 root 开始找到所有可达对象，标记为灰色，放入待处理队列。
3. 遍历灰色对象队列，将其引用对象标记为灰色放入待处理队列，自身标记为黑色。
4. 处理完灰色对象队列，执行清扫工作。

![Image]()

关于上图有几点需要说明的是。

1. 首先从 root 开始遍历，root 包括全局指针和 goroutine 栈上的指针。
2. mark 有两个过程。
    - 从 root 开始遍历，标记为灰色。遍历灰色队列。
    - re-scan 全局指针和栈。因为 mark 和用户程序是并行的，所以在过程 1 的时候可能会有新的对象分配，这个时候就需要通过写屏障（write barrier）记录下来。re-scan 再完成检查一下。
3. Stop The World 有两个过程。
    - 第一个是 GC 将要开始的时候，这个时候主要是一些准备工作，比如 enable write barrier。
    - 第二个过程就是上面提到的 re-scan 过程。如果这个时候没有 stw，那么 mark 将无休止。  
    
另外针对上图各个阶段对应 GCPhase 如下：

- Off: _GCoff
- Stack scan ~ Mark: _GCmark
- Mark termination: _GCmarktermination

[Golang源码探索(三) GC的实现原理](https://www.cnblogs.com/zkweb/p/7880099.html)  
[Golang GC 垃圾回收机制详解](https://blog.csdn.net/u010649766/article/details/80582153)
[Golang 垃圾回收剖析](http://legendtkl.com/2017/04/28/golang-gc/)