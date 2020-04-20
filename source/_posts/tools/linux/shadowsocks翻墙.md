# 通过shadowsocks实现翻墙
[TOC]
### 安装shadowwsocks
```
sudo apt install shadowsocks 
vim gui-config.json
```
### 然后配置这个json文件
```
du@du:~/Demo/ss$ cat gui-config.json
{
    "method": "aes-256-cfb",
    "password": "",#服务器密码
    "remarks": "",
    "server": "ip", #服务器IP
    "server_port": 443,#服务器端口
    "local_address":"127.0.0.1",
    "localPort": 1080,
    "shareOverLan": true
}
sslocal -c ~/gui-config.json
```
### 验证Shadowsocks客户端服务是否正常运行
```
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip
output：
{  "origin": "x.x.x.x"       #你的Shadowsock服务器IP
}
```
### 安装配置priv
```
yum install privoxy -y
```
### 配置privoxy
修改配置文件/etc/privoxy/config
```
listen-address 127.0.0.1:8118 # 8118 是默认端口，不用改
forward-socks5t / 127.0.0.1:1080 . #转发到本地端口，注意最后有个点
```

设置http、https代理
```
vi /etc/profile 
# 在最后添加如下信息
PROXY_HOST=127.0.0.1
export no_proxy=localhost,172.16.0.0/16,192.168.0.0/16.,127.0.0.1,10.10.0.0/16
# 重载环境变量
source /etc/profile
```
### 启动
```
privoxy --user privoxy /etc/privoxy/config
```
### 测试代理
```
curl -I www.google.com HTTP/1.1 200 OK
```
同时需要在chrome浏览器添加代理插件SwitchyOmega（并配置）才能在浏览器上访问外网
制作成开机自启脚本
```
sudo vim ss.sh

# nohup  command & 后台执行，即使关闭该终端，程序仍会在后台执行
nohup sslocal -c /home/yi/software/gui-config.json  &

# 加可执行权限
sudo chmod +x ss.sh
sudo mv ss.sh /etc/init.d
# 添加到开机自启
sudo update-rc.d ss.sh defaults 95
```