## dlv test
使用 `dlv` 来调试test方法
```shell script
> # dlv test -test.run example.go                                                                                                     [±master ●]
Type 'help' for list of commands.
(dlv) break tourmind.cn/hotlogs/service/chl/example.(*ExampleService).GetChannelRateLogs
Breakpoint 1 set at 0xdbd2bb for tourmind.cn/hotlogs/service/chl/example.(*ExampleService).GetChannelRateLogs() ./example.go:339
(dlv) c
> tourmind.cn/hotlogs/service/chl/example.(*ExampleService).GetChannelRateLogs() ./example.go:339 (hits goroutine(23):1 total:1) (PC: 0xdbd2bb)
   334:                 result.Success = false
   335:         }
   336:         return
   337: }
   338:
=> 339: func (s *ExampleService) GetChannelRateLogs(ctx context.Context, request *chlreqlog_model.RateLogSearchRequest,
   340:         result *chlreqlog_model.RateLogSearchResult) (err error) {
   341:
(dlv) b 345
Breakpoint 2 set at 0xdbd385 for tourmind.cn/hotlogs/service/chl/example.(*ExampleService).GetChannelRateLogs() ./example.go:345
(dlv) 
```