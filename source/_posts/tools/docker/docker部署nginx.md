## 新建宿主服务器挂载文件夹

```
mkdir -p /data/nginx/{conf.d, conf, html, log}
```
新建配置文件

```
vim /data/nginx/conf/nginx.conf
```
键入
```
  user  root;                                                                                                                                       
  worker_processes  1;
  
  error_log  /var/log/nginx/error.log warn;
  pid        /var/run/nginx.pid;
  
  events {
      worker_connections  1024;
  }
  
  
  http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
  
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
  
      access_log  /var/log/nginx/access.log  main;
  
      sendfile        on;
      #tcp_nopush     on;
  
      keepalive_timeout  65;
    #gzip  on;
  
      include /etc/nginx/conf.d/*.conf;
  }
```
```
vim /data/nginx/conf.d/default.conf
```
键入
```
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html; #项目入口文件
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
```

```
vim /data/nginx/html/index.html
```
键入

```
<h1>nginx done!</h1>
```

### 新建docker-compose.yml文件

```
mdkir -p ~/docker/nginx
cd ~/docker/nginx
vim docker-compose.yml
```
键入

```
version: '3'
services:
   proxy:
       image: nginx
       container_name: my_nginx
       volumes:
            - /data/nginx/conf/nginx.conf:/etc/nginx/nginx.conf
            - /data/nginx/conf.d:/etc/nginx/conf.d  
            - /data/nginx/log:/var/log/nginx 
            - /data/nginx/html:/usr/share/nginx/html
       ports:
           - "7100:80" #默认端口，可以访问检测nginx是否可以正常访问
           - "6088:6088" #可以根据需要映射多个端口
```

开启nginx服务

```
docker-compose up -d
```
访问ip:7100,如果打印`nginx done!`则部署成功。
可能遇到的问题：
- 403 forbidden， `/data/nginx/conf/nginx.conf`配置文件中的用户`user root`是否和项目入口文件的所属人相同`/data/nginx/html/index.html`
- 无法访问， 查看端口是否被占用，端口是否开放（如果是阿里云需要添加安全组规则）

可以根据需要在`/data/nginx/conf.d/`目录下添加新的配置文件，并修改docker-compose中的端口映射

