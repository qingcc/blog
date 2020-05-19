
1. 运行shell脚本时报错`[[ : not found`

在运行shell脚本时报错，命令为：

```
./test.sh #等价于 sh test.sh
```

解决办法：bash与sh是有区别的，两者是不同的命令，且bash是sh的增强版，而`[[]]`是bash脚本中的命令，因此在执行时，使用sh命令会报错，将sh替换为bash命令即可：

```
bash test.sh
```