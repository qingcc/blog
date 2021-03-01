# test

## 使用Go Test测试单个文件和单个方法
前置条件：  
1. 文件名须以"_test.go"结尾
2. 方法名须以"Test"打头，并且形参为 (t *testing.T)

测试整个文件：
```shell script
 go test -v hello_test.go
```
测试单个函数：
```shell script
go test -v hello_test.go -test.run TestHello
```
