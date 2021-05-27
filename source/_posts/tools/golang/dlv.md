
#安装dlv
```shell script
 go get github.com/go-delve/delve/cmd/dlv
```

dlv 调试最好还是在linux平台下。 先将代码编译成可执行文件

## gdb和dlv调试程序对比

### gdb调试程序
gdb调试程序
因为`gdb`对`Golang`的支持也是在不断完善中，为使用`gdb`调试`Golang`程序，建议将`gdb`升级到相对较新版本，目前，我使用的版本是`gdb7.10`。
大多数命令在使用`gdb`调试`C/C++`时都会用到，详细说明可参考：[Debugging Go Code with GDB](https://golang.org/doc/gdb)，具体操作如下：

1. 启动调试程序 ( `gdb` )
```shell script
 [lday@alex GoDbg]$ gdb ./GoDbg
```
 
2. 在main函数上设置断点 ( `b` )

3. 带参数启动程序 ( `r` )
(gdb) r arg1 arg2 

4. 在文件dbgTest.go上通过行号设置断点 ( `b` )
```shell script
 (gdb) b dbgTest.go:16 
 Breakpoint 3 at 0x457960: file /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/mylib/dbgTest.go, line 16.
```
 
5. 查看断点设置情况 ( `info b` )
```shell script
 (gdb) info b 
```
 
6. 禁用断点 ( `dis n` )
```shell script
 (gdb) dis 1    
 (gdb) info b 
```
 
 
7. 删除断点 ( `del n` )
```shell script
 (gdb) del 1 
 (gdb) info b 
```
 
8. 断点后继续执行 ( `c` )
```shell script
 (gdb) c  
```
 
9. 显示代码 ( `l` )
```shell script
 (gdb) l 11    
```
 
10. 单步执行 ( `n` )
```shell script
 (gdb) n
```
 
12. 打印变量信息 ( `print/p` )
在进入DBGTestRun的地方设置断点(b dbgTest.go:16)，进入该函数后，通过p命令显示对应变量：
```shell script
 (gdb) l 17 
 12        C map[int]string 
 13        D []string 
 14    } 
 15     
 16    func DBGTestRun(var1 int, var2 string, var3 []int, var4 MyStruct) { 
 17        fmt.Println("DBGTestRun Begin!\n") 
 18        waiter := &sync.WaitGroup{} 
 19     
 20        waiter.Add(1) 
 21        go RunFunc1(var1, waiter) (gdb) p var1  $3 = 1 (gdb) p var2 $4 = "golang dbg test" 
 (gdb) p var3 
 No symbol "var3" in current context.
 (gdb)
```
 从上面的输出我们可以看到一个很奇怪的事情，虽然`DBGTestRun`有4个参数传入，但是，似乎`var3`和`var4` `gdb`无法识别，在后续对`dlv`的实验操作中，我们发现，`dlv`能够识别`var3`， `var4`.
 
13. 查看调用栈 ( `bt` )，切换调用栈 ( `f n` )，显示当前栈变量信息
```shell script
 (gdb) bt 
 #0  GoWorks/GoDbg/mylib.DBGTestRun (var1=1, var2="golang dbg test")     at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/mylib/dbgTest.go:17 
 #1  0x00000000004018c2 in main.main () at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/main.go:27 
 (gdb) f 1 
 #1  0x00000000004018c2 in main.main () at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/main.go:27 27        mylib.DBGTestRun(var1, var2, var3, var4) 
 (gdb) l 
     22        var4.A = 1 
     23        var4.B = "golang dbg my struct field B" 
     24        var4.C = map[int]string{1: "value1", 2: "value2", 3: "value3"} 
     25        var4.D = []string{"D1", "D2", "D3"} 
     26     
     27        mylib.DBGTestRun(var1, var2, var3, var4) 
     28        fmt.Println("Golang dbg test over") 
     29    } 
 (gdb) print var1  
 $5 = 1 
 (gdb) print var2 
 $6 = "golang dbg test" 
 (gdb) print var3 
 $7 =  []int = {1, 2, 3}  
 (gdb) print var4 
 $8 = {A = 1, B = "golang dbg my struct field B", C = map[int]string = {[1] = "value1", [2] = "value2", [3] = "value3"},  D =  []string = {"D1", "D2", "D3"}}
```
 
14. 显示goroutine列表 ( `info goroutines` )
当程序执行到`dbgTest.go:23`时，程序通过go启动了第一个goroutine，并执行RunFunc1()，我们可以通过上述命令查看goroutine列表
```shell script
 (gdb) n 23        
waiter.Add(1) 
(gdb) info goroutines 
* 1 running  runtime.systemstack_switch   
  2 waiting  runtime.gopark   
  17 waiting  runtime.gopark   
  18 waiting  runtime.gopark   
  19 runnable GoWorks/GoDbg/mylib.RunFunc1
(gdb)
```
 
15. 查看goroutine的具体情况 ( `goroutine n cmd` )
```shell script
 (gdb) goroutine 19 bt 
 #0  GoWorks/GoDbg/mylib.RunFunc1 (variable=1, waiter=0xc8200721f0)     at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/mylib/dbgTest.go:36 
 #1  0x0000000000456df1 in runtime.goexit () at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:1998 
 #2  0x0000000000000001 in ?? () 
 #3  0x000000c8200721f0 in ?? () 
 #4  0x0000000000000000 in ?? ()
 (gdb)
```
 我们可以通过上述指令查看goroutine 9的调用栈，显然，该goroutine正在执行dbgTest.go:36行的函数：RunFunc1的goroutine。我们通过goroutine 19 info args等命令来查看该goroutine最顶层调用栈的变量信息，但是，如果我们需要查看的信息不再最顶层调用栈上，则很遗憾，gdb没法输出
 ```shell script
 (gdb) goroutine 19 
info args variable = 1 waiter = 0xc8200721f0 
(gdb) goroutine 19 p waiter  
$1 = (struct sync.WaitGroup *) 0xc8200721f0  
(gdb) goroutine 19 p *waiter  
$2 = {state1 = "\000\000\000\000\001\000\000\000\000\000\000", sema = 0}
```
 当我们执行到第26行，第2个goroutine被我们启动时，再次查看goroutine列表：
 ```shell script
 (gdb) n 26        
waiter.Add(1) 
(gdb) info goroutines 
* 1 running  runtime.systemstack_switch  
 2 waiting  runtime.gopark   
17 waiting  runtime.gopark   
18 waiting  runtime.gopark 
* 19 running  syscall.Syscall   
20 runnable GoWorks/GoDbg/mylib.RunFunc2
```
 此时我们再次查看goroutine 19的状态
 ```shell script
 (gdb) goroutine 19 bt 
#0  syscall.Syscall () at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/syscall/asm_linux_amd64.s:19 
#1  0x00000000004ab95f in syscall.write (fd=1, p= []uint8 = {...}, n=859530587568, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/syscall/zsyscall_linux_amd64.go:1064 #2  0x00000000004ab40d in syscall.Write (fd=5131648, p= []uint8, n=0, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/syscall/syscall_unix.go:180 
#3  0x000000000046c928 in os.(*File).write (f=0xc820084008, b= []uint8, n=4571929, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/os/file_unix.go:255 
#4  0x000000000046aa24 in os.(*File).Write (f=0xc82008a000, b= []uint8 = {...}, n=7, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/os/file.go:144 
#5  0x000000000045c707 in fmt.Fprintf (w=..., format="var1:%v\n", a= []interface {} = {...}, n=7, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:190 
#6  0x000000000045c7b4 in fmt.Printf (format="var1:%v\n", a= []interface {} = {...}, n=7, err=...)     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:197 
#7  0x00000000004583eb in GoWorks/GoDbg/mylib.RunFunc1 (variable=1, waiter=0xc8200721f0)     at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/mylib/dbgTest.go:37 
#8  0x0000000000456df1 in runtime.goexit () at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:1998 
#9  0x0000000000000001 in ?? () 
#10 0x000000c8200721f0 in ?? () 
#11 0x0000000000000000 in ?? ()
```
 从第7，8层调用栈我们可以看到，此时goroutine 19已经进入到RunFunc1的fmt.Printf函数中，当我们尝试在goroutine 19上切换栈时，gdb报错：
 ```shell script
 (gdb) goroutine 19 f 7 
#7  0x00000000004583eb in GoWorks/GoDbg/mylib.RunFunc1 (variable=1, waiter=0xc8200721f0)     at /home/lday/Works/Go_Works/GoLocalWorks/src/GoWorks/GoDbg/mylib/dbgTest.go:37 37        fmt.Printf("var1:%v\n", variable) Python Exception <class 'gdb.error'> Frame is invalid.:  Error occurred in Python command: Frame is invalid.
```
 似乎gdb不允许我们在goroutine上做调用栈的切换，因此我们没法在这种状态下查看某层调用栈的变量信息。缺少在goroutine上不同frame的变量查看，个人感觉gdb调试Golang程序功能大打折扣，在后面对dlv的实验操作中我们可以看到，dlv可以！


## dlv调试程序

操作说明：
1. 带参数启动程序 ( `dlv exec ./GoDbg -- arg1 arg2` )
```shell script
[lday@alex GoDbg]$ dlv exec ./GoDbg -- arg1 arg2  
Type 'help' for list of commands. 
(dlv) 
```
    
2.  在main函数上设置断点 ( `b` )
```shell script
(dlv) b main.main 
Breakpoint 1 set at 0x40101b for main.main() ./main.go:9
(dlv)
```

3.  启动调试，断点后继续执行 ( `c` )
```shell script
(dlv) c 
 > main.main() d:/gocode/tourmind.cn/temp_tools/test/godbg/main.go:10 (hits goroutine(1):1 total:1) (PC: 0xc4a68a)
      5:         "os"
      6: 
      7:         "tourmind.cn/temp_tools/test/GoDbg/mylib"
      8: )
      9: 
 =>  10: func main() {
     11:         fmt.Println("Golang dbg test...")
     12: 
     13:         var argc = len(os.Args)
     14:         var argv = append([]string{}, os.Args...)
     15: 
(dlv)
```

4. 在文件dbgTest.go上通过行号设置断点 ( `b` )
```shell script
(dlv) b dbgTest.go:17
 Breakpoint 2 set at 0x457f51 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:17 
(dlv) b dbgTest.go:23
 Breakpoint 3 set at 0x4580d0 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:23 
(dlv) b dbgTest.go:26 
Breakpoint 4 set at 0x458123 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:26 
(dlv) b dbgTest.go:29 
Breakpoint 5 set at 0x458166 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:29
(dlv) 
```

5. 显示所有断点列表 ( `bp` )
```shell script
(dlv) bp 
Breakpoint unrecovered-panic at 0x429690 for runtime.startpanic() /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/panic.go:524 (0) 
Breakpoint 1 at 0x40101b for main.main() ./main.go:9 (1) 
Breakpoint 2 at 0x457f51 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:17 (0) 
Breakpoint 3 at 0x4580d0 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:23 (0) 
Breakpoint 4 at 0x458123 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:26 (0) 
Breakpoint 5 at 0x458166 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:29 (0)
```
`dlv` 似乎没有提供类似 `gdbdis x`，禁止某个断点的功能，在文档中暂时没有查到。不过这个功能用处不大。

6. 删除某个断点 ( `clear x` )
 ```shell script
(dlv) clear 5 
Breakpoint 5 cleared at 0x458166 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:29 
(dlv) bp 
Breakpoint unrecovered-panic at 0x429690 for runtime.startpanic() /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/panic.go:524 (0) 
Breakpoint 1 at 0x40101b for main.main() ./main.go:9 (1) 
Breakpoint 2 at 0x457f51 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:17 (0) 
Breakpoint 3 at 0x4580d0 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:23 (0) 
Breakpoint 4 at 0x458123 for GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:26 (0)
(dlv)
```

7. 显示当前运行的代码位置 ( `ls` )
```shell script
(dlv) ls 
> GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:17 (hits goroutine(1):1 total:1) (PC: 0x457f51)     
    12:        C map[int]string     
    13:        D []string     
    14:    }     
    15:         
    16:    func DBGTestRun(var1 int, var2 string, var3 []int, var4 MyStruct) { 
=>  17:        fmt.Println("DBGTestRun Begin!\n")     
    18:        waiter := &sync.WaitGroup{}     
    19:         
    20:        waiter.Add(1)     
    21:        go RunFunc1(var1, waiter)     
    22:   
(dlv)
```

8.查看当前调用栈信息 ( `bt` )
```shell script
(dlv) bt 
0  0x0000000000457f51 in GoWorks/GoDbg/mylib.DBGTestRun    at ./mylib/dbgTest.go:17 
1  0x0000000000401818 in main.main    at ./main.go:27 
2  0x000000000042aefb in runtime.main    at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/proc.go:188 
3  0x0000000000456df0 in runtime.goexit    at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:1998
(dlv)
```

9. 输出变量信息（print/p）
```shell script
(dlv) print var1 
1 
(dlv) print var2 
"golang dbg test" 
(dlv) print var3 
[]int len: 3, cap: 3, [1,2,3] 
(dlv) print var4 
GoWorks/GoDbg/mylib.MyStruct {
        A: 1,
        B: "golang dbg my struct field B",
        C: map[int] string[1: "value1", 2: "value2", 3: "value3", ],
        D: [] string len: 3,cap: 3, ["D1", "D2", "D3"],}
(dlv)
```    
类比`gdb`调试，我们看到，之前我们使用`gdb`进行调试时，发现gdb在此时无法输出`var3`, `var4`的内容，而`dlv`可以

10. 在第n层调用栈上执行相应指令 ( `frame n cmd` )
```shell script
(dlv) frame 1 ls     
Goroutine 1 frame 1 at D:/gocode/tourmind.cn/temp_tools/test/GoDbg/main.go:28 (PC: 0xc4ae54)
    23:         var4.A = 1
    24:         var4.B = "golang dbg my struct field B"
    25:         var4.C = map[int]string{1: "value1", 2: "value2", 3: "value3"}
    26:         var4.D = []string{"D1", "D2", "D3"}
    27: 
=>  28:         mylib.DBGTestRun(var1, var2, var3, var4)
    29:         fmt.Println("Golang dbg test over")
    30: }
(dlv)
```
`frame 1 ls` 将显示程序在第1层调用栈上的具体实行位置

11.  查看goroutine的信息 ( `goroutines` )
当我们执行到 `dbgTest.go:26`时，我们已经启动了两个goroutine
```shell script
(dlv) ls
     > GoWorks/GoDbg/mylib.DBGTestRun() ./mylib/dbgTest.go:26 (hits goroutine(1):1 total:1) (PC: 0x458123)     
    21:        go RunFunc1(var1, waiter)     
    22:         
    23:        waiter.Add(1)     
    24:        go RunFunc2(var2, waiter)     
    25:     
=>  26:        waiter.Add(1)     
    27:        go RunFunc3(&var3, waiter)     
    28:         29:        waiter.Add(1)     
    30:        go RunFunc4(&var4, waiter)     
    31: 
(dlv)
```
此时我们来查看程序的goroutine状态信息
```shell script
(dlv) goroutines 
* Goroutine 1 - User: ./mylib/dbgTest.go:26 GoWorks/GoDbg/mylib.DBGTestRun (0x458123) (thread 9022)   
  Goroutine 2 - User: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/proc.go:263 runtime.gopark (0x42b2d3)   
  Goroutine 3 - User: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/proc.go:263 runtime.gopark (0x42b2d3)   
  Goroutine 4 - User: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/proc.go:263 runtime.gopark (0x42b2d3)   
  Goroutine 5 - User: ./mylib/dbgTest.go:39 GoWorks/GoDbg/mylib.RunFunc1 (0x4583eb) (thread 9035)   
  Goroutine 6 - User: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/format.go:130 fmt.(*fmt).padString (0x459545)
[6 goroutines]
(dlv)
```     
从输出的信息来看，先启动的 `goroutine 5`，执行`RunFunc1`，此时还没有执行`fmt.Printf`，而后启动的`goroutine 6`，执行`RunFunc2`，则已经进入到`fmt.Printf`的内部调用过程中了
     
12. 进一步查看goroutine信息 ( `goroutine x` )
接第11步的操作，此时我想查看`goroutine 6`的具体执行情况，则执行`goroutine 6`
```shell script
(dlv) goroutine 6 
Switched from 1 to 6 (thread 9022)
(dlv)
```
在此基础上，执行 `bt`，则可以看到当前`goroutine`的调用栈情况
```shell script
(dlv) bt  
0  0x0000000000454730 in runtime.systemstack_switch     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:245  
1  0x000000000040f700 in runtime.mallocgc     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/malloc.go:643  
2  0x000000000040fc43 in runtime.rawmem     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/malloc.go:809  
3  0x000000000043c2a5 in runtime.growslice     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/slice.go:95  
4  0x000000000043c015 in runtime.growslice_n     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/slice.go:44  
5  0x0000000000459545 in fmt.(*fmt).padString     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/format.go:130  
6  0x000000000045a13f in fmt.(*fmt).fmt_s     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/format.go:322  
7  0x000000000045e905 in fmt.(*pp).fmtString     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:518  
8  0x000000000046200f in fmt.(*pp).printArg     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:797  
9  0x0000000000468a8d in fmt.(*pp).doPrintf     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:1238 
10  0x000000000045c654 in fmt.Fprintf     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:188
(dlv)
```
此时输出了10层调用栈，但似乎最原始的我自身程序 `dbgTest.go` 的调用栈没有输出， 可以通过 `bt` 加`depth`参数，设定`bt`的输出深度，进而找到我们自己的调用栈，例如`bt 13`
```shell script
(dlv) bt 13 
... 
10  0x000000000045c654 in fmt.Fprintf     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:188 
11  0x000000000045c74b in fmt.Printf     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/print.go:197 
12  0x000000000045846f in GoWorks/GoDbg/mylib.RunFunc2     at ./mylib/dbgTest.go:50 
13  0x0000000000456df0 in runtime.goexit     at /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:1998
(dlv)
```
 我们看到，我们自己`dbgTest.go`的调用栈在第12层。当前`goroutine`已经不再我们自己的调用栈上，而是进入到系统函数的调用中，在这种情况下，使用`gdb`进行调试时，我们发现，
 此时我们没有很好的方法能够输出我们需要的调用栈变量信息。`dlv`可以!此时只需简单的通过`frame x cmd`就可以输出我们想要的调用栈信息了
 ```shell script
(dlv) frame 12 ls     
    45:        time.Sleep(10 * time.Second)     
    46:        waiter.Done()     
    47:    }     
    48:         
    49:    func RunFunc2(variable string, waiter *sync.WaitGroup) { 
=>  50:        fmt.Printf("var2:%v\n", variable)     
    51:        time.Sleep(10 * time.Second)     
    52:        waiter.Done()     
    53:    }     
    54:         
    55:    func RunFunc3(pVariable *[]int, waiter *sync.WaitGroup) { 
(dlv) frame 12 print variable  
"golang dbg test" 
(dlv) frame 12 print waiter 
*sync.WaitGroup {     state1: [12]uint8 [0,0,0,0,2,0,0,0,0,0,0,0],     sema: 0,}
(dlv)
```
多好的功能啊！

13. 查看当前是在哪个goroutine上（goroutine）
    当使用goroutine不带参数时，dlv就会显示当前goroutine信息，这可以帮助我们在调试时确认是否需要做goroutine切换
```shell script
(dlv) goroutine 
Thread 9022 at ./mylib/dbgTest.go:26 
Goroutine 6:     
        Runtime: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/runtime/asm_amd64.s:245 runtime.systemstack_switch (0x454730)     
        User: /home/lday/Tools/Dev_Tools/Go_Tools/go_1_6_2/src/fmt/format.go:130 fmt.(*fmt).padString (0x459545)     
        Go: ./mylib/dbgTest.go:26 GoWorks/GoDbg/mylib.DBGTestRun (0x458123)
(dlv)
```    
    

## 使用dlv调试golang程序
1. 编译选项
```shell script
go build -gcflags=all="-N -l"  ## 必须这样编译，才能用gdb打印出变量，第二个是小写的L，不是大写的i
```
需要加编译选项，类似gcc中的 -g选项，加入调试信息。

使用dlv调试
dlv的功能介绍
```shell script
Usage:
  dlv [command]

Available Commands:
  attach      Attach to running process and begin debugging.
  connect     Connect to a headless debug server.
  core        Examine a core dump.
  debug       Compile and begin debugging main package in current directory, or the package specified.
  exec        Execute a precompiled binary, and begin a debug session.
  help        Help about any command
  run         Deprecated command. Use 'debug' instead.
  test        Compile test binary and begin debugging program.
  trace       Compile and begin tracing program.
  version     Prints version.
```

由于dlv的功能比较多，我只介绍我常用的几个，包括 attach、debug、exec、core、test，这5个。

### dlv attach
这个相当于`gdb -p` 或者 `gdb attach` ，即**跟踪一个正在运行的程序**。这中用法也是很常见，对于一个后台程序，它已经运行很久了，此时你需要查看程序内部的一些状态，只能借助`attach`.
```shell script
dlv attach $PID  ## 后面的进程的ID
```

### dlv debug
```shell script
dlv debug main/hundredwar.go ## 先编译，后启动调试 
```
### dlv exec
```shell script
dlv exec ./HundredsServer  ## 直接启动调试

dlv exec ./HundredsServer -- -port 8888 -c /home/config.xml  ## 后面加参数启动调试
```

与`dlv debug`区别就是，`dlv debug` 编译一个临时可执行文件，然后启动调试，类似与`go run`。

### dlv core
用来调试`core`文件，但是想让`go`程序生成`core`文件，需要配置一个环境变量，默认`go`程序不会产生`core`文件。
```shell script
export GOTRACEBACK=crash
```
只有定义这个环境变量，`go`程序才会`coredump`。如果在协程入口定义`defer`函数，然后`recover`也不会产生`core`文件。
```shell script
go func() {
		defer func() {
			if r := recover(); r != nil {
                fmt.Printf("panic error\n") 
			}
		}()
		var p *int = nil
		fmt.Printf("p=%d\n", *p) // 访问nil指责
	}()  // 这个协程不会生产core文件
```
因为`recover`的作用就是捕获异常，然后进行错误处理，所以不会产生`coredump`，这个需要注意。这个也是`golang`的一大特色吧，捕获异常，避免程序`coredump`。

调试`coredump`文件
关于调试core文件，其实和C/C++差不多，最后都是找到发生的函数帧，定位到具体某一行代码。但是golang稍有不同，对于golang的core文件需要先定位到时哪一个goroutine发生了异常。
```shell script
dlv core ./Server core.26945  ## 启动
```

```shell script
Type 'help' for list of commands.
(dlv) goroutines   ## 查看所有goroutine
[12 goroutines]
  Goroutine 1 - User: /usr/local/go/src/runtime/time.go:102 time.Sleep (0x440d16)
  Goroutine 2 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
  Goroutine 3 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
  Goroutine 4 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
  Goroutine 5 - User: /usr/local/go/src/runtime/time.go:102 time.Sleep (0x440d16)
  Goroutine 6 - User: /usr/local/go/src/runtime/time.go:102 time.Sleep (0x440d16)
  Goroutine 7 - User: /usr/local/go/src/runtime/time.go:100 time.Sleep (0x440ccd)
  Goroutine 8 - User: ./time.go:114 main.main.func2 (0x4a33cb) (thread 21239)
  Goroutine 9 - User: /usr/local/go/src/runtime/lock_futex.go:227 runtime.notetsleepg (0x40ce42)
  Goroutine 17 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
  Goroutine 33 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
  Goroutine 49 - User: /usr/local/go/src/runtime/proc.go:292 runtime.gopark (0x42834a)
```
上面，可以看到所以的goroutine，需要找到自己的业务代码所在的goroutine，这里需要判断，不像C/C++的core文件，可以定义定位到所在的函数栈。这里的是 Goroutine 8 。

需要进入 8 号 goroutine。
```shell script
(dlv) goroutine 8  ## 切换到 8 号 goroutine
Switched from 0 to 8 (thread 21239)
```

```shell script
(dlv) bt    ## 查看栈帧
0  0x0000000000450774 in runtime.raise
   at /usr/local/go/src/runtime/sys_linux_amd64.s:159
1  0x000000000044cea0 in runtime.systemstack_switch
   at /usr/local/go/src/runtime/asm_amd64.s:363
2  0x00000000004265ba in runtime.dopanic
   at /usr/local/go/src/runtime/panic.go:597
3  0x00000000004261f1 in runtime.gopanic
   at /usr/local/go/src/runtime/panic.go:551
4  0x00000000004250ce in runtime.panicmem
   at /usr/local/go/src/runtime/panic.go:63
5  0x0000000000438baa in runtime.sigpanic
   at /usr/local/go/src/runtime/signal_unix.go:388
6  0x00000000004a33cb in main.main.func2
   at ./time.go:114  ## 显然6号栈是自己的业务代码
7  0x000000000044f6d1 in runtime.goexit
   at /usr/local/go/src/runtime/asm_amd64.s:2361
```

```shell script
(dlv) frame 6  ## 进入6号栈帧
> runtime.raise() /usr/local/go/src/runtime/sys_linux_amd64.s:159 (PC: 0x450774)
Warning: debugging optimized function
Frame 6: ./time.go:114 (PC: 4a33cb)
   109:			// 	if r := recover(); r != nil {
   110:	
   111:			// 	}
   112:			// }()
   113:			var p *int = nil
=> 114:			fmt.Printf("p=%d\n", *p)  ## 这里发生了异常
   115:		}()
   116:	
   117:		time.Sleep(10000000)
   118:	}
```

### dlv test
`dlv test` 也很有特色，是用来调试测试代码的。因为测试代码都是某一个包里面，是以包为单位的。
```shell script
dlv test $packname ## 包名
```

```shell script
[root@server]$ dlv test db ## 调试db包内部的测试用例
Type 'help' for list of commands.
(dlv) b TestMoneyDbGet ## 打断点，不用加包名了
Breakpoint 1 set at 0x73c15b for db.TestMoneyDbGet() ./db/moneydb_test.go:9
(dlv) c
> db.TestMoneyDbGet() ./db/moneydb_test.go:9 (hits goroutine(5):1 total:1) (PC: 0x73c15b)
     4:		"logger"
     5:		"testing"
     6:	)
     7:	
     8:	//日志不分离
=>   9:	func TestMoneyDbGet(t *testing.T) {
    10:		logger.Init("testlog", ".", 1000, 3, logger.DEBUG_LEVEL, false, logger.PUT_CONSOLE)
    11:		c := MoneydbConnect("192.168.202.92:12515")
    12:		if nil == c {
    13:			t.Error("Init() failed.")
    14:			return
(dlv) 
```

### dlv的不足之处
`dlv`和`gdb`相比，除了支持协程这一优势之外，其他的地方远不如`gdb`。比如

`dlv` 的`print` 不支持十六进制打印，`gdb`就可以，`p /x number`
`dlv`不支持变量、函数名的自动补全
`dlv`的`on` 功能与`gdb`的`commands`类似，可以的是`dlv`只支持`print`, `stack` and `goroutine`三个命令，竟然不支持`continue`
还有一个特殊情况，如果一个函数有定义，但是没在任何地方调用，**那么dlv打断点打不到**。

参考文章：

[Golang程序调试工具介绍(gdb vs dlv)](https://lday.me/2017/02/27/0005_gdb-vs-dlv/)  
[使用dlv调试golang程序](https://blog.csdn.net/KentZhang_/article/details/84925878)  
[手把手教你用dlv和gdb调试GoLang](https://blog.csdn.net/why444216978/article/details/110249558)  