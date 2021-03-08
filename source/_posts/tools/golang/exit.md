# 优雅的退出程序

通过读取中断信号，判断是否退出。退出前，延迟5s结束，部分协程等完成job
```go
func main() {
    // todo something

    // Wait for interrupt signal to gracefully shutdown the server with
	// a timeout of 5 seconds.
     quit := make(chan os.Signal)
     signal.Notify(quit, os.Interrupt) // 如果接收到中断信号，则写入quit管道
     <-quit
     log.Println("Shutdown Server ...")
   
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
    	log.Fatal("Server Shutdown:", err)
    }
    log.Println("Server exiting")
}
```