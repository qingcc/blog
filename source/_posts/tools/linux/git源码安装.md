# git源码安装
删除已有的git
```
git yum remove git 
```
安装编译git时需要的包
```
yum install -y curl-devel expat-devel gettext-devel openssl-devel zlib-devel
yum install -y gcc perl-ExtUtils-MakeMaker 
```
<!-- more -->
yum时，可能会报下载包错误（需要换源）
```
#备份
cd /etc/yum.repos.d
mv CentOS-Base.repo CentOS-Base.repo.old
#换源
wget http://mirrors.aliyun.com/repo/Centos-7.repo
mv Centos-7.repo CentOS-Base.repo
#更新
yum update
    
#下载最新的包
wget https://github.com/git/git/archive/v2.24.0.zip
mkdir /usr/local/git
mv v2.24.1.tar.gz /usr/local/git
cd /usr/local/git 
tar -zxvf v2.24.1.tar.gz 
rm -f v2.24.1.tar.gz     

#编译安装
make prefix=/usr/local/git all 
make prefix=/usr/local/git install

#配置环境变量，在/etc/profile文件尾部添加配置
export PATH="/usr/local/git/bin:$PATH"

#使环境变量生效
source /etc/profile 

#检查一下版本号
git --version 
```