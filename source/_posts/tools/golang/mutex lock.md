# mutex lock

`go` 语言以并发作为其特性之一，并发必然会带来对于资源的竞争，这时候我们就需要使用 `go` 提供的
 `sync.Mutex` 这把互斥锁来保证临界资源的访问互斥。

既然经常会用这把锁，那么了解一下其内部实现，就能了解这把锁适用什么场景，特性如何了。

`sync.Mutex` 是把公平锁


## 字段定义

sync.Mutex 只包含两个字段：
```go
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
type Mutex struct {
	state int32
	sema	uint32
}

const (
	mutexLocked = 1 << iota // mutex is locked
	mutexWoken
	mutexStarving
	mutexWaiterShift = iota

	starvationThresholdNs = 1e6
)
```

其中 `state` 是一个表示锁的状态的字段，这个字段会同时被多个 `goroutine` 所共用（使用 `atomic.CAS` 来保证原子性），
第 0 个 `bit`（1）表示锁已被获取，也就是已加锁，被某个 `goroutine` 拥有；
第 1 个 `bit`（2）表示有 `goroutine` 被唤醒，尝试获取锁；
第 2 个 `bit`（4）标记这把锁是否为饥饿状态。  
如下所示：
```
1111 1111 ...... 1111 1111
\_________29__________/|||
 存储等待 goroutine 数量 ||表示当前 mutex 是否加锁
                       |表示当前 mutex 是否被唤醒
                       表示 mutex 当前是否处于饥饿状态
```

`sema` 字段就是用来唤醒 `goroutine` 所用的信号量

## 互斥锁的设计理念

 - CAS原子操作。
 - 需要有一种阻塞和唤醒机制。
 - 尽量减少阻塞和唤醒切换成本。
 - 锁尽量公平，后来者要排队。即使被后来者插队了，也要照顾先来者，不能有“饥饿”现象。

 ### 尽量减少阻塞和唤醒切换成本
 减少切换成本的方法就是不切换，简单而直接。
 
 不切换的方式就是让竞争者自旋。自旋一会儿，然后抢锁。不成功就再自旋。到达上限次数才阻塞。
 
### canSpin
接下来我们来看看 `canSpin` 条件如何：

```go
// Active spinning for sync.Mutex.
//go:linkname sync_runtime_canSpin sync.runtime_canSpin
//go:nosplit
func sync_runtime_canSpin(i int) bool {
	// 这里的active_spin是个常量，值为4
	// 简单来说，sync.Mutex是有可能被多个goroutine竞争的，所以不应该大量自旋(消耗CPU)
	// 自旋的条件如下：
	// 1. 自旋次数小于active_spin(这里是4)次；
	// 2. 在多核机器上；
	// 3. GOMAXPROCS > 1并且至少有一个其它的处于运行状态的P；
	// 4. 当前P没有其它等待运行的G；
	// 满足以上四个条件才可以进行自旋。
	if i >= active_spin || ncpu <= 1 || gomaxprocs <= int32(sched.npidle+sched.nmspinning)+1 {
		return false
	}
	if p := getg().m.p.ptr(); !runqempty(p) {
		return false
	}
	return true
}

```

###mutex.lock模式

>
> 公平锁
>
> 锁有两种模式：正常模式和饥饿模式。  
> 在正常模式下，所有的等待锁的goroutine都会存在一个先进先出的队列中（轮流被唤醒）  
> 但是一个被唤醒的goroutine并不是直接获得锁，而是仍然需要和那些新请求锁的（new arrivial）  
> 的goroutine竞争，而这其实是不公平的，因为新请求锁的goroutine有一个优势——它们正在CPU上  
> 运行，并且数量可能会很多。所以一个被唤醒的goroutine拿到锁的概率是很小的。在这种情况下，  
> 这个被唤醒的goroutine会加入到队列的头部。如果一个等待的goroutine有超过1ms（写死在代码中）  
> 都没获取到锁，那么就会把锁转变为饥饿模式。  
>
> 在饥饿模式中，锁的所有权会直接从释放锁(unlock)的goroutine转交给队列头的goroutine，  
> 新请求锁的goroutine就算锁是空闲状态也不会去获取锁，并且也不会尝试自旋。它们只是排到队列的尾部。
>
> 如果一个goroutine获取到了锁之后，它会判断以下两种情况：
> 1. 它是队列中最后一个goroutine;  
> 2. 它拿到锁所花的时间小于1ms;  
> 
>以上只要有一个成立，它就会把锁转变回正常模式。  
>
> 正常模式会有比较好的性能，因为即使有很多阻塞的等待锁的goroutine，
> 一个goroutine也可以尝试请求多次锁。
> 饥饿模式对于防止尾部延迟来说非常的重要。

