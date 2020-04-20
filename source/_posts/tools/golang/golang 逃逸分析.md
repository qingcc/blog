[原文链接](https://gocn.vip/article/355)


# Golang逃逸分析

介绍逃逸分析的概念，go怎么开启逃逸分析的log。

以下资料来自互联网，有错误之处，请一定告之。

sheepbao 2017.06.10

## 什么是逃逸分析

wiki上的定义

> In compiler optimization, escape analysis is a method for determining the dynamic scope of pointers - where in the program a pointer can be accessed. It is related to pointer analysis and shape analysis.


```
// Example3:
package main

type S struct {
    M *int
}

func main() {
    var i int
    refStruct(i)
}

func refStruct(y int) (z S) {
    z.M = &y
    return z    
}

// Output:
// command-line-arguments
// escape_analysis/main.go:13: &y escapes to heap
// escape_analysis/main.go:12: moved to heap: y
```


> When a variable (or an object) is allocated in a subroutine, a pointer to the variable can escape to other threads of execution, or to calling subroutines. If an implementation uses tail call optimization (usually required for functional languages), objects may also be seen as escaping to called subroutines. If a language supports first-class continuations (as do Scheme and Standard ML of New Jersey), portions of the call stack may also escape.
> 
> If a subroutine allocates an object and returns a pointer to it, the object can be accessed from undetermined places in the program — the pointer has "escaped". Pointers can also escape if they are stored in global variables or other data structures that, in turn, escape the current procedure.
> 
> Escape analysis determines all the places where a pointer can be stored and whether the lifetime of the pointer can be proven to be restricted only to the current procedure and/or threa

大概的意思是在编译程序优化理论中，逃逸分析是一种确定指针动态范围的方法，可以分析在程序的哪些地方可以访问到指针。它涉及到指针分析和形状分析。 当一个变量(或对象)在子程序中被分配时，一个指向变量的指针可能逃逸到其它执行线程中，或者去调用子程序。如果使用尾递归优化（通常在函数编程语言中是需要的），对象也可能逃逸到被调用的子程序中。 如果一个子程序分配一个对象并返回一个该对象的指针，该对象可能在程序中的任何一个地方被访问到——这样指针就成功“逃逸”了。如果指针存储在全局变量或者其它数据结构中，它们也可能发生逃逸，这种情况是当前程序中的指针逃逸。 逃逸分析需要确定指针所有可以存储的地方，保证指针的生命周期只在当前进程或线程中。

## 逃逸分析的用处（为了性能）

- 最大的好处应该是减少gc的压力，不逃逸的对象分配在栈上，当函数返回时就回收了资源，不需要gc标记清除。

- 因为逃逸分析完后可以确定哪些变量可以分配在栈上，栈的分配比堆快，性能好

- 同步消除，如果你定义的对象的方法上有同步锁，但在运行时，却只有一个线程在访问，此时逃逸分析后的机器码，会去掉同步锁运行。

### go消除了堆和栈的区别

go在一定程度消除了堆和栈的区别，因为go在编译的时候进行逃逸分析，来决定一个对象放栈上还是放堆上，不逃逸的对象放栈上，可能逃逸的放堆上。

### 开启go编译时的逃逸分析日志

开启逃逸分析日志很简单，只要在编译的时候加上 `-gcflags '-m'`，但是我们为了不让编译时自动内连函数，一般会加 `-l` 参数，最终为 `-gcflags '-m -l'`


```
// Example:
package main

import (
    "fmt"
)

func main() {
    s := "hello"
    fmt.Println(s)
}
// go run -gcflags '-m -l' escape.go
// Output:
// command-line-arguments
// escape_analysis/main.go:9: s escapes to heap
// escape_analysis/main.go:9: main ... argument does not escape
// hello
```

### 什么时候逃逸，什么时候不逃逸


```
// Example1:
package main

type S struct{}

func main() {
    var x S
    y := &x
    _ = *identity(y)
}

func identity(z *S) *S {
    return z
}
//Output:
// command-line-arguments
// escape_analysis/main.go:11: leaking param: z to result ~r1 level=0
// escape_analysis/main.go:7: main &x does not escape
```

这里的第一行表示z变量是“流式”，因为identity这个函数仅仅输入一个变量，又将这个变量作为返回输出，但identity并没有引用z，所以这个变量没有逃逸，而x没有被引用，且生命周期也在mian里，x没有逃逸，分配在栈上。


```
// Example2:
package main

type S struct{}

func main() {
    var x S
    _ = *ref(x)
}

func ref(z S) *S {
    return &z
}
// Output:
// command-line-arguments
// escape_analysis/main.go:11: &z escapes to heap
// escape_analysis/main.go:10: moved to heap: z
```


这里的z是逃逸了，原因很简单，go都是值传递，ref函数copy了x的值，传给z，返回z的指针，然后在函数外被引用，说明z这个变量在函数內声明，可能会被函数外的其他程序访问。所以z逃逸了，分配在堆上

对象里的变量会怎么样呢？看下面

看日志的输出，这里的y是逃逸了，看来在struct里好像并没有区别，有可能被函数外的程序访问就会逃逸


```
// Example4:
package main

type S struct { 
    M *int
}

func main() { 
    var i int 
    refStruct(&i)
}

func refStruct(y *int) (z S) {
    z.M = y
    return z 
}
// Output:
// command-line-arguments
// escape_analysis/main.go:12: leaking param: y to result z level=0
// escape_analysis/main.go:9: main &i does not escape
```

这里的y没有逃逸，分配在栈上，原因和Example1是一样的。


```
// Example5:
package main

type S struct { 
    M *int
}

func main() { 
    var x S
    var i int
    ref(&i, &x) 
}

func ref(y *int, z *S) { 
    z.M = y
}
// Output:
// command-line-arguments
// escape_analysis/main.go:13: leaking param: y
// escape_analysis/main.go:13: ref z does not escape
// escape_analysis/main.go:10: &i escapes to heap
// escape_analysis/main.go:9: moved to heap: i
// escape_analysis/main.go:10: main &x does not escape
```

这里的z没有逃逸，而i却逃逸了，这是因为go的逃逸分析不知道z和i的关系，逃逸分析不知道参数y是z的一个成员，所以只能把它分配给堆。

### 参考

[Go Escape Analysis Flaws](https://docs.google.com/document/d/1CxgUBPlx9iJzkz9JWkb6tIpTe5q32QDmz8l0BouG0Cw/preview#)

[go-escape-analysis](http://www.agardner.me/golang/garbage/collection/gc/escape/analysis/2015/10/18/go-escape-analysis.html)