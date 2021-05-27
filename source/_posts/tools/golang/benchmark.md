#go 性能测试

## 基准测试
基准测试主要是通过测试CPU和内存的效率问题，来评估被测试代码的性能，进而找到更好的解决方案。

### 编写基准测试
```
# go test -v -bench . -benchmem
func BenchmarkSprintf(b *testing.B){
	num:=10
	b.ResetTimer()
	for i:=0;i<b.N;i++{
		fmt.Sprintf("%d",num)
	}
}
```
1. 基准测试的代码文件必须以_test.go结尾
2. 基准测试的函数必须以Benchmark开头，必须是可导出的
3. 基准测试函数必须接受一个指向Benchmark类型的指针作为唯一参数
4. 基准测试函数不能有返回值
5. b.ResetTimer是重置计时器，这样可以避免for循环之前的初始化代码的干扰
6. 最后的for循环很重要，被测试的代码要放到循环里
7. b.N是基准测试框架提供的，表示循环的次数，因为需要反复调用测试的代码，才可以评估性能

```
➜  go test -bench=. -run=none
BenchmarkSprintf-8      20000000               117 ns/op
PASS
ok      flysnow.org/hello       2.474s
```
使用 `go test` 命令，加上 `-bench=` 标记，接受一个表达式作为参数, .表示运行所有的基准测试

因为默认情况下 `go test` 会运行单元测试，为了防止单元测试的输出影响我们查看基准测试的结果，
可以使用 `-run=` 匹配一个从来没有的单元测试方法，过滤掉单元测试的输出，我们这里使用none，
因为我们基本上不会创建这个名字的单元测试方法。

也可以使用 `-run=^$`, 匹配这个规则的，但是没有，所以只会运行benchmark
```
go test -bench=. -run=^$
```
有些时候在benchmark之前需要做一些准备工作，并且，我们不希望这些准备工作纳入到计时里面，
我们可以使用 `b.ResetTimer()`，代表重置计时为0，以调用时的时刻作为重新计时的开始。

看到函数后面的`-8`了吗？这个表示运行时对应的GOMAXPROCS的值。

接着的`20000000`表示运行for循环的次数也就是调用被测试代码的次数

最后的`117 ns/op`表示每次需要花费117纳秒。(执行一次操作话费的时间)

以上是测试时间默认是1秒，也就是1秒的时间，调用两千万次，每次调用花费117纳秒。

如果想让测试运行的时间更长，可以通过-benchtime指定，比如3秒。

```
# go test -bench=. -benchtime=3s -run=none
// Benchmark 名字 - CPU     循环次数          平均每次执行时间 
BenchmarkSprintf-8      50000000               109 ns/op
PASS
//  哪个目录下执行go test         累计耗时
ok      flysnow.org/hello       5.628s
```
可以发现，我们加长了测试时间，测试的次数变多了，但是最终的性能结果：每次执行的时间，并没有太大变化。一般来说这个值最好不要超过3秒，意义不大。

### 结合 pprof
pprof 性能监控
```go
package bench
import "testing"
func Fib(n int) int {
    if n < 2 {
      return n
    }
    return Fib(n-1) + Fib(n-2)
}
func BenchmarkFib10(b *testing.B) {
    // run the Fib function b.N times
    for n := 0; n < b.N; n++ {
      Fib(10)
    }
}
```

```shell script
go test -bench=. -benchmem -cpuprofile profile.out
```
还可以同时看内存
```shell script
go test -bench=. -benchmem -memprofile memprofile.out -cpuprofile profile.out
```
然后就可以用输出的文件使用pprof
```shell script
go tool pprof profile.out
File: bench.test
Type: cpu
Time: Apr 5, 2018 at 4:27pm (EDT)
Duration: 2s, Total samples = 1.85s (92.40%)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) top
Showing nodes accounting for 1.85s, 100% of 1.85s total
      flat  flat%   sum%        cum   cum%
     1.85s   100%   100%      1.85s   100%  bench.Fib
         0     0%   100%      1.85s   100%  bench.BenchmarkFib10
         0     0%   100%      1.85s   100%  testing.(*B).launch
         0     0%   100%      1.85s   100%  testing.(*B).runN
```
这个是使用cpu 文件， 也可以使用内存文件

然后你也可以用list命令检查函数需要的时间

```
(pprof) list Fib
     1.84s      2.75s (flat, cum) 148.65% of Total
         .          .      1:package bench
         .          .      2:
         .          .      3:import "testing"
         .          .      4:
     530ms      530ms      5:func Fib(n int) int {
     260ms      260ms      6:   if n < 2 {
     130ms      130ms      7:           return n
         .          .      8:   }
     920ms      1.83s      9:   return Fib(n-1) + Fib(n-2)
         .          .     10:}
```









