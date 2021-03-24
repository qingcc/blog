
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