除了这两种模式。还有一个`Woken`(唤醒标记)。它主要用于**自旋状态的通知**和**锁公平性的保证**。分两个角度理解：

一、新的`g`申请锁时，发现锁被占用了。但自己满足自旋条件，于是自己自旋，并设置上的`Woken`标记。
此时占用锁的`g`在释放锁时，检查`Woken`标记，如果被标记。哪怕现在锁上面的阻塞队列不为空，也不做唤醒。
直接`return`，让自旋着的`g`有更大机会抢到锁。
```go
if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken|mutexStarving) != 0 {
		return
}
```
二、释放锁时，检查Woken标记为空。而阻塞队列里有`g`需要被唤醒。那么在唤醒时，同时标记锁`Woken`。
这里可能有疑问，原来没有`Woken`标记，为什么在唤醒一个`g`要主动标记呢？目的是保证锁公平。

考虑这样的场景：现在阻塞队列里只有一个`g`。把它唤醒后，还得等调度器运行到它，它自己再去抢锁。
但在调度器运行到它之前，很可能新的竞争者参与进来，此时锁被抢走的概率就很大。

这有失公平，被阻塞的`g`是先到者，新的竞争者是后来者。应该尽量让它们一起竞争。

```go
// 唤醒一个阻塞的goroutine，并把锁的Woken标记设置上
new = (old - 1<<mutexWaiterShift) | mutexWoken
```
设置`Woken`标记后，`state`就肯定不为零。此时新来的竞争者，在执行`Lock()`的`fast-path`时会失败，接下来就只能乖乖排队了。

```go
func (m *Mutex) Lock() {
	// Fast path: grab unlocked mutex.
	// Woken标记设置后，这里的CAS就会为false
	if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
		// ...
		return
	}
  // 接下来在阻塞里排队
}
```

小总结：为了减少切换成本，短暂的自旋等待是简单的方法。而竞争者在自旋时，要主动设置`Woken`标记。这样释放者才能感知到。


### 锁尽量公平
为什么不是绝对公平？要绝对公平的粗暴做法就是在锁被占用后，其它所有竞争者，包括新来的，全部排队。

但排队的问题也很明显，排队阻塞唤醒的切换成本(这是损耗性能的潜在的隐患，下面`Mutex`的问题有举例)。
假如临界区代码执行只需要十几个时钟周期时，让竞争者自旋等待一下，立刻就可以获得锁。减少不必要的切换成本，效率更高。

尽量公平的结果就是阻塞的竞争者被唤醒后，也要与(正在自旋的)新竞争者抢夺锁资源。


go使用三种手段保证Mutex锁尽量公平：

1. 上面介绍的，在锁释放时，主动设置`Woken`标记，防止新的竞争者轻易抢到锁。
2. 竞争者进阻塞队列策略不一样。新的竞争者，抢不到锁，就排在队列尾部。先来竞争者，从队列中被唤醒后，还是抢不到锁，就放在队列头部。
3. 任何竞争者，被阻塞等待的时间超过指定阀值(1ms)。锁就转为饥饿模式。这时锁释放时会唤醒它们，手递手式把锁资源给它们。别的竞争者（包括新来的）都抢不到。直到把饥饿问题解决掉。

### Mutex带来的问题
饥饿问题是会积压的。要尽快解决。当每次持锁时间过长时，会导致饥饿问题的积压(越来越多的`g`超时积压)
假设在业务某个场景中，对每个请求都需要访问某互斥资源。使用`Mutex`锁时，如果`QPS`很高，
阻塞队列肯定会很满。虽然`QPS`可能会降，但请求是持续的。

新来的请求，在访问互斥资源时有可能抢锁成功，后来者胜于先到者。这种情况持续发生的话，就会导致阻塞队列中所有的请求得不到处理，
耗时增高，直至超出上游设置的超时时间，一下子失败率突增，上游再影响它的上游，引起连锁反应进而服务故障异常。

解决方案要根据实际业务场景来优化。**削减锁的粒度**；或者**使用CAS的方式进队列，然后阻塞在通道上**；或者**使用无锁结构**等等。

阻塞在**通道**而不是阻塞在**锁**上，是因为`go`的`runtime`对待锁唤醒和通道唤醒`g`的效率是不一样的。这也引出了还有一种方案是改
`runtime`，让锁唤醒的`g`更快地得到执行。毕竟上面问题点是被唤醒的`g`和新的`g`在竞争中不能保证稳胜，被唤醒的`g`会有一个调度耗时，
减少耗时就有可能提高竞争成功率。

