[原文链接](https://cloud.tencent.com/developer/article/1005481)

[TOC]

# 大话 Select、Poll、Epoll

提到`select`、`poll`、`epoll`相信大家都耳熟能详了，三个都是`IO`多路复用的机制，可以监视多个描述符的读/写等事件，一旦某个描述符就绪（一般是读或者写事件发生了），就能够将发生的事件通知给关心的应用程序去处理该事件。  
本质上，`select`、`poll`、`epoll`本质上都是同步`I/O`，相信大家都读过`Richard Stevens`的经典书籍`UNP`（`UNIX:registered: Network Programming`），书中给出了5种`IO`模型：

- [1] blocking IO - 阻塞IO  
- [2] nonblocking IO - 非阻塞IO  
- [3] IO multiplexing - IO多路复用  
- [4] signal driven IO - 信号驱动IO  
- [5] asynchronous IO - 异步IO

其中前面4种`IO`都可以归类为`synchronous IO` - 同步`IO`，在介绍`select`、`poll`、`epoll`之前，首先介绍一下这几种`IO`模型，`signal driven IO`平时用的比较少，这里就不介绍了。

## 1. IO - 同步、异步、阻塞、非阻塞

下面以`network IO`中的`read`读操作为切入点，来讲述同步（`synchronous`） `IO`和异步（`asynchronous`） `IO`、阻塞（`blocking`） `IO`和非阻塞（`non-blocking`）`IO`的异同。一般情况下，一次网络`IO`读操作会涉及两个系统对象：
(1) 用户进程(线程)`Process`；  
(2)内核对象`kernel`，  
两个处理阶段：

- [1] `Waiting for the data to be ready` - 等待数据准备好  
- [2] `Copying the data from the kernel to the process` - 将数据从内核空间的`buffer`拷贝到用户空间进程的`buffer`

`IO`模型的异同点就是区分在这两个系统对象、两个处理阶段的不同上。

### 1.1 同步`IO` 之 `Blocking IO`

![Image](https://blog-10039692.file.myqcloud.com/1500016932293_3417_1500016932577.png)

如上图所示，用户进程`process`在`Blocking IO`读`recvfrom`操作的两个阶段都是等待的。在数据没准备好的时候，`process`原地等待`kernel`准备数据。  
`kernel`准备好数据后，`process`继续等待`kernel`将数据`copy`到自己的`buffer`。在`kernel`完成数据的`copy`后`process`才会从`recvfrom`系统调用中返回。

### 1.2 同步`IO` 之 `NonBlocking IO`

![Image](https://blog-10039692.file.myqcloud.com/1500017008242_1297_1500017008596.png)

从图中可以看出，`process`在`NonBlocking IO`读`recvfrom`操作的第一个阶段是不会`block`等待的，如果`kernel`数据还没准备好，那么`recvfrom`会立刻返回一个`EWOULDBLOCK`错误。
当`kernel`准备好数据后，进入处理的第二阶段的时候，`process`会等待`kernel`将数据`copy`到自己的`buffer`，在`kernel`完成数据的`copy`后`process`才会从`recvfrom`系统调用中返回。

### 1.3 同步`IO` 之 `IO multiplexing`

![Image](https://blog-10039692.file.myqcloud.com/1500017024989_2800_1500017025229.png)

`IO`多路复用，就是我们熟知的`select`、`poll`、`epoll`模型。从图上可见，在`IO`多路复用的时候，`process`在两个处理阶段都是`block`住等待的。初看好像`IO`多路复用没什么用，其实`select`、`poll`、`epoll`的优势在于可以**以较少的代价来同时监听处理多个`IO`**。

### 1.4 异步`IO`

![Image](https://blog-10039692.file.myqcloud.com/1500017078734_6117_1500017078936.png)

从上图看出，异步`IO`要求`process`在`recvfrom`操作的两个处理阶段上都不能等待，也就是`process`调用`recvfrom`后立刻返回，`kernel`自行去准备好数据并将数据从`kernel`的`buffer`中`copy`到`process`的`buffer`在通知`process`读操作完成了，然后`process`在去处理。
遗憾的是，`linux`的网络`IO`中是不存在异步`IO`的，`linux`的网络`IO`处理的第二阶段总是阻塞等待数据`copy`完成的。真正意义上的网络异步`IO`是`Windows`下的`IOCP`（`IO`完成端口）模型。

![Image](https://blog-10039692.file.myqcloud.com/1500017105443_4641_1500017105783.png)

很多时候，我们比较容易混淆`non-blocking IO`和`asynchronous IO`，认为是一样的。但是通过上图，几种`IO`模型的比较，会发现`non-blocking IO`和`asynchronous IO`的区别还是很明显的，
`non-blocking IO`仅仅要求处理的第一阶段不`block`即可，而`asynchronous IO`要求两个阶段都不能`block`住。

## 2 `Linux`的`socket` 事件`wakeup callback`机制

言归正传，在介绍`select`、`poll`、`epoll`前，有必要说说`linux(2.6+)`内核的事件`wakeup callback`机制，这是`IO`多路复用机制存在的本质。
`Linux`通过`socket`睡眠队列来管理所有等待`socket`的某个事件的`process`，同时通过`wakeup`机制来异步唤醒整个睡眠队列上等待事件的`process`，通知`process`相关事件发生。
通常情况，`socket`的事件发生的时候，其会顺序遍历`socket`睡眠队列上的每个`process`节点，调用每个`process`节点挂载的`callback`函数。在遍历的过程中，如果遇到某个节点是排他的，那么就终止遍历，总体上会涉及两大逻辑：  
（1）睡眠等待逻辑；   
（2）唤醒逻辑。

- （1）睡眠等待逻辑：涉及`select`、`poll`、`epoll_wait`的阻塞等待逻辑

> [1]`select`、`poll`、`epoll_wait`陷入内核，判断监控的`socket`是否有关心的事件发生了，如果没，则为当前`process`构建一个`wait_entry`节点，然后插入到监控`socket`的`sleep_list`  
[2]进入循环的`schedule`直到关心的事件发生了  
[3]关心的事件发生后，将当前`process`的`wait_entry`节点从`socket`的`sleep_list`中删除。

- （2）唤醒逻辑：

> [1]`socket`的事件发生了，然后`socket`顺序遍历其睡眠队列，依次调用每个`wait_entry`节点的`callback`函数
[2]直到完成队列的遍历或遇到某个`wait_entry`节点是排他的才停止。
[3]一般情况下`callback`包含两个逻辑：1.`wait_entry`自定义的私有逻辑；2.唤醒的公共逻辑，主要用于将该`wait_entry`的`process`放入`CPU`的就绪队列，让`CPU`随后可以调度其执行。

下面就上面的两大逻辑，分别阐述`select`、`poll`、`epoll`的异同，为什么`epoll`能够比`select`、`poll`高效。

## 3 大话`Select—1024`

在一个高性能的网络服务上，大多情况下一个服务进程(线程)`process`需要同时处理多个`socket`，我们需要公平对待所有`socket`，对于`read`而言，哪个`socket`有数据可读，`process`就去读取该`socket`的数据来处理。
于是对于`read`，一个朴素的需求就是关心的`N`个`socket`是否有数据”可读”，也就是我们期待”可读”事件的通知，而不是盲目地对每个`socket`调用`recv/recvfrom`来尝试接收数据。
我们应该`block`在等待事件的发生上，这个事件简单点就是”关心的`N`个`socket`中一个或多个`socket`有数据可读了”，当`block`解除的时候，就意味着，我们一定可以找到一个或多个`socket`上有可读的数据。
另一方面，根据上面的`socket wakeup callback`机制，我们不知道什么时候，哪个`socket`会有读事件发生，于是，`process`需要同时插入到这`N`个`socket`的`sleep_list`上等待任意一个`socket`可读事件发生而被唤醒，
当`process`被唤醒的时候，其`callback`里面应该有个逻辑去检查具体那些`socket`可读了。

于是，`select`的多路复用逻辑就清晰了，`select`为每个`socket`引入一个`poll`逻辑，该`poll`逻辑用于收集`socket`发生的事件，对于可读事件来说，简单伪码如下：

```
poll()
{
    //其他逻辑
    if (recieve queque is not empty)
    {
        sk_event |= POLL_IN；
    }
   //其他逻辑
}
```

接下来就到`select`的逻辑了，下面是`select`的函数原型：5个参数，后面4个参数都是`in/out`类型(值可能会被修改返回)

```
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
```

当用户`process`调用`select`的时候，`select`会将需要监控的`readfds`集合拷贝到内核空间（假设监控的仅仅是`socket`可读），然后遍历自己监控的`socket sk`，挨个调用`sk`的`poll`逻辑以便检查该`sk`是否有可读事件，
遍历完所有的`sk`后，如果没有任何一个`sk`可读，那么`select`会调用`schedule_timeout`进入`schedule`循环，使得`process`进入睡眠。如果在`timeout`时间内某个`sk`上有数据可读了，或者等待`timeout`了，
则调用`select`的`process`会被唤醒，接下来`select`就是遍历监控的`sk`集合，挨个收集可读事件并返回给用户了，相应的伪码如下：

```
for (sk in readfds)
{
    sk_event.evt = sk.poll();
    sk_event.sk = sk;
    ret_event_for_process;
}
```

通过上面的`select`逻辑过程分析，相信大家都意识到，`select`存在两个问题：

> [1] 被监控的`fds`需要从用户空间拷贝到内核空间  
    为了减少数据拷贝带来的性能损坏，内核对被监控的`fds`集合大小做了限制，并且这个是通过宏控制的，大小不可改变(限制为1024)。  
[2] 被监控的`fds`集合中，只要有一个有数据可读，整个`socket`集合就会被遍历一次调用`sk`的`poll`函数收集可读事件  
    由于当初的需求是朴素，仅仅关心是否有数据可读这样一个事件，当事件通知来的时候，由于数据的到来是异步的，我们不知道事件来的时候，有多少个被监控的`socket`有数据可读了，于是，只能挨个遍历每个`socket`来收集可读事件。

到这里，我们有三个问题需要解决：

- （1）被监控的`fds`集合限制为1024，1024太小了，我们希望能够有个比较大的可监控`fds`集合
- （2）`fds`集合需要从用户空间拷贝到内核空间的问题，我们希望不需要拷贝
- （3）当被监控的`fds`中某些有数据可读的时候，我们希望通知更加精细一点，就是我们希望能够从通知中得到有可读事件的`fds`列表，而不是需要遍历整个`fds`来收集。

## 4 大话poll—鸡肋

`select`遗留的三个问题中，问题(1)是用法限制问题，问题(2)和(3)则是性能问题。`poll`和`select`非常相似，`poll`并没着手解决性能问题，`poll`只是解决了`select`的问题(1)`fds`集合大小1024限制问题。
下面是`poll`的函数原型，`poll`改变了`fds`集合的描述方式，使用了`pollfd`结构而不是`select`的`fd_set`结构，使得`poll`支持的`fds`集合限制远大于`select`的1024。`poll`虽然解决了`fds`集合大小1024的限制问题，
但是，它并没改变大量描述符数组被整体复制于用户态和内核态的地址空间之间，以及个别描述符就绪触发整体描述符集合的遍历的低效问题。`poll`随着监控的`socket`集合的增加性能线性下降，`poll`不适合用于大并发场景。

```
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
```

## 5 大话`epoll`—终极武功

`select`遗留的三个问题，问题(1)是比较好解决，`poll`简单两三下就解决掉了，但是`poll`的解决有点鸡肋。要解决问题(2)和(3)似乎比较棘手，要怎么解决呢？我们知道，在计算机行业中，有两种解决问题的思想：

> [1] 计算机科学领域的任何问题, 都可以通过添加一个中间层来解决  
[2] 变集中(中央)处理为分散(分布式)处理

下面，我们看看，`epoll`在解决`select`的遗留问题(2)和(3)的时候，怎么运用这两个思想的。

### 5.1 `fds`集合拷贝问题的解决

对于`IO`多路复用，有两件事是必须要做的(对于监控可读事件而言)：
1. 准备好需要监控的`fds`集合；
2. 探测并返回`fds`集合中哪些`fd`可读了。细看`select`或`poll`的函数原型，我们会发现，每次调用`select`或`poll`都在重复地准备(集中处理)整个需要监控的`fds`集合。然而对于频繁调用的`select`或`poll`而言，
`fds`集合的变化频率要低得多，我们没必要每次都重新准备(集中处理)整个`fds`集合。

于是，`epoll`引入了`epoll_ctl`系统调用，将高频调用的`epoll_wait`和低频的`epoll_ctl`隔离开。同时，`epoll_ctl`通过(`EPOLL_CTL_ADD`、`EPOLL_CTL_MOD`、`EPOLL_CTL_DEL`)三个操作来分散对需要监控的`fds`集合的修改，
做到了有变化才变更，将`select`或`poll`高频、大块内存拷贝(集中处理)变成`epoll_ctl`的低频、小块内存的拷贝(分散处理)，避免了大量的内存拷贝。同时，对于高频`epoll_wait`的可读就绪的`fd`集合返回的拷贝问题，
`epoll`通过内核与用户空间`mmap`(内存映射)同一块内存来解决。`mmap`将用户空间的一块地址和内核空间的一块地址同时映射到相同的一块物理内存地址（不管是用户空间还是内核空间都是虚拟地址，最终要通过地址映射映射到物理地址），
使得这块物理内存对内核和对用户均可见，减少用户态和内核态之间的数据交换。

另外，`epoll`通过`epoll_ctl`来对监控的`fds`集合来进行增、删、改，那么必须涉及到`fd`的快速查找问题，于是，一个低时间复杂度的增、删、改、查的数据结构来组织被监控的`fds`集合是必不可少的了。
在`linux 2.6.8`之前的内核，`epoll`使用`hash`来组织`fds`集合，于是在创建`epoll fd`的时候，`epoll`需要初始化`hash`的大小。于是`epoll_create(int size`)有一个参数`size`，以便内核根据`size`的大小来分配`hash`的大小。
在`linux 2.6.8`以后的内核中，`epoll`使用红黑树来组织监控的`fds`集合，于是`epoll_create(int size)`的参数`size`实际上已经没有意义了。

## 5.2 按需遍历就绪的`fds`集合

通过上面的`socket`的睡眠队列唤醒逻辑我们知道，`socket`唤醒睡眠在其睡眠队列的`wait_entry(process)`的时候会调用`wait_entry`的回调函数`callback`，并且，我们可以在`callback`中做任何事情。
为了做到只遍历就绪的`fd`，我们需要有个地方来组织那些已经就绪的`fd`。为此，`epoll`引入了一个中间层，一个双向链表(`ready_list`)，一个单独的睡眠队列(`single_epoll_wait_list`)，并且，与`select`或`poll`不同的是，
`epoll`的`process`不需要同时插入到多路复用的`socket`集合的所有睡眠队列中，相反`process`只是插入到中间层的`epoll`的单独睡眠队列中，`process`睡眠在`epoll`的单独队列上，等待事件的发生。同时，
引入一个中间的`wait_entry_sk`，它与某个`socket sk`密切相关，`wait_entry_sk`睡眠在`sk`的睡眠队列上，其`callback`函数逻辑是将当前`sk`排入到`epoll`的`ready_list`中，并唤醒`epoll`的`single_epoll_wait_list`。
而`single_epoll_wait_list`上睡眠的`process`的回调函数就明朗了：遍历`ready_list`上的所有`sk`，挨个调用`sk`的`poll`函数收集事件，然后唤醒`process`从`epoll_wait`返回。

于是，整个过来可以分为以下几个逻辑：

（1）`epoll_ctl EPOLL_CTL_ADD`逻辑

> [1] 构建睡眠实体`wait_entry_sk`，将当前`socket sk`关联给`wait_entry_sk`，并设置`wait_entry_sk`的回调函数为`epoll_callback_sk`  
[2] 将`wait_entry_sk`排入当前`socket sk`的睡眠队列上

回调函数`epoll_callback_sk`的逻辑如下：

> [1] 将之前关联的`sk`排入`epoll`的`ready_list`  
[2] 然后唤醒`epoll`的单独睡眠队列`single_epoll_wait_list`

（2）`epoll_wait`逻辑

> [1] 构建睡眠实体`wait_entry_proc`，将当前`process`关联给`wait_entry_proc`，并设置回调函数为`epoll_callback_proc`  
[2] 判断`epoll`的`ready_list`是否为空，如果为空，则将`wait_entry_proc`排入`epoll`的`single_epoll_wait_list`中，随后进入`schedule`循环，这会导致调用`epoll_wait`的`process`睡眠。  
[3] `wait_entry_proc`被事件唤醒或超时醒来，`wait_entry_proc`将被从`single_epoll_wait_list`移除掉，然后`wait_entry_proc`执行回调函数`epoll_callback_proc`

回调函数`epoll_callback_proc`的逻辑如下：

> [1] 遍历`epoll`的`ready_list`，挨个调用每个`sk`的`poll`逻辑收集发生的事件，对于监控可读事件而已，`ready_list`上的每个`sk`都是有数据可读的，这里的遍历必要的(不同于`select/poll`的遍历，它不管有没数据可读都需要遍历一些来判断，这样就做了很多无用功。)  
[2] 将每个`sk`收集到的事件，通过`epoll_wait`传入的`events`数组回传并唤醒相应的`process`。

（3）`epoll`唤醒逻辑

整个`epoll`的协议栈唤醒逻辑如下(对于可读事件而言)：

> [1] 协议数据包到达网卡并被排入`socket sk`的接收队列  
[2] 睡眠在`sk`的睡眠队列`wait_entry`被唤醒，`wait_entry_sk`的回调函数`epoll_callback_sk`被执行  
[3] `epoll_callback_sk`将当前`sk`插入`epoll`的`ready_list`中  
[4] 唤醒睡眠在`epoll`的单独睡眠队列`single_epoll_wait_list`的`wait_entry`，`wait_entry_proc`被唤醒执行回调函数`epoll_callback_proc`  
[5] 遍历`epoll`的`ready_list`，挨个调用每个`sk`的`poll`逻辑收集发生的事件  
[6] 将每个`sk`收集到的事件，通过`epoll_wait`传入的`events`数组回传并唤醒相应的`process`。  

`epoll`巧妙的引入一个中间层解决了大量监控`socket`的无效遍历问题。细心的同学会发现，`epoll`在中间层上为每个监控的`socket`准备了一个单独的回调函数`epoll_callback_sk`，而对于`select/poll`，所有的`socket`都公用一个相同的回调函数。正是这个单独的回调e`poll_callback_sk`使得每个`socket`都能单独处理自身，当自己就绪的时候将自身`socket`挂入`epoll`的`ready_list`。同时，`epoll`引入了一个睡眠队列`single_epoll_wait_list`，分割了两类睡眠等待。`process`不再睡眠在所有的`socket`的睡眠队列上，而是睡眠在`epoll`的睡眠队列上，在等待”任意一个`socket`可读就绪”事件。而中间`wait_entry_sk`则代替`process`睡眠在具体的`socket`上，当`socket`就绪的时候，它就可以处理自身了。

## 5.3 ET(Edge Triggered 边沿触发) vs LT(Level Triggered 水平触发)

### 5.3.1 ET vs LT - 概念

说到Epoll就不能不说说Epoll事件的两种模式了，下面是两个模式的基本概念

Edge Triggered (ET) 边沿触发
.socket的接收缓冲区状态变化时触发读事件，即空的接收缓冲区刚接收到数据时触发读事件

.socket的发送缓冲区状态变化时触发写事件，即满的缓冲区刚空出空间时触发读事件

仅在缓冲区状态变化时触发事件，比如数据缓冲去从无到有的时候(不可读-可读)

Level Triggered (LT) 水平触发
.socket接收缓冲区不为空，有数据可读，则读事件一直触发

.socket发送缓冲区不满可以继续写入数据，则写事件一直触发

符合思维习惯，epoll_wait返回的事件就是socket的状态

通常情况下，大家都认为ET模式更为高效，实际上是不是呢？下面我们来说说两种模式的本质：

我们来回顾一下，5.2节（3）epoll唤醒逻辑 的第五个步骤


[5] 遍历epoll的ready_list，挨个调用每个sk的poll逻辑收集发生的事件
大家是不是有个疑问呢：挂在ready_list上的sk什么时候会被移除掉呢？其实，sk从ready_list移除的时机正是区分两种事件模式的本质。因为，通过上面的介绍，我们知道ready_list是否为空是epoll_wait是否返回的条件。于是，在两种事件模式下，步骤5如下：

对于Edge Triggered (ET) 边沿触发：

[5] 遍历epoll的ready_list，将sk从ready_list中移除，然后调用该sk的poll逻辑收集发生的事件
对于Level Triggered (LT) 水平触发：

[5.1] 遍历epoll的ready_list，将sk从ready_list中移除，然后调用该sk的poll逻辑收集发生的事件
[5.2] 如果该sk的poll函数返回了关心的事件(对于可读事件来说，就是POLL_IN事件)，那么该sk被重新加入到epoll的ready_list中。
对于可读事件而言，在ET模式下，如果某个socket有新的数据到达，那么该sk就会被排入epoll的ready_list，从而epoll_wait就一定能收到可读事件的通知(调用sk的poll逻辑一定能收集到可读事件)。于是，我们通常理解的缓冲区状态变化(从无到有)的理解是不准确的，准确的理解应该是是否有新的数据达到缓冲区。

而在LT模式下，某个sk被探测到有数据可读，那么该sk会被重新加入到read_list，那么在该sk的数据被全部取走前，下次调用epoll_wait就一定能够收到该sk的可读事件(调用sk的poll逻辑一定能收集到可读事件)，从而epoll_wait就能返回。

5.3.2 ET vs LT - 性能

通过上面的概念介绍，我们知道对于可读事件而言，LT比ET多了两个操作：(1)对ready_list的遍历的时候，对于收集到可读事件的sk会重新放入ready_list；(2)下次epoll_wait的时候会再次遍历上次重新放入的sk，如果sk本身没有数据可读了，那么这次遍历就变得多余了。
在服务端有海量活跃socket的时候，LT模式下，epoll_wait返回的时候，会有海量的socket sk重新放入ready_list。如果，用户在第一次epoll_wait返回的时候，将有数据的socket都处理掉了，那么下次epoll_wait的时候，上次epoll_wait重新入ready_list的sk被再次遍历就有点多余，这个时候LT确实会带来一些性能损失。然而，实际上会存在很多多余的遍历么？

先不说第一次epoll_wait返回的时候，用户进程能否都将有数据返回的socket处理掉。在用户处理的过程中，如果该socket有新的数据上来，那么协议栈发现sk已经在ready_list中了，那么就不需要再次放入ready_list，也就是在LT模式下，对该sk的再次遍历不是多余的，是有效的。同时，我们回归epoll高效的场景在于，服务器有海量socket，但是活跃socket较少的情况下才会体现出epoll的高效、高性能。因此，在实际的应用场合，绝大多数情况下，ET模式在性能上并不会比LT模式具有压倒性的优势，至少，目前还没有实际应用场合的测试表面ET比LT性能更好。

5.3.3 ET vs LT - 复杂度

我们知道，对于可读事件而言，在阻塞模式下，是无法识别队列空的事件的，并且，事件通知机制，仅仅是通知有数据，并不会通知有多少数据。于是，在阻塞模式下，在epoll_wait返回的时候，我们对某个socket_fd调用recv或read读取并返回了一些数据的时候，我们不能再次直接调用recv或read，因为，如果socket_fd已经无数据可读的时候，进程就会阻塞在该socket_fd的recv或read调用上，这样就影响了IO多路复用的逻辑(我们希望是阻塞在所有被监控socket的epoll_wait调用上，而不是单独某个socket_fd上)，造成其他socket饿死，即使有数据来了，也无法处理。

接下来，我们只能再次调用epoll_wait来探测一些socket_fd，看是否还有数据可读。在LT模式下，如果socket_fd还有数据可读，那么epoll_wait就一定能够返回，接着，我们就可以对该socket_fd调用recv或read读取数据。然而，在ET模式下，尽管socket_fd还是数据可读，但是如果没有新的数据上来，那么epoll_wait是不会通知可读事件的。这个时候，epoll_wait阻塞住了，这下子坑爹了，明明有数据你不处理，非要等新的数据来了在处理，那么我们就死扛咯，看谁先忍不住。

等等，在阻塞模式下，不是不能用ET的么？是的，正是因为有这样的缺点，ET强制需要在非阻塞模式下使用。在ET模式下，epoll_wait返回socket_fd有数据可读，我们必须要读完所有数据才能离开。因为，如果不读完，epoll不会在通知你了，虽然有新的数据到来的时候，会再次通知，但是我们并不知道新数据会不会来，以及什么时候会来。由于在阻塞模式下，我们是无法通过recv/read来探测空数据事件，于是，我们必须采用非阻塞模式，一直read直到EAGAIN。因此，ET要求socket_fd非阻塞也就不难理解了。

另外，epoll_wait原本的语意是：监控并探测socket是否有数据可读(对于读事件而言)。LT模式保留了其原本的语意，只要socket还有数据可读，它就能不断反馈，于是，我们想什么时候读取处理都可以，我们永远有再次poll的机会去探测是否有数据可以处理，这样带来了编程上的很大方便，不容易死锁造成某些socket饿死。相反，ET模式修改了epoll_wait原本的语意，变成了：监控并探测socket是否有新的数据可读。

于是，在epoll_wait返回socket_fd可读的时候，我们需要小心处理，要不然会造成死锁和socket饿死现象。典型如listen_fd返回可读的时候，我们需要不断的accept直到EAGAIN。假设同时有三个请求到达，epoll_wait返回listen_fd可读，这个时候，如果仅仅accept一次拿走一个请求去处理，那么就会留下两个请求，如果这个时候一直没有新的请求到达，那么再次调用epoll_wait是不会通知listen_fd可读的，于是epoll_wait只能睡眠到超时才返回，遗留下来的两个请求一直得不到处理，处于饿死状态。

5.3.4 ET vs LT - 总结

最后总结一下，ET和LT模式下epoll_wait返回的条件

ET - 对于读操作
[1] 当接收缓冲buffer内待读数据增加的时候时候(由空变为不空的时候、或者有新的数据进入缓冲buffer)

[2] 调用epoll_ctl(EPOLL_CTL_MOD)来改变socket_fd的监控事件，也就是重新mod socket_fd的EPOLLIN事件，并且接收缓冲buffer内还有数据没读取。(这里不能是EPOLL_CTL_ADD的原因是，epoll不允许重复ADD的，除非先DEL了，再ADD)
因为epoll_ctl(ADD或MOD)会调用sk的poll逻辑来检查是否有关心的事件，如果有，就会将该sk加入到epoll的ready_list中，下次调用epoll_wait的时候，就会遍历到该sk，然后会重新收集到关心的事件返回。

ET - 对于写操作
[1] 发送缓冲buffer内待发送的数据减少的时候(由满状态变为不满状态的时候、或者有部分数据被发出去的时候)
[2] 调用epoll_ctl(EPOLL_CTL_MOD)来改变socket_fd的监控事件，也就是重新mod socket_fd的EPOLLOUT事件，并且发送缓冲buffer还没满的时候。

LT - 对于读操作
LT就简单多了，唯一的条件就是，接收缓冲buffer内有可读数据的时候
LT - 对于写操作
LT就简单多了，唯一的条件就是，发送缓冲buffer还没满的时候
在绝大多少情况下，ET模式并不会比LT模式更为高效，同时，ET模式带来了不好理解的语意，这样容易造成编程上面的复杂逻辑和坑点。因此，建议还是采用LT模式来编程更为舒爽。