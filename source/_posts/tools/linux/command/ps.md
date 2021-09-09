[原文链接](https://www.cnblogs.com/peida/archive/2012/12/19/2824418.html)

[TOC]

Linux中的ps命令是Process Status的缩写。ps命令用来列出系统中当前运行的那些进程。ps命令列出的是当前那些进程的快照，
就是执行ps命令的那个时刻的那些进程，如果想要动态的显示进程信息，就可以使用top命令。

要对进程进行监测和控制，首先必须要了解当前进程的情况，也就是需要查看当前进程，而 ps 命令就是最基本同时也是非常强大的进程查看命令。
使用该命令可以确定有哪些进程正在运行和运行的状态、进程是否结束、进程有没有僵死、哪些进程占用了过多的资源等等。总之大部分信息都是可以通过执行该命令得到的。

ps 为我们提供了进程的一次性的查看，它所提供的查看结果并不动态连续的；如果想对进程时间监控，应该用 top 工具。

kill 命令用于杀死进程。

linux上进程有5种状态: 

1. 运行(正在运行或在运行队列中等待) 

2. 中断(休眠中, 受阻, 在等待某个条件的形成或接受到信号) 

3. 不可中断(收到信号不唤醒和不可运行, 进程必须等待直到有中断发生) 

4. 僵死(进程已终止, 但进程描述符存在, 直到父进程调用wait4()系统调用后释放) 

5. 停止(进程收到SIGSTOP, SIGSTP, SIGTIN, SIGTOU信号后停止运行运行) 

ps工具标识进程的5种状态码: 

> D 不可中断 uninterruptible sleep (usually IO)   
R 运行 runnable (on run queue)   
S 中断 sleeping   
T 停止 traced or stopped   
Z 僵死 a defunct (”zombie”) process   

1．命令格式：

```
ps[参数]
```

2．命令功能：

用来显示当前进程的状态

3．命令参数：

> a  显示所有进程  
-a 显示同一终端下的所有程序  
-A 显示所有进程  
c  显示进程的真实名称  
-N 反向选择  
-e 等于“-A”  
e  显示环境变量  
f  显示程序间的关系  
-H 显示树状结构  
r  显示当前终端的进程  
T  显示当前终端的所有程序  
u  指定用户的所有进程  
-au 显示较详细的资讯  
-aux 显示所有包含其他使用者的行程   
-C<命令> 列出指定命令的状况  
--lines<行数> 每页显示的行数  
--width<字符数> 每页显示的字符数  
--help 显示帮助信息  
--version 显示版本显示

4．使用实例：

实例1：显示所有进程信息

命令：

```
ps -A

[root@qing ~]# ps -A
  PID TTY          TIME CMD
    1 ?        00:04:41 systemd
    2 ?        00:00:00 kthreadd
    3 ?        00:00:00 rcu_gp
    ...
```
实例2：列出目前所有的正在内存当中的程序

命令：

```
ps aux

[root@qing ~]# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.2  51740  5320 ?        Ss   Mar24   4:41 /usr/lib/systemd/systemd --systemroot         2  0.0  0.0      0     0 ?        S    Mar24   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        I<   Mar24   0:00 [rcu_gp]
root         4  0.0  0.0      0     0 ?        I<   Mar24   0:00 [rcu_par_gp]
...
```

> USER：该 process 属于那个使用者账号的  
PID ：该 process 的号码  
%CPU：该 process 使用掉的 CPU 资源百分比  
%MEM：该 process 所占用的物理内存百分比  
VSZ ：该 process 使用掉的虚拟内存量 (Kbytes)  
RSS ：该 process 占用的固定的内存量 (Kbytes)  
TTY ：该 process 是在那个终端机上面运作，若与终端机无关，则显示 ?，另外， tty1-tty6 是本机上面的登入者程序，若为 pts/0 等等的，则表示为由网络连接进主机的程序。  
STAT：该程序目前的状态，主要的状态有  
R ：该程序目前正在运作，或者是可被运作  
S ：该程序目前正在睡眠当中 (可说是 idle 状态)，但可被某些讯号 (signal) 唤醒。  
T ：该程序目前正在侦测或者是停止了  
Z ：该程序应该已经终止，但是其父程序却无法正常的终止他，造成 zombie (疆尸) 程序的状态  
START：该 process 被触发启动的时间  
TIME ：该 process 实际使用 CPU 运作的时间  
COMMAND：该程序的实际指令