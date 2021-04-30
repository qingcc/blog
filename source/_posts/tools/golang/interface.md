
## interface 底层结构
根据 interface 是否包含有 method，底层实现上用两种 struct 来表示：iface 和 eface。
eface表示不含 method 的 interface 结构，或者叫 empty interface。
对于 Golang 中的大部分数据类型都可以抽象出来 _type 结构，同时针对不同的类型还会有一些其他信息。

```go
// runtime/runtime2.go
type eface struct {
    _type *_type
    data  unsafe.Pointer
}

type _type struct {
    size       uintptr // type size
    ptrdata    uintptr // size of memory prefix holding all pointers
    hash       uint32  // hash of type; avoids computation in hash tables
    tflag      tflag   // extra type information flags
    align      uint8   // alignment of variable with this type
    fieldalign uint8   // alignment of struct field with this type
    kind       uint8   // enumeration for C
    alg        *typeAlg  // algorithm table
    gcdata    *byte    // garbage collection data
    str       nameOff  // string form
    ptrToThis typeOff  // type for pointer to this type, may be zero
}
```

iface 表示 non-empty interface 的底层实现。相比于 empty interface，non-empty 要包含一些 method。
method 的具体实现存放在 itab.fun 变量里。如果 interface 包含多个 method，
这里只有一个 fun 变量怎么存呢？这个下面再细说。
```go
// runtime/runtime2.go
type iface struct {
	tab  *itab
	data unsafe.Pointer
}

// layout of Itab known to compilers
// allocated in non-garbage-collected memory
// Needs to be in sync with
// ../cmd/compile/internal/gc/reflect.go:/^func.dumptabs.
type itab struct {
	inter *interfacetype
	_type *_type
	hash  uint32 // copy of _type.hash. Used for type switches.
	_     [4]byte
	fun   [1]uintptr // variable sized. fun[0]==0 means _type does not implement inter.
}

```
我们使用实际程序来看一下。
```go
package main

import (
    "fmt"
)

type MyInterface interface {
    Print()
}

type MyStruct struct{}
func (ms MyStruct) Print() {}

func main() {
    x := 1
    var y interface{} = x
    var s MyStruct
    var t MyInterface = s
    fmt.Println(y, t)
}
```

## itab

iface 结构中最重要的是 itab 结构。itab 可以理解为 pair<interface type, concrete type> 。当然 itab 里面还包含一些其他信息，
比如 interface 里面包含的 method 的具体实现。下面细说。itab 的结构如下。

```
type itab struct {
    inter  *interfacetype
    _type  *_type
    link   *itab
    bad    int32
    inhash int32      // has this itab been added to hash?
    fun    [1]uintptr // variable sized
}
```
其中 interfacetype 包含了一些关于 interface 本身的信息，比如 package path，包含的 method。
上面提到的 iface 和 eface 是数据类型（built-in 和 type-define）转换成 interface 之后的实体的 struct 结构，
而这里的 interfacetype 是我们定义 interface 时候的一种抽象表示。

```
type interfacetype struct {
    typ     _type
    pkgpath name
    mhdr    []imethod
}

type imethod struct {   //这里的 method 只是一种函数声明的抽象，比如  func Print() error
    name nameOff
    ityp typeOff
}
```

_type 表示 concrete type。fun 表示的 interface 里面的 method 的具体实现。比如 interface type 包含了 method A, B，
则通过 fun 就可以找到这两个 method 的具体实现。这里有个问题 fun 是长度为 1 的 uintptr 数组，那么怎么表示多个 method 呢？看一下测试程序。



**这里就看不懂了，先记录到这**

















