# mutex lock

`go` 语言以并发作为其特性之一，并发必然会带来对于资源的竞争，这时候我们就需要使用 `go` 提供的
 `sync.Mutex` 这把互斥锁来保证临界资源的访问互斥。

既然经常会用这把锁，那么了解一下其内部实现，就能了解这把锁适用什么场景，特性如何了。

`sync.Mutex` 是把公平锁

## 互斥锁的设计理念

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

在下一步真正看源代码之前，我们必须要理解一点：当一个 `goroutine` 获取到锁的时候，有可能没有竞争者，也有可能会有很多竞争者，
那么我们就需要站在不同的 `goroutine` 的角度上去考虑 `goroutine` 看到的锁的状态和实际状态、期望状态之间的转化。


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

## Lock

在看代码之前，我们需要有一个概念：每个 `goroutine` 也有自己的状态，存在局部变量里面（也就是函数栈里面），
`goroutine` 有可能是新到的、被唤醒的、正常的、饥饿的。


## 核心代码
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

## canSpin
接下来我们来看看上文提到的 canSpin 条件如何：

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

所以可以看出来，并不是一直无限自旋下去的，当自旋次数到达 4 次或者其它条件不符合的时候，就改为信号量拿锁了。

以上为什么 CAS 能拿到锁呢？因为 CAS 会原子性地判断 old state 和当前锁的状态是否一致；
而总有一个 goroutine 会满足以上条件成功拿锁。


## Unlock
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

##没看懂的地方
1. 

## 参考文章
[GO 夜读](https://reading.hidevops.io/articles/sync/sync_mutex_source_code_analysis/)  
[mutex lock](https://www.purewhite.io/2019/03/28/golang-mutex-source/)  
[golang中的锁源码实现：Mutex](http://legendtkl.com/2016/10/23/golang-mutex/)  
[Golang 并发编程与同步原语](https://www.infoq.cn/article/q40qmeoqxfpsdccgm0ba)  
[golang sync.Mutex锁如何实现goroutine的阻塞与唤醒初探](https://blog.csdn.net/liyunlong41/article/details/104949898)  
[信号量的结构](https://studygolang.com/articles/33190)