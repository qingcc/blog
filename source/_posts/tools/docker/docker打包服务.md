# docker打包服务
结构：
```
-servicea
--Dockerfile //生成镜像文件
--servicea.go //服务a的入口文件
--build.sh //启动文件
```

Dockerfile
```dockerfile
FROM alpine

WORKDIR /app

EXPOSE 10011

ADD servicea /app/

CMD ["/app/servicea"]
```

build.sh
```shell
#!/bin/sh
source_path=servicea.go
image_name=servicea

echo "===> building container image"

build_result="$(go build -o $image_name $source_path)"

if [[ $build_result =~ ":" ]] ; then
    echo "**** encounter building error, exit"
    echo "$build_result"
    exit
fi

docker rmi -f $image_name
docker build -t $image_name  .

echo '-> ** tagging '$image_name
docker tag $image_name $image_name
rm $image_name
```
给build.sh加可执行权限，执行
```shell
chmod +x build.sh
./build.sh
# or
bash build.sh
```

之后会通过Dockerfile生成镜像

将镜像推送
```shell
docker push $image_name
```