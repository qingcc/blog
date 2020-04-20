运行portainer生成容器
```
docker run -d \
-p 9000:9000 \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
portainer/portainer
```

一键安装ssr(翻墙服务端，需要未被墙的境外服务器），按照提示一步步设置即可完成
```
wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
```

安装Shadowsocks 客户端（翻墙）
```
#安装
pip install --upgrade pip
pip install shadowsocks

#配置
vi /etc/shadowsocks.json

{
  "server":"x.x.x.x",             #你的 ss 服务器 ip
  "server_port":0,                #你的 ss 服务器端口
  "local_address": "127.0.0.1",   #本地ip
  "local_port":1080,                 #本地端口
  "password":"password",          #连接 ss 密码
  "timeout":300,                  #等待超时
  "method":"aes-256-cfb",         #加密方式
  "workers": 1                    #工作线程数
}

#运行
nohup sslocal -c /etc/shadowsocks.json  &
```
浏览器翻墙还需要下载SwitchyOmega,简单配置即可翻墙，终端需要翻墙还需要安装privoxy

安装privoxy
```
#安装依赖
yum  -y install  make  gcc  
yum  -y install autoconf 
yum -y install zlib  zlib-devel 

#下载源码
wget https://nchc.dl.sourceforge.net/project/ijbswa/Sources/3.0.28%20%28stable%29/privoxy-3.0.28-stable-src.tar.gz

#建立账户（Privoxy 强烈不建议使用 root 用户运行，所以我们使用 useradd privoxy 新建一个用户.）
sudo useradd privoxy -r -s /usr/sbin/nologin

#编译
tar xzvf privoxy-3.0.23-stable-src.tar.gz
cd privoxy-3.0.23-stable
autoheader && autoconf
./configure
make && make install

#配置
vi /usr/local/etc/privoxy/config
#找到以下两句，确保没有注释掉
listen-address 127.0.0.1:8118   # 8118 是默认端口，不用改，下面会用到
forward-socks5t / 127.0.0.1:1080 . # 这里的端口写 shadowsocks 的本地端口（注意最后那个 . 不要漏了）

#启动
privoxy --user privoxy /usr/local/etc/privoxy/config

#配置 /etc/profile
vi /etc/profile
#添加
export http_proxy=http://127.0.0.1:8118       #这里的端口和上面 privoxy 中的保持一致
export https_proxy=http://127.0.0.1:8118
#更新配置
source /etc/profile
#测试
curl www.google.com
```