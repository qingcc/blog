# spinlock(自旋锁)

## 自旋锁的定义
当一个线程尝试去获取某一把锁的时候，如果这个锁此时已经被别人获取(占用)，那么此线程就无法获取到
这把锁，该线程将会等待，间隔一段时间后会再次尝试获取。这种采用循环加锁 -> 等待的机制被称为
自旋锁(spinlock)。

## 自旋锁的提出背景
由于在多处理器环境中某些资源的有限性，有时需要互斥访问(mutual exclusion)，这时候就需要引入锁
的概念，只有获取了锁的线程才能够对资源进行访问，由于多线程的核心是CPU的时间分片，所以同一时刻只
能有一个线程获取到锁。那么就面临一个问题，那么没有获取到锁的线程应该怎么办？

通常有两种处理方式：一种是没有获取到锁的线程就一直循环等待判断该资源是否已经释放锁，这种锁叫做自旋锁，
它不用将线程阻塞起来(NON-BLOCKING)；还有一种处理方式就是把自己阻塞起来，等待重新调度请求，这种叫做互斥锁。

## 自旋锁的原理
自旋锁的原理比较简单，如果持有锁的线程能在短时间内释放锁资源，那么那些等待竞争锁的线程就不需要做内核态和用户态之间的切换进入阻塞状态，它们只需要等一等(自旋)，等到持有锁的线程释放锁之后即可获取，这样就避免了用户进程和内核切换的消耗。

因为自旋锁避免了操作系统进程调度和线程切换，所以自旋锁通常适用在时间比较短的情况下。由于这个原因，操作系统的内核经常使用自旋锁。但是，如果长时间上锁的话，自旋锁会非常耗费性能，它阻止了其他线程的运行和调度。线程持有锁的时间越长，则持有该锁的线程将被 OS(Operating System) 调度程序中断的风险越大。如果发生中断情况，那么其他线程将保持旋转状态(反复尝试获取锁)，而持有该锁的线程并不打算释放锁，这样导致的是结果是无限期推迟，直到持有锁的线程可以完成并释放它为止。

解决上面这种情况一个很好的方式是给自旋锁设定一个自旋时间，等时间一到立即释放自旋锁。自旋锁的目的是占着CPU资源不进行释放，等到获取锁立即进行处理。但是如何去选择自旋时间呢？如果自旋执行时间太长，会有大量的线程处于自旋状态占用 CPU 资源，进而会影响整体系统的性能。因此自旋的周期选的额外重要！JDK在1.6 引入了适应性自旋锁，适应性自旋锁意味着自旋时间不是固定的了，而是由前一次在同一个锁上的自旋时间以及锁拥有的状态来决定，基本认为一个线程上下文切换的时间是最佳的一个时间。

## 自旋锁的优缺点
自旋锁尽可能的减少线程的阻塞，这对于锁的竞争不激烈，且占用锁时间非常短的代码块来说性能能大幅度的提升，因为自旋的消耗会小于线程阻塞挂起再唤醒的操作的消耗，这些操作会导致线程发生两次上下文切换！

但是如果锁的竞争激烈，或者持有锁的线程需要长时间占用锁执行同步块，这时候就不适合使用自旋锁了，因为自旋锁在获取锁前一直都是占用 cpu 做无用功，占着 XX 不 XX，同时有大量线程在竞争一个锁，会导致获取锁的时间很长，线程自旋的消耗大于线程阻塞挂起操作的消耗，其它需要 cpu 的线程又不能获取到 cpu，造成 cpu 的浪费。所以这种情况下我们要关闭自旋锁。

CAS（Compare and swap），即比较并交换，也是实现我们平时所说的自旋锁或乐观锁的核心操作。  
它的实现很简单，就是用一个旧的预期的值和内存值进行比较，如果两个值相等，
就用新的值替换内存值，并返回 true。否则，返回 false。

## CAS 实现自旋锁


CAS算法是一种有名的无锁算法。无锁编程，即不使用锁的情况下实现多线程之间的变量同步，也就是在没有
线程被阻塞的情况下实现变量的同步，所以也叫非阻塞同步（Non-blocking Synchronization）。

在多线程环境下，原子操作是保证线程安全的重要手段。

既然用锁可以实现原子操作，那么为什么还要用 CAS 呢，因为加锁带来的性能损耗较大，
而用 CAS 可以实现乐观锁，它实际上是直接利用了 CPU 层面的指令，所以性能很高。

CAS 是实现自旋锁的基础，CAS 利用 CPU 指令保证了操作的原子性，以达到锁的效果，
自旋 就是循环，一般是用一个无限循环实现。这样一来，一个无限循环中，  
执行一个 CAS 操作，当操作成功，返回 true 时，循环结束；  
当返回 false 时，接着执行循环，继续尝试 CAS 操作，直到返回 true。


## 使用场景

CAS 适合简单对象的操作，比如布尔值、整型值等；
CAS 适合冲突较少的情况，如果太多线程在同时自旋，那么长时间循环会导致 CPU 开销很大；

## ABA问题

CAS 存在一个问题，就是一个值从 A 变为 B ，又从 B 变回了 A，
这种情况下，CAS 会认为值没有发生过变化，但实际上是有变化的


[参考文章](https://www.cnblogs.com/cxuanBlog/p/11679883.html)