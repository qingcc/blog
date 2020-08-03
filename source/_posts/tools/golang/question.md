
1. 关于从channel中正确的取出slice数据
```
ch := make(chan []int)
go func() {
    for i:=0; i<5; i++ {
        ch<-[]int{i, i*i, i*i*i}
    }
    close(ch)
}
for _, v := range <-ch {
    log.Println("v:", v)
}
```
对于普通的channel，for-range会不断的将ch中的值读取出来，直到ch被关闭。
当channel管道存储的是slice类型的值时，for-range遍历的是从ch读取出来的第一个slice，
该代码不会等到ch管道关闭，for-range遍历就会结束。（容易造成goroutine泄露）。

正确的从slice类型的channel中读取数据姿势：
```
for {
    if v, ok := <-ch; ok {
        for _, vv := v {
            //todo something
        }
    } else {
        break
    }
}
```
从channel ch中读取出来数据v，并判断ch是否被close了，若已close，则ok=false，break跳出循环；
若ch还未close，则继续遍历slice v。此时能一直读取存储slice 的 channel ch直到close(ch)。
但如果明确直到ch存储的不是slice，直接使用for-range更便捷。

2. 接口对接时，http解析请求数据和返回响应数据

一般对接接口时，会采用加密方法来保证数据的安全性。go默认是用UTF-8编码格式. 在正常的情况下,一般接口都会指定UTF-8的编码格式.
Ajax请求也默认为UTF-8. 所以正常情况下,go对接不需要考虑转码问题.golang在加密数据时，可能会对已经编码过的字符串再次编码加密，
会导致加密后的密文和对方的密文对应不上（对方要求的密文为 对元数据做utf-8编码后md5加密，而对接时，可能会出现对元数据编码2次在加密）

go utf-8编码&反编码： 

```
url.QueryEscape()   //编码
url.QueryUnescape() //反编码
```
在对接接口时需注意。(接收的请求数据可能是未编码的，也可能是已编码的，需要注意，不要出现连续编码)

响应数据：

在接口响应数据时，对一些非必填字段，大多时候采用的是不填充。go默认返回对应数据类型的`零值` 比如string类型的返回空字符串。
但是请求方可能会出现 对一些非必填字段 可以不响应该字段，但是不能返回空字符串（string类型，实际遇到过）。所以对于这种情况需要
定义好响应字段（非必填可以不定义）

3. 向空map写入数据 (assignment to entry in nil map)

```
    newRTs := make(map[int]map[string]interface, 0) //map[supplier_id]map[room_type_code]domain.RoomType
    rtMap := newRTs[rt.id]  //newRTs[rt.SupplierId]可能为nil，此时向rtMap写入数据就会报错
	rtMap[rt.str] = rt     //error:  assignment to entry in nil map
	newRTs[rt.id] = rtMap
```
正确的处理方法是在赋值之前先判断是不是nil，如果是，则先分配好空间
```
    if newRTs[rt.id] == nil { //不确定newRts[id]是否是nil，之后需要向该map赋值，故需要先判断
        newRTs[rt.id] = make(map[string]interface)
    }
```