在下一步真正看源代码之前，我们必须要理解一点：当一个 `goroutine` 获取到锁的时候，有可能没有竞争者，也有可能会有很多竞争者，
那么我们就需要站在不同的 `goroutine` 的角度上去考虑 `goroutine` 看到的锁的状态和实际状态、期望状态之间的转化。

### 阻塞和唤醒机制 (没看懂。。。)
go的阻塞和唤醒是`semacquire`和`semrelease`。虽然命名上是`sema`，但实际用途却是一套阻塞唤醒机制。
```
// That is, don't think of these as semaphores.
// Think of them as a way to implement sleep and wakeup
```

`go`的`runtime`有一个全局变量`semtable`，它放置了所有的信号量。
```go
var semtable [semTabSize]struct {
	root semaRoot
	pad  [sys.CacheLineSize - unsafe.Sizeof(semaRoot{})]byte
}

func semacquire1(addr *uint32, lifo bool, profile semaProfileFlags)
func semrelease1(addr *uint32, handoff bool)
```
每个信号量都由一个变量地址指定。`Mutex`就是用成员`sema`的地址。

在阻塞时，调用`semacquire1`，把地址(`addr`)传给它。

如果`addr`大于1，并且通过`CAS`减一成功，那就说明获取信号量成功。不用阻塞。

否则，`semacquire1`会在`semtable`数组中找一个元素和它对应上。每个元素都有一个`root`，这个`root`是`Treap`树（`ACM`同学应该熟悉）。

最后`addr`变成一个树节点，这个树节点，有自己的一个队列，专门放被阻塞的`goroutine`。叫它阻塞队列吧。

这个阻塞队列是个双端队列，头尾都可以进。

`semacquire1`把当前`goroutine`相关元数据放进阻塞队列之后，就挂起了。

`semrelease1`是给`addr` `CAS`加一。

如果坚持发现当前`addr`上有阻塞的`g`时，就取一个出来，唤醒它，让它自己再去`semacquire1`。这是`handoff`为`false`的情况。

但`handoff`为`true`的话，就尝试手递手地把信号量送给这个`g`。等于说`g`不用再自己去抢了，因为自己再去抢有可能抢不到。

最后`semrelease1`会把取出来的这个`g`挂在当前`P`的本地待运行队列尾部，等待调度执行。

就是这样，在获取不到`Mutex`锁时，通过信号量来阻塞和唤醒`g`。


## lock 源码

在看代码之前，我们需要有一个概念：每个 `goroutine` 也有自己的状态，存在局部变量里面（也就是函数栈里面），
`goroutine` 有可能是新到的、被唤醒的、正常的、饥饿的。

