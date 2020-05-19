[原文链接](https://blog.csdn.net/pysense/java/article/details/103840680)

前言
  在前面两篇文章《gevent与协程》和《asyncio与协程》，讨论了有关协程异步编程方面的内容，从代码层面和基本的demo可以大致理解协程的工作方式。如果要深入理解为何单线程基于事件的驱动可以在“低能耗”的条件下达到高性能的IO服务，则要研究Linux底层实现原理——IO多路复用，而理解IO多路复用的前提是对文件描述符有较为深入的理解，因此本文把文件描述符和IO多路复用放在同一篇文章里，形成全局的体系化认知，这就是本文讨论的内容。

# 1、理解文件描述符

## 1.1 基本概念
  
在Linux中，一切皆文件，而理解文件描述符才能理解“一切皆文件”的真实含义，IO多路复用的select、poll和epoll机制正是通过操作文件描述符集合来处理IO事件。
含义，这里引用百度的介绍：

  文件描述符是一个索引号，是一个非负整数，它指向普通的文件或者I/O设备，它是连接用户空间和内核空间纽带。在linux系统上内核（kernel）利用文件描述符（file descriptor）来访问文件。打开现存文件或新建文件时，内核会返回一个文件描述符。读写文件也需要使用文件描述符来指定待读写的文件。（在Windows系统上，文件描述符被称作文件句柄）

当你看完本篇内容后，再回它这段解释，总结得真到位！在后面会给出为何文件描述符是一个非负整数，而不是其他更为复杂数据结构呢（例如hash map、list、链表等）？

## 1.2 打开一个文件

  当某个进程打开一个已有文件或创建一个新文件时，内核向该进程返回一个文件描述符（一个非负整数）。
(在程序设计中，一些涉及底层的程序编写往往会围绕着文件描述符展开。但是文件描述符这一概念往往只适用于UNIX、Linux这样的操作系统。)
这里以打开的iPython shell进程调用os.open为例，OS是Centos7.5

```
In [1]: import os
In [6]: fd = os.open( "/opt/test.txt", os.O_RDWR|os.O_CREAT) # os.O_RDWR读写模式打开，os.O_CREAT若文件不存在则创建               
In [7]: fd                                                                             
Out[7]: 17 # 这个17就是file descriptor
```

在Python里面，os.open方法返回文件描述符是更为底层API，而open方法是返回python文件对象，是更贴近用户的API。

在linux系统上查看以上iPython进程打开的所有文件描述符示例：（这里就是一个文件描述表的大致形式，每一个文件描述符指向一个文件或者设备）

```
[root@nn opt]# ll /proc/11622/fd #11622为ipython的shell进程
total 0
lrwx------ 1 root root 64 **** 16:43 0 -> /dev/pts/0
lrwx------ 1 root root 64 **** 16:43 1 -> /dev/pts/0
lr-x------ 1 root root 64 **** 16:43 10 -> pipe:[41268]
l-wx------ 1 root root 64 **** 16:43 11 -> pipe:[41268]
lrwx------ 1 root root 64 **** 16:43 12 -> anon_inode:[eventpoll]
lrwx------ 1 root root 64 **** 16:43 13 -> socket:[41269]
lrwx------ 1 root root 64 **** 16:43 14 -> socket:[41270]
lr-x------ 1 root root 64 **** 16:43 15 -> pipe:[41271]
l-wx------ 1 root root 64 **** 16:43 16 -> pipe:[41271]
l-wx------ 1 root root 64 **** 16:43 17 -> /opt/test.txt
lrwx------ 1 root root 64 **** 16:43 18 -> /opt/test.txt
lrwx------ 1 root root 64 **** 16:43 19 -> /opt/test.txt
lrwx------ 1 root root 64 **** 16:43 2 -> /dev/pts/0
lrwx------ 1 root root 64 **** 16:43 20 -> anon_inode:[eventpoll]
l-wx------ 1 root root 64 **** 16:43 3 -> /dev/null
lrwx------ 1 root root 64 **** 16:43 4 -> /root/.ipython/profile_default/history.sqlite
lrwx------ 1 root root 64 **** 16:43 5 -> /root/.ipython/profile_default/history.sqlite
lrwx------ 1 root root 64 **** 16:43 6 -> anon_inode:[eventpoll]
lrwx------ 1 root root 64 **** 16:43 7 -> socket:[41266]
lrwx------ 1 root root 64 **** 16:43 8 -> socket:[41267]
lrwx------ 1 root root 64 **** 16:43 9 -> anon_inode:[eventpoll]
```

因为在ipython里面，fd = os.open( "/opt/test.txt", os.O_RDWR) 运行3次，也就文件/opt/test.txt打开3次，所以返回个文件描述符:17、18、19（从这里说明，同一进程可以同一时刻打开同一文件多次）

11622进程号指向当前iPython shell，查看它打开的文件描述符18，指向被打开文件：/opt/test.txt：

```
[root@nn opt]# ll /proc/11622/fd/18 
lrwx------ 1 root root 64 **** 16:43 /proc/11622/fd/18 -> /opt/test.txt
```

关闭文件描述符就关闭了所打开的文件

```
In [14]: os.close(19)                                                                  
In [15]: os.close(18)                                                                  
In [16]: os.close(17)
```

## 1.3 对文件描述符进行读写

读：通过给定文件描述符读文件内容

```
"""
# os.read()方法的docstring
os.read()
Signature: os.read(fd, length, /)
Docstring: Read from a file descriptor.  Returns a bytes object.
Type:      builtin_function_or_method
"""
import os
fd=os.open('/opt/test.txt',os.O_RDWR|os.O_CREAT)
data=os.read(fd,64) #指定读文件前64byte内容 
print(data) # b'foo\nbar\n\n'
```

写：通过给定文件描述符将数据写入到文件

```
"""
# os.read()方法的docstring
Signature: os.write(fd, data, /)
Docstring: Write a bytes object to a file descriptor.
Type:      builtin_function_or_method
"""
import os
fd=os.open('/opt/test.txt',os.O_RDWR|os.O_CREAT)
byte_nums=os.write(fd,b'save data by file descriptor directly \n') # 注意要写入byte类型的数据
print(byte_nums) # 返回写入byte字符串长度（字符个数）
```

了解基本调用底层的os读写文件描述符的方法，也可以封装出一个类似内建open方法的定制myopen类。

## 1.4 通过管道打开文件描述符

也可以通过管道pipe方法（创建一个无名管道）同时打开一个读文件描述符以及一个写文件描述符。（有关管道的定义和理解本文不再累赘，可参考其他博文。）

```
import os
fd_read,fd_write=os.pipe()
print('fd_read:',fd_read,'fd_write:',fd_write) #系统返回两个整数3、4， fd_read: 3 fd_write: 4
os.write(fd_write,b'foo') # 向管道的写端写入数据
os.read(fd_read,64) # 从管道的读端读取数据
```

创建管道时总是返回相邻的两个整数，因为stderr为2，故之后创建的文件描述符只能从3开始，示意图如下：

如果尝试向管道另外一端的fd_write描述符读取数据，就会报错，所以对于管道，读数据只能在读文件描述符上读操作，写入数据只能在写文件描述符操作。

```
os.read(fd_write,64)
OSError: [Errno 9] Bad file descriptor
```

如果已经把fd_read读取完好后，此时管道为空，若再读取该管道，进程会被阻塞，因为写管道端没有数据写入，这是管道的性质之一——数据一旦被读走，便不在管道中存在，若此时还继续向读端反复读取，则进程会被阻塞。

注意写入管道的字符个数是有限制的，当超过管道容量时，写入操作被阻塞，可以通过以下方法精确策略出

```
import os
def get_pipe_capacity(size):
    fd_read,fd_write=os.pipe()
    total=0
    print("start to count")
    for i in range(1,size+1):
        os.write(fd_write,b'a')
        total=i
        
    print("end to count,total bytes:",total)

get_pipe_capacity(64*1024)
输出：
start to count
end to count,total bytes: 65536
```

往管道写入64*1024 大小的byte时，管道写端未发生阻塞，当把写入的byte数改为：写入64*1024+1时，写入操作被阻塞了

```
get_pipe_capacity(64*1024+1)
输出:
start to count # 执行流被阻塞，无后续输出。
```

通过该方法可以精确测量出pipe默认容量为64KB。
看到这部内容，是否有人联想到在使用subprocess执行某些cmd命令后，一直卡在读取输出上？
常见用法：

```
p= subprocess.Popen(your_cmd, shell= True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE) # 问题出现在：标准输出
使用了管道，而管道有容量限制，当命令返回的数据大小超过管道64KB时，执行流卡在这里
bytes_result, err = p.communicate(timeout=1)
str_result = str(bytes_result, encoding="utf-8")
if p.returncode != 0:
    pass
if not str_result:
    return False
else:
    return True
```

问题出现在：subprocess.Popen标准输出使用了管道，而管道有容量限制，当你的your_cmd返回的数据大小超过管道64KB时（stdout获取返回数据，用了管道存放），执行流卡在subprocess.Popen这里，其实进程阻塞了。
既然知道管道有容量限制，那么可以将stdout定向到本地文件系统，那么输出的数据就存放到容量更大的文件，建议使用临时文件作为重定向输出，如下所示：

```
def stdout_by_tempfile():
    # SpooledTemporaryFile也是一个普通文件对象，当然支持with协议（它的源码实现了__enter__和__exit__方法）
    with tempfile.SpooledTemporaryFile(buffering=1*1024) as tf:
    """创建一个临时文件对象，注意这个bufferfing不是限制只能存储1024字节的数据，而是输出内容超过1024字节后，自动将输出的数据缓存到临时文件里"""
        try:
            fd = tf.fileno() # 返回文件描述符，这个文件描述符不再指向管道，而是指向某个临时文件
            p = subprocess.Popen(your_cmd,stdin=fd,stdout=fd,stderr=fd,shell=True) # 将stdout输出的内容定向到文件描述符指向的文件
            p.communicate(timeout=5) # 指定输出超时时间
            tf.seek(0) # 将文件对象指针放置起始位置，以便读取从头到尾的完整的已存数据
            output_data = tf.readlines() # 一次读取临时文件的所有数据（这是读取的是byte类型），也可用迭代器（如果数据上几百M）这里tf就是普通文件对象，因为也有readlines、readline、write、tell等常见文件操作方法
            save_to_db(output_data) # 将your_cmd输出的数据存到db或者其他地方
            return True
        except Exception as e:
            return False
```

经过对文件描述符的讨论，现在你可以轻松“操作进程的stdin或者stdout”

## 1.5 常见的文件描述符0、1、2

  在Linux系统上，每个进程都有属于自己的stdin、stdout、stderr。标准输入（standard input）的文件描述符是 0，标准输出（standard output）是 1，标准错误（standard error）是 2。尽管这种习惯并非Unix内核的特性，但是因为一些 shell 和很多应用程序都使用这种习惯，因此，如果内核不遵循这种习惯的话，很多应用程序将不能使用。

  在上面的iPython例子中，ll /proc/11622/fd 其实是列出属于11622进程的文件描述符表，可以看到，每个进程拥有的fd数值从0到linux限制的最大值，其中每个进程自己的0、1、2就是用于当前进程的标准输入、标准输出和标准错误。

关于文件描述符表简单介绍：操作系统内核为每个进程在u_block结构中维护文件描述符表，所有属于该进程的文件描述符都在该表中建立索引:数值–>某个文件。你可以把整个文件描述表看成是一个C语言的数组，数组的元素指向文件引用，数组的下表就是它的文件描述符

下面，已iPython的一个shell进程为例，如何将stdin、stdout、stderr的0、1、2替换为其他文件描述符：

# 也可以用sys模块，例如：sys.stdout.fileno() 

```
In [4]: stdin_fd=os.sys.stdin.fileno() # 当前iPython shell进程的标准输入

In [5]: stdin_fd
Out[5]: 0

In [6]: stdout_fd=os.sys.stdout.fileno() #当前iPython shell进程的标准输出

In [7]: stdout_fd
Out[7]: 1

In [8]: stderr_fd=os.sys.stderr.fileno() #当前iPython shell进程的标准错误

In [9]: stderr_fd
Out[9]: 2
```

os.sys.stdin等是什么呢？其实这些对象跟open(file_name,mode) 打开文件返回的文件对象是一样的，例如下面：os.sys.stdin是以utf-8编码的只读模式的文件对象，os.sys.stdout以及os.sys.stderr是以utf-8编码的写模式的文件对象，既然是文件对象，那么读对象就支持read、readline等方法，写对象则支持write等方法

```
In [21]: os.sys.stdin
Out[21]: <_io.TextIOWrapper name='<stdin>' mode='r' encoding='UTF-8'>

In [22]: os.sys.stdout
Out[22]: <_io.TextIOWrapper name='<stdout>' mode='w' encoding='UTF-8'>

In [23]: os.sys.stderr
Out[23]: <_io.TextIOWrapper name='<stderr>' mode='w' encoding='UTF-8'>
```

将文件描述符2：stdout替换为其他打开某个文件的文件描述符：
```
In [2]: f=open('/opt/test.txt','w')
In [3]: f.fileno()
Out[3]: 11

In [4]: os.sys.stdout=f
In [5]: os.sys.stdout.fileno() # 输出不再打印到当前shell，而且写入文件：/opt/test.txt
In [7]: print('stdout redirect to file') # 输出不再打印到当前shell，而且写入文件：/opt/test.txt
In [8]: os.sys.stdout # 输出不再打印到当前shell，而且写入文件：/opt/test.txt
```

查看/opt/test.txt文件内容
```
 % cat test.txt

11

stdout redirect to file

<_io.TextIOWrapper name='/opt/test.txt' mode='w' encoding='UTF-8'>
```

可以看到当前进程os.sys.stdout标准输出不再是2，而是11，指向某个已打开的文件。
当拿到一个已知的文件描述符后（一个非负整数），那么可以调用os.write(fd,bstr)方法向fd指向的文件写入数据，例如向文件描述符为11写入b’foo’字符串

```
In [11]: os.write(11,b'foo\n')
1
查看文件/opt/test.txt内容：

% cat test.txt

11

stdout redirect to file

<_io.TextIOWrapper name='/opt/test.txt' mode='w' encoding='UTF-8'>
foo
3
```

这一小节内容是想表述这么一个逻辑：如果要进程要对文件写入数据、或者读取数据（这不就是IO吗），底层必须通过文件描述符来实现，这就为讨论IO多路复用提供很好的知识背景，因为IO多路复用就是涉及到client向server写入数据，或者从server读取数据的需求。

## 1.6 进程打开文件描述符的个数

  文件描述符的有效范围是 0 到 OPEN_MAX。centos7.5默认每个进程最多可以打开 1024个文件（0 -1023）。对于 FreeBSD 、Mac OS X 和 Solaris 来说，每个进程最多可以打开文件的多少取决于系统内存的大小，int 的大小，以及系统管理员设定的限制。Linux 2.4.22 强制规定最多不能超过 1,048,576 。

调整文件描述符打开数量的限制：

管理用户可以在 `etc/security/limits.conf` 配置文件中设置他们的文件描述符极限，如下例所示。

```
softnofile 10240
hardnofile 20480
```

系统级文件描述符极限还可以通过将以下三行添加到 `/etc/rc.d/rc.local` 启动脚本中来设置：

```
\#Increasesystem-widefiledescriptorlimit.
echo4096>/proc/sys/fs/file-max
echo16384>/proc/sys/fs/inode-max
```

在一些基于IO事件实现的高性能中间件例如redis、nginx、gevent等，在其官方的调优教程，一般会建议将系统打开文件描述符的数量设为大值，以便发挥并发性能。

## 1.7 文件描述符底层原理

  之所以将文件描述符的底层原理放在本节最后讨论，是考虑到，当前面的内容你已经理解后，那么再讨论背后原理，将更容易理解。
  总结1.2~1.6的内容：

进程只有拿到文件描述符才能向它指向的物理文件写入数据或者读取数据，然后再把这些数据用socket方式（通过网卡）远程传输给client。
文件描述符就是操作系统为了高效管理已打开文件所创建的一个索引。给os.wirte传入fd，进程非常迅速通过fd找到已打开的文件，进程高效率了，作为操作系统当然也更高效管理这些进程。
  那么不禁会提问：为什么进程只有拿到文件描述符才能向它指向的物理文件写入数据或者读取数据？本节内容回答此问题，相关图或者表述参考这些文章：[《Linux中文件描述符的理解(文件描述符、文件表项、i-node)》](https://blog.csdn.net/qq_28114615/article/details/94590598)（推荐这篇文章，作者从源码的角度解析fd的理解）、[《Linux文件描述符到底是什么？》](https://blog.csdn.net/wan13141/article/details/89433379)

  基本知识背景：理解数组、指针、结构体以及内存，c语言的结构体像Python的类，都是为了封装属性和方法，形成一个“具备多个功能”的object。
原理
  一个 Linux 进程启动后，它在内核中每一个打开的文件都需要由3种数据结构支撑运行：

每个进程对应一张打开文件描述符表，属于进程级的数据结构，进程通过调用系统IO方法（传入文件描述符）访问文件数据（用户态切到内核态）；

内核维持一张打开文件表，文件表由多个文件表项组成，属于系统级数据结构，该文件表创建者和管理由内核负责，每个进程可共享；

每个打开的文件对应一个i-node数据结构，系统通过i-node可以取到位于磁盘的数据（用于返回给用户态，内核态切回用户态），存在于内核中。
（机智的小伙伴应该联想到这个技术点：为何用户程序读取文件数据，会出现用户态到内核态切换，然后再由内核态转到用户态？上面3个表可以回答这个问题）

三者的关系图如下：

![Image](https://img-blog.csdnimg.cn/20200105184452579.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3B5c2Vuc2U=,size_16,color_FFFFFF,t_70)

文件描述符表
  在Linux中，对于每一个进程，都会分配一个PCB（进程控制块——Processing Control Block），在C代码实现上，这个数据结构名为task_struct，它里面有一个成员变量*files(属于files_struct类型)，files_struct的指针又指向一个指针数组fd_array，数组每一个元素都是一个指向file类型的指针，该进程打开的每个文件都属于file类型。从这里得出：
所谓文件描述符，就是fd_array[NR_OPEN_DEFAULT]这个指针数组的索引号，这也回答了为何文件描述符为非负整数。

task_struct类型-->*files指针(files_struct类型)-->fd_array(文件描述符表)
task_struct类型的定义(省略部分代码)：

```
struct task_struct {
	......
	struct files_struct *files; 
	......
};
```

files_struct类型的定义(省略部分代码)：

```
struct files_struct {
	......
	int next_fd; #进程新打开一个文件对应的文件描述符
	struct file __rcu * fd_array[NR_OPEN_DEFAULT]; //进程级打开文件描述符表
	......	
};
```

系统级文件表
  每一个打开的文件都对应于一个file结构体（c语言上用结构体，而其他高级语言例如python或者java则称为file类型或者file对象），在该结构体中，f_flags描述了文件标志，f_pos描述了文件的偏移位置，而在f_path中有含有一个指向一个inode结点的指针，因此f_path非常关键，它直接指向物理文件存储的inode节点。
文件表指向逻辑大致如下：
file类型 --> f_path变量（path类型 --> *dentry指针（dentry类型）--> d_inode指针（inode类型）

file类型的定义(省略部分代码)：

```
struct file {
	......	
	struct path		f_path;     //属于path类型，包括目录项以及i-node
	atomic_long_t		f_count;  //文件打开次数
	fmode_t			f_mode;   //文件打开时的mode，对应于open函数的mode参数
	......		
};
```

path类型的定义(省略部分代码)：

```
struct path {
	struct vfsmount *mnt;
	struct dentry *dentry;//目录项
};
```

dentry类型的定义(省略部分代码)：

```
struct dentry {
	......	
	struct inode *d_inode;
	struct super_block *d_sb;	/* The root of the dentry tree *
 	......	
};
```

从以上“file类型嵌套链”可知：进程打开一个文件后，系统给它返回一个文件描述符fd，进程通过fd调用系统io方法，系统（内核）通过f_path再到dentry指针找到物理文件的inode，从而找到相应的数据块。

系统级的文件i-node表
  继续上面内容，内核找到i-node节点后，就能获取文件数据块在磁盘上的位置以及文件大小等文件的元数据信息，使得进程能够根据已打开文件对应的文件描述符一路定位到磁盘上相应文件的位置，从而进行文件读写。
inode类型的定义(省略部分代码)：

```
struct inode {
    .......
	umode_t			i_mode;     //权限
	uid_t			i_uid;      //用户id
	gid_t			i_gid;      //组id
    .......
	unsigned long		i_ino;   //inode节点号
	loff_t			i_size;   //文件大小
	.......
	struct timespec		i_atime;  //最后一次访问(access)的时间
	struct timespec		i_mtime;  //最后一次修改(modify)的时间
	struct timespec		i_ctime;  //最后一次改变(change)的时间
    .......	
	blkcnt_t		i_blocks;    //块数
	struct address_space	*i_mapping;   //块地址映射
```

上面有Linux文件常见的基本属性，例如访问时间、修改时间、权限、属主等，系统级的文件表里每一个文件表项都会指向i-node，这个i-node对应磁盘中的一个物理文件。

# 本节小结

  到处，有关文件描述符的底层原理介绍完毕，本节内容也只是抛砖引玉，读者可自行去检索Linux文件系统原理或者VFS虚拟文件系统原理等底层文件系统知识(从这里联想到不得不佩服Apache开发hdfs文件系统的大咖团队，他们对Linux文件系统的底层实现应该且必须是绝对掌握的)。如果你能理解以上全部内容，那么在第2部分的IO多路复用中提到的大部分概念，将不再晦涩难懂。

# 2、 IO多路复用原理

  IO：input和output，一般指数据的写入、数据的读取。IO主要分为两类：硬盘 IO和网络IO，本内容主要针对网络 IO。复用的含义？复用当然理解为重复使用某个事物，而在本文，这个事物是一个线程，因此，IO多路复用，是指并发的socket连接复用一个IO线程(换句话说：只需要一个线程，即可为多个client同时提供socket连接请求)。在第1章节中，如果用户程序要将数据写入或者读取数据，那么它在底层必须通过文件描述符才能达到相应操作结果，因此IO多路复用与文件描述符密切相连，这就是为何在第一章节里给出了大量有关文件描述符知识的原因。

## 2.1 IO触发用户空间与内核空间之间的切换

在本博客前面有关大数据项目的文章里，其中《深入理解kafka》提到kafka通过通过sendfile（零拷贝机制）提高消费者端的吞吐量，其中就提到用户空间与内核空间之间的切换，结合第1章节内容简要介绍：


用户程序通过系统调用获得网络和文件的数据
内核负责网络和文件数据的读写

```
file_path='/opt/test.txt' # 上下文为用户空间
fd=os.open(file_path,os.O_RDWR|os.O_CREAT) # 用户空间切换到内核空间
data=os.read(fd,64) #指定读文件前64byte内容  # 上下文从用户空间切换到内核空间，数据准备好后，上下文再从内核空间再切换到用户空间
print(data) # 上下文为用户空间
```

对于os.read的过程，用文件描述符的背景也可以理解：read底层用fd读取文件数据的流程：进程级文件描述符，到系统级文件表，再到系统级i-node表。从进程级到系统级，这里从代码层面展示用户空间到内核的空间的上下文切换
所以只要有网络IO或者磁盘IO，必然会发生用户空间到内核空间的上下文切换。

图的原理参考
https://www.cnblogs.com/yanguhung/p/10145755.html

## 2.2 IO模型的介绍

IO模型基本分类：
（1）Blocking I/O（同步阻塞IO）：最常见也最传统IO模型，即代码语句按顺序执行若某一条语句执行需等待那么后面的代码会被阻塞，例如常见顺序步骤：读取文件、等待内核返回数据、拿到数据、处理输出
（2）同步非阻塞IO（Non-blocking IO）：默认创建的socket为阻塞型，将socket设置为NONBLOCK，业务流程则变为同步非阻塞IO
（3）IO多路复用（IO Multiplexing ）：即经典的Reactor设计模式，有时也称为异步阻塞IO，Java中的Selector和Linux中的epoll都是这种模型。
（4）异步IO（Asynchronous IO）：即经典的Proactor设计模式，也称为异步非阻塞IO
这里也给出个人在知乎看到一篇关于IO模型更为形象的回答：链接，通过购买火车票的场景来介绍5种IO模型（本章节未提到的信号驱动的IO模型）

https://mp.weixin.qq.com/s/E3PYOSCuO4O6JB2FpHyZCg

同步和异步
  同步是指用户线程发起IO请求后需要等待或者轮询内核IO操作完成后才能继续执行；例如内核读文件需要耗时10秒，那么用户线程发起读取文件IO后，等待内核从磁盘拷贝到内存10秒，接着用户线程才能进行下一步对文件内容进行其他操作，按顺序执行。
  而异步是指用户线程发起IO请求后仍继续执行，当内核IO操作完成后会通知用户线程，或者调用用户线程注册的回调函数。

阻塞和非阻塞
  阻塞是指内核空间IO操作需要为把数据返回到用户空间；而非阻塞是指IO操作被调用后立即返回给用户一个状态值，无需等到IO操作彻底完成。

以下为四个模型的内容，图和部分文参考此篇《英文原文文章》

同步阻塞IO
  同步阻塞IO模型是最简单的IO模型，如图1所示：  用户线程通过系统调用recvfrom方法向内核发起IO读文件操作（application switch to kernel），后面的代码被阻塞，用于线程处于等待当中，当内核已经从磁盘拿到数据并加载到内核空间，然后将数据拷贝到用户空间（kernel switch to application），用户线程再进行最后的data process数据处理。

同步阻塞IO模型的伪代码描述为：

read(socket, buffer) # 执行流被阻塞，直到buffer有数据可以读或者内核抛给用户程序一个error信号，程序才会往下执行。
process(buffer) 
1
2
缺点分析：
  用在多线程高并发场景（例如10万并发），服务端与客户端一对一连接，对于server端来说，将大量消耗内存和CPU资源（用户态到内核态的上下文切换），并发能力受限。

同步非阻塞IO
  同步非阻塞IO是在同步阻塞IO的基础上，将socket设置为NONBLOCK。这样做用户线程可以在发起IO请求后可以立即返回，原理图如下：

  在该图中，用户线程前面3次不断发起调用recvfrom，内核还未准备好数据，因此只能返回error of EWOULDBLOCK，直到最后一次调用recvfrom时，内核已经将数据拷贝到用户buffer端，此次可读取到数据，接下来就是process the data。

同步非阻塞IO模型的伪代码描述为：

while true:
        try:
        	streaming_data=read(buffer)
    	 	do_someting(streaming_data)
    		do_foo(streaming_data)	    
    		do_bar(streaming_data)     
	    except error of EWOULDBLOCK:
	         print('kernel not ready for data yet,going to next loop')
	         pass
    	sleep(0.1)
1
2
3
4
5
6
7
8
9
10
该模式有两个明显的缺点：

  第一点：即client需要循环system call，尝试读取socket中的数据，直到读取成功后，才继续处理接收的数据。整个IO请求的过程中，虽然用户线程每次发起IO请求后可以立即返回，但是为了等到数据，仍需要不断地轮询、重复请求。如果有10万个客户端连接，那么将消耗大量的serverCPU资源和占用带宽。

  第二点：虽然设定了一个间隔时间去轮询，但也会发生一定响应延迟，因为每间隔一小段时间去轮询一次read操作，而任务可能在两次轮询之间的任意时间就已经完成，这会导致整体数据吞吐量的降低。

  （以上的流程就像你在Starbucks店点了一杯cappuccino ，付款后，咖啡师正在制作中，而你却每隔0.1秒从座位走到点餐台问咖啡师OK了没，以至于你根本无法腾出时间享受用一台MacBook Pro优雅的coding的下午茶美好时光。当然如果仅有你1个人以这种方式去询问，咖啡师应该还可以接受（假设“客户是上帝这个真理“在Starbucks能够严格实施）。假设有10万个客户，都以这方式去轮询咖啡师，想象下画面…）

IO多路复用模式
  前面两种模式缺点明显，那么 IO多路复用模式就是为了解决以上两种情况，IO多路复用是指内核一旦发现进程指定的一个或者多个IO事件准备读取，它就通知该进程，原理图如下：
  前面两种IO模型用户线程直接调用recvfrom来等待内核返回数据，而IO复用则通过调用select（还有poll或者epoll）系统方法，此时用户线程会阻塞在select语句处，等待内核copy数据到用户态，用户再收到内核返回可读的socket文件描述符，伪代码如下：

while true:
	all_fds=select()# 执行流在此处阻塞，当之前注册的socket文件描述符集合有其中的fd发生IO事件，内核会放回所有fds（注意：select不会返回具体发生IO事件的fd，需要用户线程自行查找）
    for each_fd in all_fds:
        if can_read(fd):  # 遍历内核返回每个socket文件描述符对象来判断到底是哪个流产生的IO事件。
        	process_data(fd) # 找到了发生IO事件的文件描述符fd

1
2
3
4
5
6
此IO模型优点：
  用户线程终于可以实现一个线程内同时发起和处理多个socket的IO请求，用户线程注册多个socket，（对于内核就是文件描述符集合），然后不断地调用select读取被激活的socket 文件描述符。（在这里，select看起就像是用户态和内核态之间的一个代理）
缺点在下文会谈到。

IO多路复用适用场景：
  从Redis、Nginx等这些强大的用于高并发网络访问的中间件可知，IO多路复用目前使用最突出的场景就是：socket连接，也即web服务，一般指高性能网络服务。
  与多进程和多线程技术的简单粗暴的业务实现不同，I/O多路复用技术的最大优势是系统开销小，系统不必创建多进程或者多线程，也不必维护这些进程/线程的复杂上下文以及内存管理，从而大大减小了系统的开销，极大提升响应时间。

3、深入理解select、poll
  上面第2节内容提到了IO多路复用的基本工作原理，目前linux支持I/O多路复用的系统调用常见有 select，poll，epoll（linux2.4内核前主要是select和poll，epoll方法则是从Linux 2.6内核引入），它们都是实现这么一个逻辑：一个进程可以监听多个文件描述符（10k-100k不等，看服务器性能），一旦某个文件描述符就绪（一般是读就绪或者写就绪），内核返回这些可读写的文件描述符给到用户线程，从而让用户线程进行相应的读写操作，这一过程支持并发请求。
下面就linux实现IO多路复用三种方式进行详细讨论：

理解select函数
  select：在一段时间内，监听用户线程感兴趣的文件描述符上面的可读、可写和异常等事件，在这里通过简单介绍其C接口的用法即可理解select功能，API：

#include <sys/select.h>
int select（int nfds, fd_set * readfds, fd_set * writefds, fd_set * exceptfds, struct timeval * timeout);
1
2
函数参数解释，参考文章
nfds：
  非负整数的变量，表示当前线程打开的所有件文件描述符集的总数，nfds=maxfdp+1，计算方法就是当前线程打开的最大文件描述符+1

*readfds:
  fd_set集合类型的指针变量，表示当前线程接收到内核返回的可读事件文件描述符集合（有数据到了这个状态称之为读事件），如果这个集合中有一个文件可读，内核给select返回一个大于0的值，表示有文件可读，如果没有可读的文件，则根据timeout参数再判断是否超时，若内核阻塞当前线程的时长超出timeout，select返回0，若发生错误返回负值。传入NULL值，表示不关心任何文件的读变化

*writefd:
  当前有多少个写事件（关心输出缓冲区是否已满）
最后一个结构体表示每个几秒钟醒来做其他事件，用来设置select等待时间

*exceptfds：
  监视文件描述符集合中的有抛出异常的fd

timeout：
  select()的超时结束时间，它可以使select处于三种状态：
（1）若将NULL以形参传入，select置于阻塞状态，当前线程一直等到内核监视文件描述符集合中某个文件描述符发生变化为止；
（2）若将时间值设为0秒0毫秒，表示非阻塞，不管文件描述符是否有变化，都立刻返回继续执行，文件无变化返回0，有变化返回一个正值；
（3）timeout的值大于0，等待时长，即select在timeout时间内阻塞，超时后返回-1，否则在超时后不管怎样一定返回。

select函数返回值：
  执行成功则返回绪的文件描述符的总数。如果在超过时间内没有任何文件描述符准备就绪，将返回0；失败则返回-1并设置errno；若在select等待事件内程序接收到信号，则select立即返回-1，并设置errno为EINTER。
（从这里可以得出：写C的同学尤其是Unix 网络开发方向，对什么select、poll、epoll早已轻车熟路）

select的优点
  select目前几乎在所有的平台上支持，其良好跨平台支持。

select的缺点

（1）打开的文件描述符有最大值限制
  默认1024，当然可自行设为较大值，例如10万，取决于服务器性内存和cpu配置。

（2）对socket进行扫描时是线性扫描，即采用轮询的方法，效率较低。
  当一个线程发起socket请求数较大时例如100，用户线程每次select()都会触发server端的内核遍历所有文件描述符，如果有1万个client发起这种IO请求，server的内核要遍历1万*100=100万的文件描述符。可想而知这种时间复杂度为o(n)是非常低效率的。
（3）第2点说了，当并发量大时，服务端提供server socket连接的进程需要维护一个用来存放大量fd的数据结构（参考1.7章节的内容：task_struct类型-->*files指针(files_struct类型)-->fd_array(文件描述符表)），会导致用户态和内核态之间在传递该数据结构时复制占用内存开销大。
https://www.itnotebooks.com/?p=1106

理解poll函数
本节内容部分参考《poll函数解析》，oll函数的定义：

int poll(struct pollfd *fds, nfds_t nfds, int timeout);
1
pollfd类型定义：

　　struct pollfd{
　　int fd;              //文件描述符：socket或者其他输入设备的对应fd
　　short events;    //用户向内核注册感兴趣的事件（读事件、写事件、异常事件）
　　short revents;   //内核返回给用户注册的就绪事件
　　};
1
2
3
4
5
events有以下三大类：
例如fd=10，events=POLLRDNORM
revents：返回用户在调用poll注册的感兴趣且已就绪的事件

参数说明：
pollfd类型的*fds变量：传入socket的文件描述符，用户线程通过fds[i].events注册感兴趣事件(可读、可写、异常)，
nfds:
跟select的nfds参数相同
timeout:
INFTIM:永远等待
0:立即返回，不阻塞
大于0:等待给定时长

函数返回值：
成功时，poll() 返回结构体中 revents事件不为 0 的文件描述符个数；
如果在超时前没有任何事件发生，poll()返回 0；

工作流程
（1）pollfd初始化，传入socket的文件描述符，设置感兴趣事件event，以及内核revent。设置时间限制（用户线程通过fds[i].events传入感兴趣事件，内核通过修改fds[i].revents向用户线程返回已经就绪的事件）
（2）用户线程调用poll，并阻塞于此处
（3）内核返回就绪事件，并处理该事件

select与poll本质差别不大，只是poll没有最大文件描述符的限制，因为它是基于链表来存储的

poll缺点：
（1）大量的fd的数组被整体复制于用户态和内核地址空间之间，而不管这样的复制是否有意义。
（2）poll还有一个特点是“水平触发”，如果报告了fd后，没有被处理，那么下次poll时会再次报告该fd

这里引用了这篇文章《linux 下 poll 编程》代码来说明poll流程，程序逻辑并不难理解，能够让poll返回就绪的事件，是内核驱动通过中断信号来判断事件是否发生：

```
#include <sys/socket.h>
......
#define OPEN_MAX 1024

int main()
{
    int listenfd, connfd, sockfd, i, maxi;
    char buf[MAXLINE];
    struct pollfd client[OPEN_MAX];//存放客户端发来的所有socket对应的文件描述符，限定最大可用文件描述符1024
    ......
    client[0].fd = listenfd;// 传入socket对应的文件描述符
    client[0].events = POLLRDNORM;//关心监听套机字的读事件
    
    for(;;)
    {
        nready = poll(client, maxi + 1, -1); #server 进程调用poll，用户线程在此处阻塞，直到内核返回就绪的POLLRDNORM事件的文件描述符集合
        if(client[0].revents & POLLRDNORM) # 如果收到内核返回client注册的事件
        {
            connfd = accept(listenfd, (SA *) &cliaddr, &clilen); # 获取每个client socket连接对应的文件描述符
            if(connfd < 0)
            {
                continue;
            }
            for(i = 1; i < OPEN_MAX; ++i)
            {
                if(client[i].fd < 0)
                    client[i].fd = connfd; # 将客户端的请求的fd加到polled这个列表
                break;
            }
            if(i == OPEN_MAX)
            {
                printf("too many clients");
                exit(0);
            }
            client[i].events = POLLRDNORM;# 为客户端的fd注册可读事件
            if(i > maxi)
            {
                maxi = i;
            }
            if(--nready <=0 )
                continue;
        }
        for(i = 1; i < OPEN_MAX; ++i)
        {
            if((sockfd = client[i].fd) < 0)
            {
                continue;
            }
            if(client[i].revents & POLLRDNORM | POLLERR) # server通过轮询所有的文件描述符，如果revents有读事件或者异常事件
            {
                if((n = read(sockfd, buf, MAXLINE)) < 0)# 读取数据
                {
                    if(errno == ECONNRESET)
                    {
                        close(sockfd); # 若该就绪的文件描述符返回的异常事件，则重置
                        client[i].fd = -1;
                    }
                    else
                    {
                        printf("read error!\n");
                    }
                }
                else if(n == 0)
                {
                    close(sockfd);
                    client[i].fd = -1;
                }
                else
                {
                    write(sockfd, buf,  n);
                }
                if(--nready <= 0)
                    break;
            }
        }
    }
}
```

  从上面看，不管select和poll都需要在返回后，都需要通过遍历文件描述符来获取已经就绪的socket（for(i = 1; i < OPEN_MAX; ++i)==>if(client[i].revents & POLLRDNORM | POLLERR)）。事实上，高并发连接中例如10k个连接，在同一时刻可能只有小部分的socket fd处于就绪状态，但server端进程却为此不断的遍历，当注册的描述符数量的增长，其效率也会线性下降。
该图为select、poll和Epoll性能对比（还有一个更高性能的Kqueue）
可以看到，随着socket连接数量增大（对应文件描述符数量也增加），select、poll处理响应更慢，epoll响应速度几乎不受文件描述符数量的影响。

4、深入理解epoll
  考虑到epoll为本文核心内容，而且知识相对更有深度，因此将其单独作为1个章节讨论。部分内容参考的以下文章（吸收多篇文章内容后，你会赞叹epoll设计的精巧）：
《epoll原理详解及epoll反应堆模型》
《Linux下的I/O复用与epoll详解》
《我读过最好的Epoll模型讲解》
《 彻底搞懂epoll高效运行的原理 》

4.1 epoll的c语言接口详解：
这里介绍epoll的IO模型完成创建过程：

int epoll_create(int size);
1
功能说明：创建一个epoll实例，参数size用来指定该epoll对象可以管理的socket文件描述符的个数。在Linux 2.6.8以后的版本中，参数 size 已被忽略，但是必须大于0。

函数返回值：一个代表新创建的epoll实例的文件描述符epoll_fd，这个描述符由server端持有，用于统管所有client请求的socket连接对应的文件描述符

int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);  
1
epfd：epoll_create创建的epoll对象，以文件描述符形式epoll_fd返回，对于一个server进程，它对于只有一个epoll_fd。

op:监听socket时告诉内核要监听针对这个socket（其实是socket对应的文件描述符fd）什么类型的事件，主要有以下三种要监听的事件类型需要注册到epoll_fd上：
– EPOLL_CTL_ADD：注册新的fd到epfd中；
– EPOLL_CTL_MOD：修改已经注册的fd的监听事件；
– EPOLL_CTL_DEL：从epfd中删除一个fd；

fd：epfd需要监听的fd，主要指server为client的socket请求创建对应文件描述符，来一个socket连接就对应新建一个文件描述符，

epoll_event：告诉内核需要对所注册文件描述符的什么类型事件进行监听，和poll函数支持的事件（读、写、异常）类型基本相同，不同是epoll还可以监听两个额外的事件：EPOLLET和EPOLLONESHOT（水平触发和边缘触发），这是epoll高性能的关键，文章后面会深入讨论。epoll_event结构如下：

struct epoll_event {
  __uint32_t events;  /* Epoll的事件类型 */
  epoll_data_t data;  /* User data variable */
};
1
2
3
4
其中events就包括以下事件：

EPOLLIN ： 监听的文件描述符可读（包括client主动向server断开socket连接的事件）

EPOLLOUT： 监听的文件描述符可写；

EPOLLPRI： 监听的文件描述符有紧急的数据可读；

EPOLLERR： 监听的文件描述符有异常事件；

EPOLLRDHUP： 监听的文件描述对应的socket连接被挂断；这里挂断像不像打电话给对方，对方挂断你的电话的意思？没错，这里是指socket连接的client断开了TCP连接（TCP半开），此时epoll监听对应的socket文件描述符会触发一个EPOLLRDHUP事件。（这里也需要给出一个知识：使用 2.6.17 之后版本内核，对端连接断开触发的 epoll 事件会包含 EPOLLIN | EPOLLRDHUP，即 0x2001。有了这个事件，对端断开连接的异常就可以在TCP层进行处理，无需到应用层处理，提高断开响应速度。）
EPOLLET：将EPOLL设为边缘触发模式Edge Triggered，一般用法如下：
ev.events = EPOLLIN|EPOLLET; //监听读状态同时设置ET模式
如果要设为水平触发Level Triggered，只需：
ev.events = EPOLLIN //默认就是水平触发模式

EPOLLONESHOT： 只监听一次事件，当监听完这次事件之后，如果还需要继续监听这个socket文件描述符，需要再次把这个socket加入到EPOLL队列里。

关于epoll_event类型的data用法如下：
定义一个变量ev，类型为struct epoll_event
ev.data.fd = 10;//将要监听的文件描述符绑定到ev.data.fd
ev.events = EPOLLIN|EPOLLET; //监听读状态同时设置ET模式

#include <sys/epoll.h>
int epoll_wait ( int epfd, struct epoll_event* events, int maxevents, int timeout );
1
2
函数返回值：成功时返回有IO（或者异常）事件就绪的文件描述符的数量，如果在timeout时间内没有描述符准备好则返回0。出错时，epoll_wait()返回-1并且把errno设置为对应的值

events：内核检测监听描述符发生了事件，内核将这些描述符的所有就绪事件以events数组返回给用户，。

maxevents：指定最多监听多少个事件类型

timeout：指定epoll的超时时间，单位是毫秒。当timeout为-1是，epoll_wait调用将永远阻塞，直到某个时间发生。当timeout为0时，epoll_wait调用将立即返回。

为更好理解该epoll_wait，这里给个简单epoll工作流程说明：

1、假设socket server进程持有的epoll_fd为3，即epoll_fd=epoll_create(size=1024);
2、假设现有2个client向server发起socket连接，server给它分配的文件描述符是4和5，并且注册的事件为：EPOLLIN可读事件，注册过程如下：
ev.data.fd = 4
ev.events = EPOLLIN
epoll_ctl(epfd=4, op=EPOLL_CTL_ADD, fd=4, &ev);  # 这里不是C语言的写法，只是为了方便说明原理，将关键字参数也列出来，用类似python的参数语法

ev.data.fd = 5
ev.events = EPOLLIN
epoll_ctl(epfd=4, op=EPOLL_CTL_ADD, fd=5, &ev);  
1
2
3
4
5
6
7
3、假设现在文件描述符5可读事件触发（例如内核已经完成将data.log拷贝到用户空间）
4、调用epoll_wait(epfd=3, events,maxevents=10, timeout=-1)，返回1，表示当前内核告诉server进程有1个文件描述符发生了事件，这里events存放的是就绪文件描述符及其事件：
ready_fds=epoll_wait(epfd=3, events,maxevents=10, timeout=-1)
for i in range(ready_fds）：
	ev=events[i] //从内核返回的事件数组中取出epoll_event类型
	print(ev.data.fd) //这里返回的就绪文件描述符是5，对应client的第二个socket连接
	print(ev.evevts）//这里返回EPOLLIN可读事件
	os.read(ev.data.fd)//读取文件描述符5指向的数据
1
2
3
4
5
6
请重点关注第4点，这里可以初步回答epoll适合的场景以及为何epoll比select和poll更高效的原因：（这里说了是初步，第4.2和4.3节将给出更有深度的内容）
  epoll适合的场景：适用于连接数量大且长连接，但活动连接较少的情况。如何解释？在上面的例子中，我们假设了2个client socket连接，现在，我们假设10万个socket连接，而当中”活跃“（就绪）的文件描述符只有100个，调用epoll_wait返回100，接着在for循环里面将非常快速处理完可读事件。
  也就是说，使用epoll的IO效率，不会随着socket连接数（文件描述符connect_fd数量）的增加而降低。因为内核只返回少量活跃就绪的fd才会被回调处理；
  换句话说：epoll几乎跟外部连接总数无关，它只管“就绪”的连接，这就是Epoll的效率就会远远高于select和poll的原因。
  现在大家应该可以理解第3节最后给出的Libevet Benchmark图：100个active条件下，连接的文件描述符从2500到15000，可以看到epoll高性能几乎保持稳定，因为它只需处理这固定的100个就绪的fds，而select和poll，要处理的是从2500个到15000个，因此处理时长也是线性增长，效率越来越低。

简单总结epoll3个方法即可完成高效且并发数高的文件描述符监听的基本流程

A、server端持有可统管所有socket文件描述符的唯一epoll_fd=epoll_create()
B 、epoll_ctl(epoll_fd，添加或者删除所有待监听socket文件描述符以及它们的事件类型)
C、返回有事件发生的就绪文件描述符 =epoll_wait(epoll_fd)
4.2 epoll用红黑树管理所有监听文件描述符
用python设计一个伪epoll模型？
  在4.1介绍epoll的相关函数中，大家应该有这么一个开发者直觉：
每次有新的文件描述符，则将其注册到一个”由内核管理的数据结构“，而且还是向该数据结构添加、删除文件描述符感兴趣的事件。ok，既然提到这个数据结构可以添加、删除，这个直觉告诉我们，内核是否用一个类似python列表（或者链表）的方式来管理所有监听文件描述符呢（其中列表中每项用）？不妨假设epoll就是用python列表管理fds，来讨论”原版epoll“的设计：

epoll_create(size)是内核创建一个python列表
epoll_list= epoll_create(size=100) //全局list变量，用户进程持有，可监听100个外部文件描述符。
假设现在有2个新的外部socket连接请求server，3个tcp的socket连接对应文件描述符为4、5、6，注册事件为EPOLLIN可读
注册过程如下
epoll_list= epoll_create(size=100) 
while True:
	connect_fd=socket_obj.accept().fd
	epoll_ctl(epoll_list, op='EPOLL_CTL_ADD',{'fd':connect_fd,'listen_event':'EPOLLIN'})
	
1
2
3
4
5
op都是添加，说明是向epoll_list进行append操作

由于用户空间持有epoll_list，若内核要处理epoll，需将epoll_list拷贝到内核空间，对于内核，它看到的epoll_list如下：
epoll_list=[ 
{'fd':4,'listen_event':'EPOLLIN'},
{'fd':5,'listen_event':'EPOLLIN'},
{'fd':6,'listen_event':'EPOLLIN'},
]
1
2
3
4
5
假设现在文件描述符4、5可读，最终调用回调函数处理业务：
ready_fds_list=epoll_wait(epoll_list,events,maxevents=10, timeout=-1)# epoll_list又从内核空间拷贝到用户空间，当前仅有2个文件描述符，性能还ok，而且假设返回的是就绪文件描述符列表:
ready_fds_list=[ 
{'fd':4,'listen_event':'EPOLLIN'},
{'fd':5,'listen_event':'EPOLLIN'},
]
for  each_fd in ready_fds_list:
	callback(each_fd)
1
2
3
4
5
6
经过上面4个步骤，我们貌似造出了一个可易于理解的、python版本的epoll。下面介绍原版epoll设计

真epoll设计
第一点：上面简陋python版本epoll，用列表来管理所有监听的文件描述符
epoll_list= epoll_create(size=100)
真实设计：epoll_fd= epoll_create(size=100)，Linux用一个特殊文件描述符，并创建了eventpoll实例，eventpoll里面指向了一个红黑树，这棵树就是用于存放所有监听的文件描述符及其事件。

第二点：上面简陋python版本epoll，用列表来管理所有监听的文件描述符，每次有新的socket连接，注册fd以及获取活动fd都会发生用户态到内核态、内核态到用户态切换：拷贝的对象——epoll_list。假设当前服务器有10万个socket连接请求，那么将发生10万次用户态到内核态切换，以及10万次内核态到用户态的切换，显然效率极低。
真实设计：第一点说了，用epoll_fd指向一颗存放在内核空间的红黑树，如何避免用户态和内核态频繁切换？Linux用mmap()函数解决。mmap将用户空间的一块地址和内核空间的一块地址同时映射到同一块物理内存地址，使得这块物理内存对用户进程和内核均可访问，砍掉用户态和内核态切换的环节（注意区别zero copy）。也就是说内核拿到epoll_fd后，可直接操作epoll_fd指向的红黑树上存放的所有被监听的文件描述符，妙了！
这里说的epoll_fd是如何实现在底层指向一个红黑树呢?
用户进程调用：epoll_fd=epoll_create(size)时，用户进程mmap映射的一块物理地址上就创建一个eventpoll结构体对象，该对象包含一个红黑树的根节点，从而实现epoll_fd由此至终都指向这颗红黑树（内核也可直接访问）：

struct eventpoll{  
    ....  
    /*红黑树的根节点，这颗树的节点存储着epoll_fd所有要监听的文件描述符及该文件描述符关联的其他属性*/  
    struct rb_root  rbr;  
    /*双链表中则存放着将要通过epoll_wait返回给用户的满足条件文件描述符、事件类型*/  
    struct list_head rdlist;  
    /*还有其他成员变量，这里省略了，因为我们更关注存放就绪事件链表和存放被监听的所有文件描述符的红黑树 */
    ....  
};  
1
2
3
4
5
6
7
8
9
  上面的rdllist是一个双向链表，用于存储就绪事件的文描述符。用户进程代码执行epoll_wait时，执行流阻塞（在底层，是内核让进程休眠），直到监听的文件描述符有中断事件发生，内核将这些就绪文件描述符添加到rdlist里面，最后返回用户的是events数组，数组包含就绪的fd及其事件类型。

第三点：用列表存放大量项，但需要进行增或者删除操作时，列表时间复杂度为
  时间复杂度O(N)，想象下10万个连接的时间复杂度
真实设计：Linux为epoll设计了一个红黑树的数据结构，当调用epoll_ctl函数用于添加或者删除一个文件描述符时，对应内核而已，都是在红黑树的节点去处理，而红黑树本身插入和删除性能比列表高，时间复杂度O(logN)，N为树的高度，太巧妙了。
  这个红黑树上的节点存放什么数据呢？每个节点称为epoll item结构，里面的组成如下：
fd:被epoll对象监听的文件描述符（client发起的socket连接对应的文件描述符）
event：要监听该fd的就绪事件，例如前面说的EPOLLIN可读事件
file:在1.6章节提到的系统文件表中，一个文件描述符对应系统文件表中一个文件项，这个文件项就是file类型，用于指向inode）
ready_node:双向链表中一个就绪事件的节点，可指回双向链表。


  用户进程调用epoll_create函数，对应在内核就已经创建了一个全局唯一eventpoll实例（object），对应背后完整的数据结构如下，示意图来源于该文章：
  图中的list就是双向链表，可以清楚看出epoll主要用了两个struct类型（当然不止这2个成员变量，还有锁、等待队列）和两种数据结构，完成高并发IO模型的构建，设计巧妙。因此，如果大家提高个人开发能力以及设计能力，数据结构必须要精通！（这里涉及到内核对红黑树、链表的操作是线程安全的，源码用了锁保操作原子性）

  关于更深入的epoll红黑树以及事件就绪链表等底层的代码实现和图解析，这里有两篇文章，写得很好，作者根据英文原版内容自行理解后的整理：
《Linux内核笔记：epoll实现原理（一）》
《Linux内核笔记：epoll实现原理（二）》
（英文原版的链接现无法访问，地址《the-implementation-of-epoll》 )

4.3 level trigger和edge trigger
  epoll工作模式支持水平触发(level trigger，简称LT，又称普通模式)和边缘触发(edge trigger，简称ET，又称“高速模式”)，而select和poll只支持LT模式。这里说的触发需要通过以下详细的说明来体会其内涵：
level trigger模式的触发条件：

对于读就绪事件，只要用户程序没有读完fd的数据，也即缓冲内容不为空，epoll_wait还会继续返回该fd，让用户程序继续读该fd
对于写就绪事件，只要用户程序未向fd写满数据，也即缓冲区还不满，epoll_wait还会继续返回该fd，让用户程序继续对该fd写操作
原理解释：
  假设当前用户进程添加监听的文件描述符为4，以下简称为4fd，当该4fd有可读可写就绪事件时，epoll_wait()有返回，于是用户程序去进行读写操作，如果当前这一轮用户程序没有把4fd数据一次性全部读写完，那么下一轮调用 epoll_wait()时，它还会返回4fd这个事件对象，让你继续把4fd的缓存区上读或者写。如果用户程序一直不去读写，它会一直通知返回4fd。
参考代码如下：
```
#include <stdio.h>
#include <unistd.h>
#include <sys/epoll.h>

int main(void)
{
　　int epfd,nfds;
　　struct epoll_event ev,events[10]; //ev用于注册事件，数组用于返回要处理的事件
　　epfd = epoll_create(1); //监听标准输入描述符，用于做测试
　　ev.data.fd = STDIN_FILENO; //标准输入描述符绑定到用户data的fd变量
　　ev.events = EPOLLIN; //监听读事件，且默认为LT水平触发事件
　　epoll_ctl(epfd, EPOLL_CTL_ADD, STDIN_FILENO, &ev); //注册epoll事件
　　for(;;)
　　{
　　　　nfds = epoll_wait(epfd, events, 5, -1); //内核返回就绪事件
　　　　for(int i = 0; i < nfds; i++)
　　　　{
　　　　　　if(events[i].data.fd==STDIN_FILENO) //如果返回的事件对象的fd为标准输入fd，则打印字符串，注意到，用户程序没有在缓存区读取数据
　　　　　　　　printf("epoll LT mode");

　　　　}
　　}
}
```
  上面代码最关键的地方：在if(events[i].data.fd==STDIN_FILENO)之后，用户程序没有在标准输入的缓存区读取数据，根据水平触发原理，epoll_wait一直返回STDIN_FILENO这个就绪读事件，该代码最终效果：屏幕标准输出一直打印"epoll LT mode"字符串。
  上面的过程可以解释为何LT模式是epoll工作效率较低的模式，具体说明如下：
  假设除了感兴趣监听的文件描述符4fd，还有另外100个我不需要读写文件描述符（监听它们不代表一定要处理他们的就绪读写事件），最终会出现这样场景：epoll_wait每次都把这100个fd返回，而我只想对4fd进行读写，因此导致程序必须从101个fd中检索出4fd，若这些100fd以更高的优先级返回，那么用户则更晚才能拿到4fd，最终降低业务处理效率。

edge trigger模式的触发条件：

对于读就绪事件，常见触发条件：
缓冲区由空变为不空的时候（有数据可读时）
当有新增数据到达时，即缓冲区中的待读数据变多时

对于写就绪事件，常见触发条件
缓冲区由满变为空的时候（可写）
当有旧数据被发送走，即缓冲区中的内容变少的时

原理解释：
  假设当前用户进程添加监听的文件描述符为4，以下简称为4fd，当该4fd有可读可写就绪事件时，epoll_wait()有返回，于是用户程序去读写操作，如果当前这一轮用户程序没有把4fd数据一次性全部读写完，那么下次调用epoll_wait()时，它不会再返回这个4fd就绪事件，直到在4fd上出现新的可读写事件才会通知你。这种模式比水平触发效率高，系统不会充斥大量你不关心的就绪文件描述符。
参考代码如下：
```
#include <stdio.h>
#include <unistd.h>
#include <sys/epoll.h>

int main(void)
{
　　int epfd,nfds;
　　struct epoll_event ev,events[10]; //ev用于注册事件，数组用于返回要处理的事件
　　epfd = epoll_create(1); //监听标准输入描述符，用于做测试
　　ev.data.fd = STDIN_FILENO; //标准输入描述符绑定到用户data的fd变量
　　ev.events = EPOLLIN|EPOLLET; //监听读事件，而且开启ET触发事件
　　epoll_ctl(epfd, EPOLL_CTL_ADD, STDIN_FILENO, &ev); //注册epoll事件
　　for(;;)
　　{
　　　　nfds = epoll_wait(epfd, events, 5, -1); //内核返回就绪事件
　　　　for(int i = 0; i < nfds; i++)
　　　　{
　　　　　　if(events[i].data.fd==STDIN_FILENO) //如果返回的事件对象的fd为标准输入fd，则打印字符串，注意到，用户程序没有在缓存区读取数据
　　　　　　　　printf("epoll ET mode");

　　　　}
　　}
}
```
  程序运行效果：ev.events = EPOLLIN|EPOLLET，将epoll监听的标准输入文件描述符设为ET模式，当向stdin敲入字符串abc时，缓存区由空转为不空，触发epoll_wait返回就绪事件，而之后用户程序并没有把缓冲区读取数据，根据ET原理，程序只打印一次"epoll ET mode"后就被阻塞。因为epoll_wait只通知一次，下次不再通知用户该4fd事件。除非外界再向stdin敲入字符串以至缓存区新增了数据，epoll_wait就会通知用户这个4fd有就绪事件。

4.4 水平触发和边缘触发的小结
  以某个被监听的文件描述符发生读事件作为示例：

a.对于某个监听的文件描述符fd，假设其指向的读缓冲区初始时刻为空
b. 假设内核拷贝了4KB数据到用户进程的读缓冲区
c.不管水平触发还是边缘触发模式，epoll_wait此时都会返回可读就绪事件
d. 若采用水平触发方式，用户读取了2KB的数据，读缓冲区还剩余2KB数据，epoll_wait还会继续返回（通知）用户fd有可读就绪事件，直到读缓冲变为空为止。
f.若采用边缘触发方式，用户读取了2KB的数据，读缓冲区还剩余2KB数据，epoll_wait不再返回（通知）用户fd有可读就绪事件，除非读缓存区被用户进程或者内核写入新增数据例如1KB（此时读取缓冲变为3KB数据)那么epoll_wait才会通知用户有可读就绪事件。
  到此，已经完成对epoll深入解析的内容，当你掌握这些底层原理后，再回看当前出色中间件或框架如redis、nginx、node.js、tornado等，真香！
————————————————
版权声明：本文为CSDN博主「yield-bytes」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/pysense/java/article/details/103840680