[参考文章](https://blog.csdn.net/mojiewangday/article/details/104552668)
# 测试容器间通信
## 创建网络

```
docker network create --driver=bridge --subnet=172.25.0.0/16 my_nginx_net
```

修改nginx的docker-compose.yml，使用新创建的网络
```
version: '3'
services:
   proxy:
       image: nginx
       container_name: my_nginx
       volumes:
            - /data/nginx/config/nginx.conf:/etc/nginx/nginx.conf
            - /data/nginx/conf.d:/etc/nginx/conf.d
            - /data/nginx/log:/var/log/nginx
            - /data/nginx/html:/usr/share/nginx/html
       ports:
           - "7100:80"
           - "6088:6000"
           - "7000:4000"                                                                                                                                      
       networks:
          my_nginx_net:
                aliases:
                    - test1

networks:
    my_nginx_net:
        external: true
```
使用该网络创建blog容器

```
docker run -dit --net my_nginx_net --name hexo_blog --ip 172.25.0.13 \
    -v ~/.ssh:/root/.ssh \
    -v /root/docker/hexo/source:/blog/source \
    -v /root/docker/hexo/themes:/blog/themes \
    -v /root/docker/hexo/scaffolds:/blog/scaffolds \
    -v /root/docker/hexo/_config.yml:/blog/_config.yml \
qingcc/hexo_blog:latest
```
修改my_nginx容器配置文件

```
vim /data/nginx/conf.d/test.conf
```
键入

```
server {
    listen 4000;                #监听端口
    resolver 8.8.8.8;   #dns解析地址
    server_name blog;
    #charset koi8-r;
#        access_log  /var/log/nginx/test.access.log  main;
    location /test {
         proxy_pass http://172.25.0.12:7077/ping; #设定http代理服务器的协议和地址                                                                     
         proxy_set_header HOST $host;
         proxy_buffers 256 4k;
         proxy_max_temp_file_size 0k;
         proxy_connect_timeout 30;
         proxy_send_timeout 60;
         proxy_read_timeout 60;
         proxy_next_upstream error timeout invalid_header http_502;
        #root   html;
        #index  index.html index.htm;
    }

    location /blog {
         proxy_pass http://172.25.0.13:4000/;
         proxy_redirect  off;
         proxy_set_header  X-Real-IP $remote_addr;
         proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection "upgrade";
         proxy_read_timeout 1d;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
```
开启my_nginx容器

```
docker-compose up -d
```

本地访问

```
http://47.112.210.86:7000/blog //能正常访问
```

首先是请求47.112.210.86 服务器的7000端口，my_nginx容器有做端口映射，宿主机7000端口映射到my_nginx容器的4000端口，所以该请求实际上是请求my_nginx的4000端口。根据my_nginx的站点配置，请求路由带有`/blog`会把该请求分发到http://172.25.0.13:4000/， 而172.25.0.13对应的是hexo_blog的ip（创建容器时指定的ip，否则ip会随机分配；只有新建的网络使用`--subnet`参数设置子网，才能在创建容器时设置容器ip，否则会报错，创建容器失败）

在该例子中，hexo_blog没有设置端口映射，也可以被my_nginx访问到。

容器间相互通信主要有3种方式：
 1. 每个容器都设置端口映射。
 2. 使用--links参数（官方不推荐使用）
 3. 使用network通信（推荐）
 
docker network默认使用bridge，2个容器使用同一个网络可以相互通信，使用非同一个网络，不能直接通信

使用overlay网络（非本地网络bridge）可以实现多个处于不同服务器相互通信（待学习）