```go
// Lock locks m.
// If the lock is already in use, the calling goroutine
// blocks until the mutex is available.
func (m *Mutex) Lock() {
	// Fast path: grab unlocked mutex.
	if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
		if race.Enabled {
			race.Acquire(unsafe.Pointer(m))
		}
		return
	}
	
	var waitStartTime int64 // 用来存当前goroutine等待的时间
	starving := false       // 用来存当前goroutine是否饥饿
	awoke := false          // 用来存当前goroutine是否已唤醒
	iter := 0               // 用来存当前goroutine的循环次数(想一想一个goroutine如果循环了2147483648次咋办……)
	old := m.state          // 复制一下当前锁的状态
	// 自旋
	for {
		// 如果是饥饿情况之下，就不要自旋了，因为锁会直接交给队列头部的goroutine
		// 如果锁是被获取状态，并且满足自旋条件（canSpin见后文分析），那么就自旋等锁
		// 伪代码：if isLocked() and isNotStarving() and canSpin()
		if old&(mutexLocked|mutexStarving) == mutexLocked && runtime_canSpin(iter) {
			// 将自己的状态以及锁的状态设置为唤醒，这样当Unlock的时候就不会去唤醒其它被阻塞的goroutine了
			if !awoke && old&mutexWoken == 0 && old>>mutexWaiterShift != 0 &&
				atomic.CompareAndSwapInt32(&m.state, old, old|mutexWoken) {
				awoke = true
			}
			// 进行自旋(分析见后文)
			runtime_doSpin()
			iter++
			// 更新锁的状态(有可能在自旋的这段时间之内锁的状态已经被其它goroutine改变)
			old = m.state
			continue
		}
		
		// 当走到这一步的时候，可能会有以下的情况：
		// 1. 锁被获取+饥饿 (饥饿状态不会进入上面的if条件)
		// 2. 锁被获取+正常 (runtime_canSpin()返回false，比如自旋次数超过4次)
		// 3. 锁空闲+饥饿   (饥饿状态不会进入上面的if条件)
		// 4. 锁空闲+正常   (正常模式下，锁空闲不会进入上面的if条件)
		
		// goroutine的状态可能是唤醒以及非唤醒
		
		// 复制一份当前的状态，目的是根据当前状态设置出期望的状态，存在new里面，
		// 并且通过CAS来比较以及更新锁的状态
		// old用来存锁的当前状态
		new := old

		// 如果说锁不是饥饿状态，就把期望状态设置为被获取(获取锁)
		// 也就是说，如果是饥饿状态，就不要把期望状态设置为被获取(饥饿状态会把锁移交给队列头的goroutine)
		// 伪代码：if isNotStarving()
		if old&mutexStarving == 0 {
			// 伪代码：newState = locked
			new |= mutexLocked
		}
		// 如果锁是被获取状态，或者饥饿状态
		// 就把期望状态中的等待队列的等待者数量+1(实际上是new + 8)
		// (会不会可能有三亿个goroutine等待拿锁……)
		if old&(mutexLocked|mutexStarving) != 0 {
			new += 1 << mutexWaiterShift
		}
		// 如果说当前的goroutine是饥饿状态，并且锁被其它goroutine获取
		// 那么将期望的锁的状态设置为饥饿状态
		// 如果锁是释放状态，那么就不用切换了
		// Unlock期望一个饥饿的锁会有一些等待拿锁的goroutine，而不只是一个
		// 这种情况下不会成立
		if starving && old&mutexLocked != 0 {
			// 期望状态设置为饥饿状态
			new |= mutexStarving
		}
		// 如果说当前goroutine是被唤醒状态，我们需要reset这个状态
		// 因为goroutine要么是拿到锁了，要么是进入sleep了
		if awoke {
			// 如果说期望状态不是woken状态，那么肯定出问题了(若awoke为true，则锁必定是woken状态)
			// 会将awoke设置为true的只有2个对方，
			// 1. 新g在自旋时，若state的woken位为0时(先将woken位置为1，成功后才将本g的awoke设为true)
            // 2. 在沉睡的g被唤醒时，正常模式下，只有当state的woken位为0，才会唤醒沉睡的g(先设置state的woken位，再唤醒)
            // 饥饿模式下，将state置为饥饿模式的g必然是从沉睡中被唤醒的(该g为woken状态)，此时，新g不会去自旋并将本身g的awoke置为1，unlock时，直接唤醒队头的g即可
			if new&mutexWoken == 0 {
				throw("sync: inconsistent mutex state")
			}
			// 这句就是把new设置为非唤醒状态
			// &^的意思是and not
			new &^= mutexWoken
		}
		// 通过CAS来尝试设置锁的状态
		// 这里可能是设置锁，也有可能是只设置为饥饿状态和等待数量
		if atomic.CompareAndSwapInt32(&m.state, old, new) {
			// 如果说old状态不是饥饿状态也不是被获取状态
			// 那么代表当前goroutine已经通过CAS成功获取了锁
			// (能进入这个代码块表示状态已改变，也就是说状态是从空闲到被获取)
			if old&(mutexLocked|mutexStarving) == 0 {
				break // locked the mutex with CAS
			}
			// 如果之前已经等待过了，那么就要放到队列头
			queueLifo := waitStartTime != 0
			// 如果说之前没有等待过，就初始化设置现在的等待时间
			if waitStartTime == 0 {
				waitStartTime = runtime_nanotime()
			}
			// 既然获取锁失败了，就使用sleep原语来阻塞当前goroutine
			// 通过信号量来排队获取锁
			// 如果是新来的goroutine，就放到队列尾部
			// 如果是被唤醒的等待锁的goroutine，就放到队列头部
			runtime_SemacquireMutex(&m.sema, queueLifo) // 根据 queueLifo = true or false 来判断是放到队列头还是队列尾
			
			// 这里sleep完了，被唤醒
			
			// 如果当前goroutine已经是饥饿状态了
			// 或者当前goroutine已经等待了1ms（在上面定义常量）以上
			// 就把当前goroutine的状态设置为饥饿
			starving = starving || runtime_nanotime()-waitStartTime > starvationThresholdNs
			// 再次获取一下锁现在的状态(从沉睡被唤醒，锁的状态大概率是变动了)
			old = m.state
			// 如果说锁现在是饥饿状态，就代表现在锁是被释放的状态，当前goroutine是被信号量所唤醒的
			// 也就是说，锁被直接交给了当前goroutine
			if old&mutexStarving != 0 {
				// 饥饿模式下，本goroutine被唤醒, 锁的状态必定是未唤醒、未锁定状态(**暂时未看懂**)
				// 那么是不可能的，肯定是出问题了，因为当前状态肯定应该有等待的队列，锁也一定是被释放状态且未唤醒
				if old&(mutexLocked|mutexWoken) != 0 || old>>mutexWaiterShift == 0 {
					throw("sync: inconsistent mutex state")
				}
				// 当前的goroutine获得了锁，那么就把等待队列-1
				delta := int32(mutexLocked - 1<<mutexWaiterShift)
				// 如果当前goroutine非饥饿状态，或者说当前goroutine是队列中最后一个goroutine
				// 那么就退出饥饿模式，把状态设置为正常
				if !starving || old>>mutexWaiterShift == 1 {
					// Exit starvation mode.
					// Critical to do it here and consider wait time.
					// Starvation mode is so inefficient, that two goroutines
					// can go lock-step infinitely once they switch mutex
					// to starvation mode.
					delta -= mutexStarving
				}
				// 原子性地加上改动的状态
				atomic.AddInt32(&m.state, delta)
				break
			}
			// 这里是当前goroutine被唤醒， 且是正常模式(饥饿模式会进入上面的if并break)，需要把当前的goroutine 中awoke设为被唤醒
			// 并且重置iter(重置spin)
			awoke = true
			iter = 0
		} else {
			// 如果CAS不成功，也就是说没能成功获得锁，锁被别的goroutine获得了或者锁一直没被释放
			// 那么就更新状态，重新开始循环尝试拿锁
			old = m.state
		}
	}

	if race.Enabled {
		race.Acquire(unsafe.Pointer(m))
	}
}
```

