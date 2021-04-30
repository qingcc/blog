
# 获取环境变量`name`的值
```
if strings.TrimSpace(os.Getenv("name")) == "" {
    //todo something
}
```

# 逃逸分析

```shell script
go build -gcflags "-N -l -m" closure
```