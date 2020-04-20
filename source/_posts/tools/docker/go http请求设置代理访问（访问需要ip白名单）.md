## 问题描述
对接接口时经常需要面对，请求方需要ip白名单，而自己使用的是公司内网（没有固定的公网ip）。在测试接口时，需要先将代码上传到服务器，再在服务器上运行代码（比较麻烦）。

## 使用代理
使用代理可以解决该问题。
### 使用nginx做代理
安装参照 docker部署nginx

添加代理站点

```
vim /data/nginx/conf.d/proxy.conf
```
键入
```
server {
        listen 6088;                #监听端口
        resolver 8.8.8.8;   #dns解析地址
        server_name  proxy;
        #charset koi8-r;
        #access_log  logs/host.access.log  main;
        location / {
             proxy_pass https://$host$request_uri;     #设定http代理服务器的协议和地址
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
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
 
    }
```
重启my_nginx容器

```
docker restart my_nginx
```

此时已配置好代理

### go http请求使用该代理

正常http代码
```
if req, newReqErr := http.NewRequest(method, context.Endpoint, bytes.NewReader(context.ReqBody)); newReqErr != nil {
    ...
}else {
    if resp, e := client.Do(req); e == nil { //发起请求
        ...
    }
}
```
使用代理

```
if req, newReqErr := http.NewRequest(method, context.Endpoint, bytes.NewReader(context.ReqBody)); newReqErr != nil {
    ...
}else {
    //设置代理, 47.112.210.86:6088即为代理所在的服务器及代理端口
    proxy := func(_ *http.Request) (*url.URL, error) {
		return url.Parse("http://47.112.210.86:6088") //根据定义Proxy func(*Request) (*url.URL, error)这里要返回url.URL
	}
	transport := &http.Transport{Proxy: proxy}
	client := &http.Client{Transport: transport}
	if resp, e := client.Do(req); e == nil { //发起请求
	    ...
	}
}
```
此时运行该go代码，会使用该代理来访问。（将47.112.210.86 ip添加到对方的ip白名单即可在本地测试访问）



