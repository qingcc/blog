[linux安装protobuf步骤](https://www.twblogs.net/a/5c9bf5e2bd9eee73ef4b1238/zh-cn)

按步骤执行
安装需要的依赖包：
```
yum -y install autoconf automake libtool curl make g++ unzip
```
下载protobuf源码, 解压进入
```
git clone https://github.com/google/protobuf.git
cd protobuf
```
生成configure文件的脚本文件，如果不执行这步，以下操作将通不过
```
./autogen.sh 
./configure    //可以修改安装目录通过 ./configure --prefix=命令,统一安装在/usr/local/protobuf下
```

备注：此处操作最后有一个警告，configure: WARNING: no configuration information is in third_party/googletest，需要解决，不然会影响之后的操作。参考博客：https://blog.csdn.net/yzhang6_10/article/details/81482852?utm_source=blogxgwz3

这里需要下载googletest，下载地址：https://github.com/google/googletest/releases ，解压后放在protobuf-3.6.1/third_party文件夹下，并命名为googletest，然后重新从第四步./autogen.sh开始执行。(此处解压会有多个 嵌套的 googletest文件夹, 最终成功的是有2个)

重新执行以下命令, 不会报错
```
./autogen.sh 
./configure    //可以修改安装目录通过 ./configure --prefix=命令,统一安装在/usr/local/protobuf下
```

```
make //成功
make check //会报错
make install //安装

$protoc --version //打印版本
```

此处报错：protoc: error while loading shared libraries: libprotoc.so.18: cannot open shared object file:No such file or directory

解决办法:

A.创建文件，在/etc/ld.so.conf.d目录下，使用sudo touch libprotobuf.conf命令创建libprotobuf.conf文件
$sudo touch libprotobuf.conf

B.使用Vim编辑libprotobuf.conf，插入内容：
/usr/local/lib

C.编辑完成后，输入命令sudo ldconfig
$sudo ldconfig

D.再次输入命令protoc --version，查看版本，可以看到输出版本号，说明protc安装完成。

此时, 可以安装go版本的protoc
```
go get github.com/golang/protobuf
go install github.com/golang/protobuf/protoc-gen-go/
```
之后, 可以正常使用
```
$ protoc --go_out=. hello.proto //生成go文件了
```

安装`protobuf` `go`版本脚本 `protobufInstall.sh`
```
#!/bin/bash
yum -y install autoconf automake libtool curl make g++ unzip
homePath=`echo ~`
if [ ! -d "${homePath}/download/" ]; then
    mkdir ~/download
fi
cd "${homePath}/download/"
if [ ! -d "${homePath}/download/protof/" ]; then
  git clone https://github.com/google/protobuf.git
fi
cd ./protobuf
./autogen.sh
./configure
make && make install
hasError=`protoc --version| grep "error"`
if [ "${hasError}" != "" ]; then
  cat > /etc/ld.so.conf.d/libprotobuf.conf << EOF
/usr/local/lib
EOF
sudo ldconfig
fi
hasError=`protoc --version| grep "error"`
if [ "${hasError}" == "" ]; then
  go get github.com/golang/protobuf
  go install github.com/golang/protobuf/protoc-gen-go/
  cp "${GOPATH}/bin/protoc-gen-go" /usr/bin/
  protoc --go_out=. hello.proto
else
  echo "has wrong"
fi
```

等待执行（需要一定的时间）  
最后打印如下，没有找到`hello.proto`文件.

```
Could not make proto path relative: hello.proto: No such file or directory
```
