#windows下设置GO111MODULE

```shell script
go env -w GOPROXY=https://goproxy.io,direct
go env -w GO111MODULE=on
```