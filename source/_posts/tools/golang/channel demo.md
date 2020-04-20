
一个有趣的例子。 （channel只读，只写，可读可写）
```
func test() {
   inch := make(chan int)  // 无缓存, 可读写
   outch := make(chan int) // 无缓存, 可读写
   go func() {
      //将inch的地址赋给in, 此时, 向inch中写入数据时, 由于地址相同, in内也会有数据,此时in准备好读出
      var in <-chan int = inch //in  只读(接收) int 类型数据, 不能写入, 无缓存
      var out chan<- int       //out 只写(发送) int 类型数据, 不能读出, 无缓存
      var val int
      fmt.Println("in:", in, "out:", out)
      fmt.Println("inch:", inch, "outch:", outch)
      for {
         select {
         case out <- val:
            fmt.Println("case1", val)
            time.Sleep(time.Second * 3) //沉睡 3 秒, 会先打印, outch 读出的数据, 再打印 该case 之后需要打印的数据
            out = nil                   //out = nil != outch, 即out 只能写入, 没有读出, 即 写入阻塞
            in = inch                   // in = inch, 可以通过 向 inch 写入 实现 向 in 写入(in & inch 同地址), 即 可写入, 读出 不阻塞, 进入下面的case
            fmt.Println("in case1")
         case val = <-in:
            fmt.Println("case2", val)
            out = outch //将可写可读的outch的地址赋给 out, 在另一个协程中, outch 准备好读数据 故 out 可以写入, out 写入 不阻塞, 进入上面的case
            in = nil    //将in 指向 nil, 即 in 只能读出, 没有写入, 读出阻塞
            fmt.Println("in case2", "out:", out, "outch:", outch)
         }
      }
   }()
   go func() {
      for r := range outch {
         fmt.Println("result:", r)
      }
   }()
   time.Sleep(0)
   fmt.Println("inch read")
   inch <- 1
   inch <- 2//无缓存, 只有当写入的 1 被取出, 且, inch 准备好读出时, 才会从阻塞 状态 进入正常状态, 写入 数据 2
   time.Sleep(3 * time.Second)
}
```
