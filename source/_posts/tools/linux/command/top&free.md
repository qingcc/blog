[原文链接](http://www.linuxboy.net/linuxjc/147057.html)

[TOC]

## `top` 查看cpu占用情况

在linux中，有一个命令允许您查看系统中的资源是如何使用(或浪费)的，我想快速解释一下如何监视运行在您机器上的进程。

## 统一查看正在运行进程的命令行工具- `top`

用法：

```
top -hv | -bcHiOSs -d secs -n max -u|U user -p pid(s) -o field -w [cols]
```

top命令使用过程中，还可以使用一些交互的命令来完成其它参数的功能。这些命令是通过快捷键启动的。
> ＜空格＞：立刻刷新。  
P：根据CPU使用大小进行排序。  
T：根据时间、累计时间排序。  
q：退出top命令。  
m：切换显示内存信息。  
t：切换显示进程和CPU状态信息。  
c：切换显示命令名称和完整命令行。  
M：根据使用内存大小进行排序。  
W：将当前设置写入~/.toprc文件中。这是写top配置文件的推荐方法。  


`top` 命令可以精确地查看正在计算机上运行的进程，以及内存使用情况、CPU消耗和有关使用的交换内存的详细信息。


```
top

#output

top - 11:50:33 up 23 days, 17:30,  1 user,  load average: 0.11, 0.12, 0.14
Tasks:  87 total,   1 running,  52 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.4 us,  2.0 sy,  0.0 ni, 95.6 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :  2037516 total,    81348 free,   479964 used,  1476204 buff/cache
KiB Swap:        0 total,        0 free,        0 used.  1369232 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                                                                       
 1126 root      10 -10  128280  13188   8264 S  1.7  0.6 380:38.35 AliYunDun                                                                                     
 3083 root      20   0  336584  82644  45548 S  1.0  4.1   9:40.74 kubelet                                                                                       
 3032 kube      20   0  296404  72844  44184 S  0.7  3.6   7:44.29 kube-controller                                                                               
 2849 etcd      20   0   10.4g 159696  17264 S  0.3  7.8   4:34.00 etcd                                                                                          
 3162 root      20   0  301168  65844  43824 S  0.3  3.2   7:53.74 kube-proxy                                                                                    
13347 kube      20   0  156564 118888  34912 S  0.3  5.8   5:04.31 kube-apiserver                                                                                
31541 root      20   0       0      0      0 I  0.3  0.0   0:00.02 kworker/0:2-eve                                                                               
    1 root      20   0   51740   5344   4012 S  0.0  0.3   3:58.95 systemd                                                                                       
    2 root      20   0       0      0      0 S  0.0  0.0   0:00.12 kthreadd
```

### 1. 系统正常运行时间和系统平均负载

第一行显示了系统的正常运行时间，即系统运行了多少小时或几天

```
top - 11:50:33 up 23 days, 17:30,  1 user,  load average: 0.11, 0.12, 0.14
```
比如，正在运行的状态显示以下：

> 11:50:33 当前时间
> 
> 23 days, 17:30 系统启动运行的时间
> 
> 1 user 表示有1个用户正在使用系统
> 
> 接下来的3个值显示了最后1分钟/5分钟/15分钟的平均负载:0.11, 0.12, 0.14

### 2. 监控任务状态

第二行提供关于系统中实际加载的进程状态的信息

```
Tasks:  87 total,   1 running,  52 sleeping,   0 stopped,   0 zombie
```

基本上，数字附近的单词是任务的当前状态。

### Linux怎么查看正在运行的进程占用的CPU

第三行代表系统中CPU状态的简要概述。

```
%Cpu(s):  2.4 us,  2.0 sy,  0.0 ni, 95.6 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

每个参数表示cpu状态的不同指示符，简单来说，这就是它们的含义：

> us 用户空间占用CPU的百分比
> 
> sy 内核空间占用CPU的百分比
> 
> ni nice 改变过优先级的进程占用CPU的百分比
> 
> id 空闲CPU百分比
> 
> wa IO等待占用CPU的百分比
> 
> hi 硬中断（Hardware IRQ）占用CPU的百分比
> 
> si 软中断（Software Interrupts）占用CPU的百分比
> 
> st 偷取时间——由于每个现代CPU都支持虚拟化，所以这个索引指的是管理程序偷取的CPU数量，用于执行运行虚拟机之类的任务。

### 怎么查看内存使用率，物理和交换空间

下面两行代码概述了系统中物理内存和交换内存的内存状态。

由于现代系统大量使用缓存，您将更有可能经常看到物理内存几乎被占满了。

相反，当物理内存不能处理更多的东西时，交换空间是一种“备份”，因此它被迫在磁盘上写东西以避免丢失。如果交换空间的使用高，这是一个清楚的警告，表明某些事情没有按照预期进行。

这一行是指物理内存:

```
KiB Mem :  2037516 total,    81348 free,   479964 used,  1476204 buff/cache
```

第四行,内存状态，具体信息如下：

> 2037516 total — 物理内存总量（2GB）
> 
> 479964 used — 使用中的内存总量（479MB）
> 
> 81348 free — 空闲内存总量（81MB）
> 
> 1476204 buffers — 缓存的内存量 （1.47GB）

下一行就是给出交换内存的信息

```
KiB Swap:        0 total,        0 free,        0 used.  1369232 avail Mem 
```

> 0 total — 交换区总量（0K）
>
> 0 used — 使用的交换区总量（0K）
> 
> 0 free — 空闲交换区总量（0K）
> 
> 0 cached — 缓冲的交换区总量（0K）

好了，我们的想查看的进程在哪里?

在这里，前面几行之外的列表表示在您的系统上正在运行的进程、守护进程和服务的列表，每一行都带有关于单个进程的变量说明。以下是我的查看记录:

```
  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                                                                       
 1126 root      10 -10  128280  13188   8264 S  1.7  0.6 380:38.35 AliYunDun                                                                                     
 3083 root      20   0  336584  82644  45548 S  1.0  4.1   9:40.74 kubelet                                                                                       
 3032 kube      20   0  296404  72844  44184 S  0.7  3.6   7:44.29 kube-controller                                                                               
 2849 etcd      20   0   10.4g 159696  17264 S  0.3  7.8   4:34.00 etcd                                                                                          
 3162 root      20   0  301168  65844  43824 S  0.3  3.2   7:53.74 kube-proxy                                                                                    
13347 kube      20   0  156564 118888  34912 S  0.3  5.8   5:04.31 kube-apiserver 
```

以上输出结果提供了关于在您的系统上正在运行的进程的各种信息。

> PID – 进程的ID号  
USER – 显示用户正在运行的进程  
PR – 此指示符显示进程优先级，如果您在输出结果中看到“rt”表示进程具有实时优先级，则此指示符用于系统进程。  
NI – 指示是否使用命令nice来增强给定进程的优先级。  
VIRT – 指进程使用的虚拟内存的数量，这意味着它在内存中存储数据、库和交换的页面  
RES – 物理内存上有多少进程处于“RES”状态  
SHR – 指示为进程共享的内存段的大小  
S – 当前正在运行的进程的状态  D =不可中断的睡眠状态 R =运行 S =睡眠 T =跟踪/停止 Z =僵尸进程   
%CPU – 共享cpu运行给定正在运行进程所花费的时间百分比  
%MEM – 正在运行的进程使用的物理内存的百分比  
%TIME+ – cpu运行给定正在运行的进程所花费的总时间  
COMMAND – 用于初始化进程的命令  

我该怎么处理这些信息呢?

收集到这些正在运行的进程信息后，这些信息将帮助您排除各种问题，比如内存/CPU/泄漏、OOM错误，或者仅仅是了解当时正在运行的进程。

当然，你可以结合grep命令过滤和定制你想要看的内容，比如

```
top |grep NI 
```

可以看到，`top` 命令是一个功能十分强大的监控系统的工具，对于系统管理员而言尤其重要。但是，它的缺点是会消耗很多系统资源。


`free` 命令用来显示内存的使用情况，使用权限是所有用户

```
free [－b　－k　－m] [－o] [－s delay] [－t] [－V]
```

> ｃ.主要参数  
－b －k －m -g：分别以字节（KB、MB）为单位显示内存使用情况。  
－h 以人类能看懂的格式显示（自动转换为GB或MB）  
－s delay：显示每隔多少秒数来显示一次内存使用情况。  
－t：显示内存总和列。  
－o：不显示缓冲区调节列。  

`free` 命令是用来查看内存使用情况的主要命令。和 `top` 命令相比，它的优点是使用简单，并且只占用很少的系统资源。通过 `－S` 参数可以使用 `free` 命令不间断地监视有多少内存在使用，这样可以把它当作一个方便实时监控器。

```
free －b －s 5
```
使用这个命令后终端会连续不断地报告内存使用情况（以字节为单位），每5秒更新一次。

