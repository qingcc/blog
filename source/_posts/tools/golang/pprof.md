[link](https://juejin.im/post/5d27400151882530af139a85)

[TOC]

main方法中添加如下代码
```
_ "net/http/pprof"
...
go func() {
	log.Println(http.ListenAndServe(":6060", nil))
	}()
```

访问 `http://localhost:6060/debug/pprof/` 即可查看到操作面板，点击 `goroutine` 即可查看 `goroutine` 使用情况 `debug=1`, `goroutine` 
总体使用情况，`debug=2`,每个 `goroutine` 的信息。 点击 `trace` 下载 `trace` 文件, 使用命令 `go tool trace trace_filename` 
即可查看对应的trace信息。也可在服务器上运行命令 `curl http://127.0.0.1:6060/debug/pprof/trace?seconds=20 > trace.out` 来生成trace文件。

**注意**：要设置为 `:6060` 而不能是 `localhost:6060`,否则会出现本地访问不了的问题（部署在服务器上，只能在服务器上通过命令行来查看，本地访问不了）

## 使用pprof工具生成svg图片
部分非http server程序如果需要连接数据库（指定ip才能连接），生成.svg图片，并只下载该图片会更方便(可执行文件一般比较大)
```shell script
root@hostname:~/path# go tool pprof main cpu.pprof 
File: main
Type: cpu
Time: Mar 22, 2021 at 10:24am (CST)
Duration: 5.48s, Total samples = 3.12s (56.98%)
Entering interactive mode (type "help" for commands, "o" for options)
(pprof) web
Couldn't find a suitable web browser!
Set the BROWSER environment variable to your desired browser.
(pprof) svg
Generating report in profile001.svg
(pprof) 
```
通过命令 `go tool pprof binaryFile cpu.pprof`和`svg`，即可生成对应的svg图