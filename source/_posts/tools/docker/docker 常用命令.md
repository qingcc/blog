## 常用命令
删除本地无用的镜像

```
docker  images|grep  none|awk  '{print  $3  }'|xargs  docker  rmi
```