## Unlock 源码
Unlock方法释放所申请的锁

```go
func (m *Mutex) Unlock() {
	// mutex 的 state 减去1，加锁状态 -> 未加锁
	new := atomic.AddInt32(&m.state, -mutexLocked)
	// 未 Lock 直接 Unlock，报 panic
	if (new+mutexLocked)&mutexLocked == 0 {
		throw("sync: unlock of unlocked mutex")
	}
	// mutex 正常模式
	if new&mutexStarving == 0 {
		old := new
		for {
			// 如果没有等待者，或者已经存在一个 goroutine 被唤醒或得到锁，或处于饥饿模式
			// 无需唤醒任何处于等待状态的 goroutine
			if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken|mutexStarving) != 0 {
				return
			}
			// 等待者数量减1，并将唤醒位改成1
			new = (old - 1<<mutexWaiterShift) | mutexWoken
			if atomic.CompareAndSwapInt32(&m.state, old, new) {
				// 唤醒一个阻塞的 goroutine，但不是唤醒第一个等待者
				runtime_Semrelease(&m.sema, false)
				return
			}
			old = m.state
		}
	} else {
		// mutex 饥饿模式，直接将 mutex 拥有权移交给等待队列最前端的 goroutine
		runtime_Semrelease(&m.sema, true)
	}
}
```

## 总结
根据以上代码的分析，可以看出，`sync.Mutex` 这把锁在你的工作负载（所需时间）比较低，比如只是对某个关键变量赋值的时候，性能还是比较好的，
但是如果说对于临界资源的操作耗时很长（特别是单个操作就大于 1ms）的话，实际上性能上会有一定的问题，
这也就是我们经常看到 “锁一直处于饥饿状态” 的问题，对于这种情况，可能就需要另寻他法了。

好了，至此整个 `sync.Mutex` 的分析就此结束了，虽然只有短短 200 行代码（包括 150 行注释，实际代码估计就 50 行），
但是其中的算法、设计的思想、编程的理念却是值得感悟，所谓大道至简、少即是多可能就是如此吧。

## 参考文章
[GO 夜读](https://reading.hidevops.io/articles/sync/sync_mutex_source_code_analysis/)  
[mutex lock](https://www.purewhite.io/2019/03/28/golang-mutex-source/)  
[golang中的锁源码实现：Mutex](http://legendtkl.com/2016/10/23/golang-mutex/)  
[Golang 并发编程与同步原语](https://www.infoq.cn/article/q40qmeoqxfpsdccgm0ba)  
[golang sync.Mutex锁如何实现goroutine的阻塞与唤醒初探](https://blog.csdn.net/liyunlong41/article/details/104949898)  
[信号量的结构](https://studygolang.com/articles/33190)  
[一份详细注释的go Mutex源码](https://zhuanlan.zhihu.com/p/75263302)