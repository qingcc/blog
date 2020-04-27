```
[原文链接](https://www.cnblogs.com/mingdeng3000/p/11655883.html)
```
[TOC]

shell命令大全笔记
篇幅有点长，但是认真看完对你是有很大帮助。
- `-print` 将匹配的文件输出到标准输出
- `-exec` 将匹配的文件执行该参数所给出的shell命令
- `-ok` 将匹配的文件执行该参数所给出的shell命令,每次执行命令有提示

```
find /etc -name passwd -exec rm {} \; ## {} \;中间有空格,不提示

find /etc -name passwd -ok rm {} \; ## {} \;中间有空格,每次删除都提示
```


- `-prune` 不在指定的目录中查找,不可以与-depth选项连用
案例一:查找/home目录下所有的.sh结尾的文件,忽略/home/ab目录
注意:不可以写成-path '/home/ab/' ; 要注意此命令的路径写法,要不同为绝对路径,要不同为相对路径;否则就为错误
```
[root@localhost home]# find /home -path '/home/ab' -prune -o -name '*.sh' -print
/home/t1.sh
/home/t2.sh
/home/t3.sh
/home/t4.sh
/home/t5.sh
/home/t6.sh
/home/t7.sh
/home/t8.sh
/home/t9.sh
[root@localhost home]# find . -path './ab' -prune -o -name '*.sh' -print
./t1.sh
./t2.sh
./t3.sh
./t4.sh
./t5.sh
./t6.sh
./t7.sh
./t8.sh
./t9.sh
[root@localhost home]#
```
案例二:在除dir0、dir1及子目录以外的目录下查找txt后缀文件
```
find ./ \( -path './dir0*' -o -path './dir1*' \) -a -prune -o -name *.txt -print
```
注意:圆括号()表示此处是一个复合表达式，它告诉 shell 不对圆括号里面的字符作特殊解释，而留给 find 命令去解释其意义。由于命令行不能直接使用圆括号，所以需要用反斜杠’\’进行转意。一定要注意’(‘，’)’左右两边都需空格。

案例三: 在dir0、dir1及子目录下查找txt后缀文件
```
find ./ \( -path './dir0*' -o -path './dir1*' \) -a -name *.txt -print
```
> -perm 按照文件权限来查找文件
> 
> -mtime -n 文件更改时间距离现在n天以内
> 
> -mtime +n 文件更改时间距离现在n天以前
> 
> -atime
> 
> -ctime


- xargs -exec 区别

> -exec: 对传递给exec执行的文件长度有限制;对处理的每一个匹配到的文件发起一个进程.
>
> xargs: 每次只获取一部分文件而不是全部文件,对处理的所有文件只有一个进程

案例一:
```
[root@localhost home]# ls
a ab jack t1.sh t2.sh t3.sh t4.sh t5.sh t6.sh t7.sh t8.sh t9.sh
[root@localhost home]# find /home -name "*.sh" | xargs chmod 777 ##对匹配到的文件统一授权
[root@localhost home]# find /home -name "*.sh" -exec chmod 000 {} \; ##对匹配到的文件统一授权
```
################
后台执行命令
################
atq 查询后台执行的命令
atrm 删除后台执行的命令
nohup 进程在退出帐户时该进程还不会结束,可以使用此命令
格式: nohup command &
[root@localhost home]# nohup ping 127.0.0.1 &
[2] 11319
[root@localhost home]# nohup: 忽略输入并把输出追加到"nohup.out"
[root@localhost home]# ls nohup.out
nohup.out
[root@localhost home]# jobs -l #查看后台运行的进程
[2]+ 11319 运行中 nohup ping 127.0.0.1 &
[root@localhost home]#
################
文件名置换
################

[...] 匹配[]中所含有的任何字符
[!...] 匹配[]中非感叹号!之后的字符

echo命令有很多功能，使用的时候需要加选项"-e"; 最常用的是下面几个：
\\ 反斜线
\a 报警符(BEL)
\b 退格符
\c 禁止尾随的换行符
\f 换页符
\n 换行符
\r 回车符
\t 水平制表符
\v 纵向制表符
-n 不输出行尾的换行符.
-e 允许对下面列出的加反斜线转义的字符进行解释.

案例一:
echo -e "what is your name: \c"
read name
echo 你的名字是:$name
等价于
echo -n "what is your name:"
read name
echo 你的名字是:$name


## read 命令
语法: read varible1 varible2 ...
案例一: 执行时一次性需要输入2个参数
echo -n "输入你的名字和别名: "
read name alia
echo 你的名字是:$name 你的别名是: $alia

## tee 命令
把输出的一个副本输送到标准输出，另一个
副本拷贝到相应的文件中。
tee -a files # -a表示追加到文件末尾
案例一: 将文件追加到nohup.out末尾
[root@localhost home]# head -4 /etc/passwd | tee -a nohup.out

command 1> filename #把标准输出重定向到一个文件中
command 1> filename 2>&1 #把标准输出和标准错误重定向到一个文件中

案例一: 将错误文件和正确文件输出到filename
cat>>filename 2>&1<<EOF
EOF

## exec命令
exec使用当前shell,没有开启子shell,执行的时候所有的环境
都将会被清除,并重新启动一个shell;执行完毕后关闭shell

################
命令执行顺序
################
(命令1;命令2;....) 在当前shell中执行
{命令1;命令2;....} 在当前子shell中执行

################
正则表达式
################
pattern\n{n\} 用来匹配前面pattern出现次数,n为次数
pattern\{n,\} 用来匹配前面pattern至少为n次
pattern\{n,m\} 用来匹配前面pattern出现次数为n与m次之间
#-----------------------------------------------------
案例一:
0 - 9 ] \ { 2 \ } - [ 0 - 9 ] \ { 2 \ } - [ 0 - 9 ] \ { 4 \ } ##对日期格式d d - m m - y y y y
[ 0 - 9 ] \ { 3 \ } \ . [ 0 - 9 ] \ { 3 \ } \ . [ 0 - 9 ] \ { 3 \ } \ . [ 0 - 9 ] \ { 3 \ } ##对I P地址格式nnn. nnn.nnn.nnn
[ ^ . * $ ] ##对匹配任意行
#-----------------------------------------------------

sort 默认按照第一列进行排序操作,以空格进行分割
sort -t （设置分隔符）和-k （指定某列） filename
########
案例:
1. 指定冒号为分隔符,按照第四列排序
sort -t: -g -k4 /etc/passwd

2. -g表示以数值类型排序,默认按照字符串类型,即把数值当做字符串来比对
[root@localhost ~]# sort -t: -g -k3 passwd #-g选项,按照常规数值排序
[root@localhost ~]# sort -t: -n -k3 passwd #-n选项,按照字符串数值排序
[root@localhost ~]# sort -t: -k3 passwd #把第三列作为常规类型排序,会2大于10类型的错误

3. -u 删除重复的内容
[root@localhost ~]# ls -l /etc | awk '{print $5}' | wc -l
292
[root@localhost ~]# ls -l /etc | awk '{print $5}' | sort -u |wc -l #sort -u去重
184
[root@localhost ~]#

##uniq的重复表示行连续重复,而sort -u的重复则对所有行来说
案例一:
[root@localhost ~]# uniq -c aa #显示aa文件中出现连续重复的行的次数
2 test
1 admin
1 test
1 jack
1 liu
3 test
[root@localhost ~]#

[root@localhost ~]# uniq -d aa #显示重复出现的行
test
test
aa
vm

[root@localhost ~]# uniq -f2 aa #查看第二域,忽略第一域,查看有重复的项
test aa
[root@localhost ~]#

##cut 剪切列或域
-d #指定与空格和Tab键不同的域分隔符
-f1,5 #剪切第1域,第5域

################################
paste:
-d #连接2个文件的连接分隔符,例如-d@

[root@localhost ~]# paste aa bb #将2个文件按照行合并
aroot admin docker aa
aroot admin oa bb
aroot admin
aroot admin
jack public
[root@localhost ~]#

#第一个文件作为第一行,第二个作为第二行
[root@localhost ~]# paste -s aa bb
aroot admin aroot admin aroot admin aroot admin jack public
docker aa oa bb
[root@localhost ~]#

#以空格进行分割,每行只显示2列内容
[root@localhost ~]# ls /etc | paste -d" " - -


################
登录环境
################
用户登录时，自动读取/etc目录下profile文件，此文件包含：
? 全局或局部环境变量。
? PATH信息。
? 终端设置。
? 安全命令。
? 日期信息或放弃操作信息。

stty用于设置终端特性.
stty -a #查看终端现在的stty选项
[root@localhost ~]# stty -a
speed 38400 baud; rows 28; columns 143; line = 0;
intr = ^C; quit = ^\; erase = ^H; kill = ^U; eof = ^D; eol = <undef>; eol2 = <undef>; swtch = <undef>; start = ^Q; stop = ^S; susp = ^Z;
rprnt = ^R; werase = ^W; lnext = ^V; flush = ^O; min = 1; time = 0;
-parenb -parodd -cmspar cs8 -hupcl -cstopb cread -clocal -crtscts
-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr icrnl ixon -ixoff -iuclc -ixany -imaxbel -iutf8
opost -olcuc -ocrnl onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
isig icanon iexten echo echoe echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke

#############################
案例一: 避免键盘上输入错误无法删除
#!/bin/bash
echo -n "请输入你的名字:"
stty erase '^H' #避免键盘上输入错误无法删除
read name
echo 你的名字为: $name
###########################
案例二:关闭回显功能
#!/bin/bash
#将终端特性保存为一个变量
savestty=`stty -g`
#更改终端特性echo
stty cbreak -echo
stty -a
echo -e "\nGive me that passwd: \c"
read passwd
echo -e "\nyou password is $passwd"
#恢复终端特性为保存的变量
stty $savestty
[root@localhost ~]#
#-----------------------------------------------------------------------
################
环境变量
################

unset 清除变量
set 查看所有本地定义的shell变量
${变量名:-变量值} #如果未初始化则使用花括号里面的变量值
#################################
#!/bin/bash
aab=vmsys
echo ${aab:-redhat} #如果变量没有设置初始值,则变量值为redhat
#################################

[root@localhost ~]# more ab.sh
#!/bin/bash
aab=vmsys
echo 变量内容为:${aab:-redhat} #如果变量没有设置初始值,则变量值为redhat
#------------- ------------------------------
color=blue
echo "未清除变量内容为: ${color:-grey}"
unset color #清除变量后,变量值为花括号里面内容
echo "清除后变量内容为: ${color:-grey}"

[root@localhost ~]# sh ab.sh
变量内容为:vmsys
未清除变量内容为: blue
清除后变量内容为: grey
[root@localhost ~]#
################
案例三:
#!/bin/bash
echo -n "what time do you wish to start the payrool: [03:00] "
read TIME
echo "process to start at ${TIME:=03:00} ok"

echo -n "is it a monthly or weekly run [weekly]"
read RUN_TYPE
echo "Run type is ${RUN_TYPE:=weekly}"
at -f $RUN_TYPE $TIME #-f表示一次性计划任务从文件读取

####
案例四: 提示信息自己定义的内容 ${变量名:? "提示内容..."}
echo "the file is ${files:? "sorry cannot locate the variable files"}"
[root@localhost ~]#

案例五:
#echo ${var0?jack} #未定义变量var0,则显示自定义的提示字符串jack

#echo ${var1:?jack} #未定义变量var1,则显示自定义的提示字符串jack

#echo ${var2:-jack} #没有设置var2的时候,后续echo $var2为空,当前${var2:-jack}代码显示为jack,属于一种替换操作!

#echo ${var3:=jack} #没有定义var3自动设置var3=jack;如果设置了变量就使用定义的
###########################################################################
测试变量是否取值，如果未设置，则返回一空串。方法如下：
$ { v a r i a b l e : + v a l u e }
案例1:
abc=100
echo ${abc+`route add default gw 172.16.38.254`} #如果没有定义变量abc就显示为空,定义了就执行后面命令

#######################################
在脚本中调用另一脚本(这实际上创建了一个子进程)

在一个脚本调用另外一个脚本需要设置PATH环境变量,并且还需要export导出;
案例一:
[root@localhost ~]# more father
#!/bin/bash
PATH=$PATH:/root
export PATH
echo "This is the father"
FILM="A few good Men"
echo "I like the film: $FILM"
export FILM

echo ------------------------------
child
echo "back to father"
echo "and the film is: $FILM"
[root@localhost ~]# more child
#!/bin/bash
echo "called from father.. i am the child"
echo "film name is: $FILM"
FILM="DIE HARD"
echo "changing film to: $FILM"
[root@localhost ~]#

###############

$# 传递到脚本的参数个数
$* 以一个单字符串显示所有向脚本传递的参数
$$ 脚本运行的当前进程ID号
$! 后台运行的最后一个进程的进程ID号
$@ 与$#相同,但是使用是要加上引号
$- 显示shell使用的当前选项,与set命令功能相同


[ -r filename -a -w filename ] #文件filename可读可写
或者
[ -r filename ] && [ -w filename ]
#######################################

字符串类型:
= 字符串相等
!= 字符串不等
-z 空串
-n 非空串
---------------------------------------
#############
流控制部分
#############
#!/bin/bash
echo "`basename $0`" #表示执行的变量本身

####################################

>&2 也就是把结果输出到和标准错误一样


###将每行做为一个单变量输入到line
#!/bin/bash
while read line
do
echo $line
done< filename.txt

#--------------------------------------------
#!/bin/bash
#root x 0 0 root /root /bin/bash
#bin x 1 1 bin /bin /sbin/nologin
###################################################
save_ifs=$IFS #保存默认分隔符
IFS=: #设置分隔符为冒号
while read A B C D E F G #读取七个变量
do
echo -e "$A\t$B\t$C\t$D\t$E\t$F\t$G\t" #设置分隔符为\t
done < /etc/passwd
IFS=$save_ifs #恢复默认分隔符
#----------------------------------------------
total=`expr ${total:=0} + ${items:=100}`

#####################
read每次读取2条记录
#------------
#!/bin/bash
while read rec1
do
read rec2
echo "one:"$rec1
echo "two:"$rec2
echo ------------------------------
done</etc/passwd
################################################
#当为数字的时候awk返回为1
[root@localhost ~]# echo 22 | awk '{if($0~/[^a-z A-Z]/) print "1"}'
1
[root@localhost ~]#

# 不能含有空格或者字母,否则返回1
[root@localhost ~]# echo 22 2 | awk '{if($0~/[a-zA-Z ]/) print "1"}'
1
[root@localhost ~]#
#-----------------------------------
do
{语句}
while(条件)

例子：
[chengmo@localhost nginx]# awk 'BEGIN{
total=0;
i=0;
do
{
total+=i;
i++;
}while(i<=100)
print total;
}'

结果: 5050

#!/bin/bash
read -p "请输入内容: " var
aa=`echo $var | awk '{if($0~/[a-zA-Z]/) print "1";else if($0~/[0-9]/) print "2"}'`
echo $aa

 

## shfit 向左偏移一位
#!/bin/bash

while [ $# -ne 0 ]
do
echo $1
shift
done
~
###########################
扩展AWK
###########################
1.
[root@localhost ~]# awk '(/^root/) {print $0}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
[root@localhost ~]#
[root@localhost ~]#
[root@localhost ~]# awk '/^root/ {print $0}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
[root@localhost ~]#

2. NF表示读取的域数
[root@localhost ~]# awk 'BEGIN{FS=":"} /^root/ {print $1,$NF}' /etc/passwd
root /bin/bash
[root@localhost ~]#

3.NR表示读取的记录数
[root@localhost ~]# awk 'BEGIN{FS=":"} /^root/ {print NR,$1,$NF}' /etc/passwd
1 root /bin/bash
[root@localhost ~]#

4.OFS="##" 输出字符串使用##
[root@localhost ~]# awk 'BEGIN{FS=":";OFS="##"} /^root/ {print NR,$1,$NF}' /etc/passwd
1##root##/bin/bash
[root@localhost ~]#


5.设置输出字段分隔符（OFS使用方法)

[chengmo@localhost ~]$ awk 'BEGIN{FS=":";OFS="^^"}/^root/{print FNR,$1,$NF}' /etc/passwd
1^^root^^/bin/bash

6.设置输出行记录分隔符(ORS使用方法）
[chengmo@localhost ~]$ awk 'BEGIN{FS=":";ORS="^^"}{print FNR,$1,$NF}' /etc/passwd
1 root /bin/bash^^2 bin /sbin/nologin^^3 daemon /sbin/nologin^^4 adm /sbin/nologin^^5 lp /sbin/nologin
从上面看，ORS默认是换行符，这里修改为：”^^”，所有行之间用”^^”分隔了。

7.ARGC得到所有输入参数个数，ARGV获得输入参数内容，是一个数组
[root@localhost ~]# awk 'BEGIN{FS=":"; print "ARGC="ARGC; for(k in ARGV) {print k"=" ARGV[k];} } ' /etc/passwd ADMIN JACK
ARGC=4
0=awk
1=/etc/passwd
2=ADMIN
3=JACK
[root@localhost ~]#

8.获取环境变量;ENVIRON是子典型数组，可以通过对应键值获得它的值。
[root@localhost ~]#
[root@localhost ~]# awk 'BEGIN{print ENVIRON["PATH"];}' /etc/passwd
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
[root@localhost ~]#
[root@localhost ~]#

9.格式如：awk ‘{action}’ 变量名=变量值 ，这样传入变量，可以在action中获得值。 注意：变量名与值放到’{action}’后面
[root@localhost ~]# aa='bdqn jack'
[root@localhost ~]#
[root@localhost ~]# echo | awk '{print aa}' aa="$aa"
bdqn jack
[root@localhost ~]#

10.只需要调用：awk内置变量 ENVIRON,就可以直接获得环境变量。它是一个字典数组。环境变量名 就是它的键值。
awk 'BEGIN{for (i in ENVIRON) {print i"="ENVIRON[i];}}'

11.true就返回1,false返回0
awk逻辑运算符
[chengmo@localhost ~]$ awk 'BEGIN{a=1;b=2;print (a>5 && b<=2),(a>5 || b<=2);}'
0 1

12. ?:运算符
[chengmo@localhost ~]$ awk 'BEGIN{a="b";print a=="b" ? "ok":"err";}'
ok
[root@localhost ~]# awk 'BEGIN{a="b";print a!="b" ? "ok":"err";}'
err

13. in运算符;in运算符，判断数组中是否存在该键值
[chengmo@localhost ~]$ awk 'BEGIN{a="b";arr[0]="b";arr[1]="c";print (a in arr);}'
0

[chengmo@localhost ~]$ awk 'BEGIN{a="b";arr[0]="b";arr["b"]="c";print (a in arr);}'
1
in运算符，判断数组中是否存在该键值

14.只需要将变量通过”+”连接运算。自动强制将字符串转为整型。非数字变成0，发现第一个非数字字符，后面自动忽略。10test10忽略后面的test10变成==>>10
[chengmo@centos5 ~]$ awk 'BEGIN{a="100";b="10test10";print (a+b+0);}'
110

15.awk数字转为字符串
[chengmo@centos5 ~]$ awk 'BEGIN{a=100;b=100;c=(a""b);print c}'
100100
只需要将变量与””符号连接起来运算即可

16.
[chengmo@centos5 ~]$ awk 'BEGIN{a="a";b="b";c=(a""b);print c}'
ab

[chengmo@centos5 ~]$ awk 'BEGIN{a="a";b="b";c=(a+b);print c}'
0
字符串连接操作通”二“，”+”号操作符。模式强制将左右2边的值转为 数字类型。然后进行操作。

17.数组的使用;split为分割字符串为数组
[root@localhost ~]# awk 'BEGIN{info="it is a test";lens=split(info,tA," ");print length(tA), tA[1],tA[2];}'
4 it is
[root@localhost ~]#
[chengmo@localhost ~]$ awk 'BEGIN{info="it is a test";split(info,tA," ");print asort(tA);}'
4
asort对数组进行排序，返回数组长度。

18. 循环打印数组
[chengmo@localhost ~]$ awk 'BEGIN{info="it is a test";split(info,tA," ");for(k in tA){print k,tA[k];}}'
4 test
1 it
2 is
3 a

for…in 输出，因为数组是关联数组，默认是无序的。所以通过for…in 得到是无序的数组。如果需要得到有序数组，需要通过下标获得。
[chengmo@localhost ~]$ awk 'BEGIN{info="it is a test";tlen=split(info,tA," ");for(k=1;k<=tlen;k++){print k,tA[k];}}'
1 it
2 is
3 a
4 test

注意：数组下标是从1开始，与c数组不一样。

19.判断数组
正确判断方法：
[chengmo@localhost ~]$ awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";if( "c" in tB){print "ok";};for(k in tB){print k,tB[k];}}'
a a1
b b1

if(key in array) 通过这种方法判断数组中是否包含”key”键值。

 

20.删除键值：
[chengmo@localhost ~]$ awk 'BEGIN{tB["a"]="a1";tB["b"]="b1";delete tB["a"];for(k in tB){print k,tB[k];}}'
b b1

delete array[key]可以删除，对应数组key的，序列值

21. 多重嵌套,每条命令语句后面可以用“；”号结尾
awk 'BEGIN{
test=100;
if(test>90)
{
print "very good";
}
else if(test>60)
{
print "good";
}
else
{
print "no pass";
}
}'

22.
awk 'BEGIN{
test=100;
total=0;
while(i<=test)
{
total+=i;
i++;
}
print total;
}'
5050

23. for循环
for循环有两种格式：
格式1：
for(变量 in 数组)
{语句}

格式2：
for(变量;条件;表达式)
{语句}

案例:
awk 'BEGIN{
for(k in ENVIRON)
{
print k"="ENVIRON[k];
}
}'
#------------------
awk 'BEGIN{
total=0;
for(i=0;i<=100;i++)
{
total+=i;
}
print total;
}'

5050


24.do循环
格式：
do
{语句}while(条件)

案例：
awk 'BEGIN{
total=0;
i=0;
do
{
total+=i;
i++;
}while(i<=100)
print total;
}'
5050

## 案例:将具有字符串 ae 或 alle 或 anne 或 allnne 的所有记录打印至标准输出
在正则表达式中将字符串组合在一起。命令行：
awk '/a(ll)?(nn)?e/' testfile

## 内置函数:

#+ 表示匹配前面的子表达式一次或多次。要匹配 + 字符，请使用 \+

awk 'BEGIN{info="this is a test2010test!";gsub(/[0-9]+/,"!",info);print info}'
this is a test!test!
#-------------------------------------------------------------------------------
gsub( Ere, Repl, [ In ] ) 除了正则表达式所有具体值被替代这点，它和 sub 函数完全一样地执行，。

sub( Ere, Repl, [ In ] ) 用 Repl 参数指定的字符串替换 In 参数指定的字符串中的由 Ere 参数指定的扩展正则表达式的第一个具体值。
sub 函数返回替换的数量。出现在 Repl 参数指定的字符串中的 &（和符号）由 In 参数指定的与 Ere 参数的
指定的扩展正则表达式匹配的字符串替换。如果未指定 In 参数，缺省值是整个记录（$0 记录变量）。

index( String1, String2 ) 在由 String1 参数指定的字符串（其中有出现 String2 指定的参数）中，返回位置，从 1 开始编号。
如果 String2 参数不在 String1 参数中出现，则返回 0（零）。

length [(String)] 返回 String 参数指定的字符串的长度（字符形式）。如果未给出 String 参数，则返回整个记录的长度（$0 记录变量）。

blength [(String)] 返回 String 参数指定的字符串的长度（以字节为单位）。如果未给出 String 参数，则返回整个记录的长度（$0 记录变量）。

substr( String, M, [ N ] ) 返回具有 N 参数指定的字符数量子串。子串从 String 参数指定的字符串取得，其字符以 M 参数指定的位置开始。
M 参数指定为将 String 参数中的第一个字符作为编号 1。如果未指定 N 参数，则子串的长度将是 M 参数指定的位置到 String 参数的末尾 的长度。

match( String, Ere ) 在 String 参数指定的字符串（Ere 参数指定的扩展正则表达式出现在其中）中返回位置（字符形式），
从 1 开始编号，或如果 Ere 参数不出现，则返回 0（零）。RSTART 特殊变量设置为返回值。RLENGTH 特殊变量设置为匹配的字符串的长度，或如果未找到任何匹配，则设置为 -1（负一）。

split( String, A, [Ere] ) 将 String 参数指定的参数分割为数组元素 A[1], A[2], . . ., A[n]，并返回 n 变量的值。
此分隔可以通过 Ere 参数指定的扩展正则表达式进行，或用当前字段分隔符（FS 特殊变量）来进行（如果没有给出 Ere 参数）。除非上下文指明特定的元素还应具有一个数字值，否则 A 数组中的元素用字符串值来创建。

tolower( String ) 返回 String 参数指定的字符串，字符串中每个大写字符将更改为小写。大写和小写的映射由当前语言环境的 LC_CTYPE 范畴定义。

toupper( String ) 返回 String 参数指定的字符串，字符串中每个小写字符将更改为大写。大写和小写的映射由当前语言环境的 LC_CTYPE 范畴定义。

sprintf(Format, Expr, Expr, . . . ) 根据 Format 参数指定的 printf 子例程格式字符串来格式化 Expr 参数指定的表达式并返回最后生成的字符串。

#################################################
格式化字符串输出（sprintf使用）
格式化字符串格式：
其中格式化字符串包括两部分内容: 一部分是正常字符, 这些字符将按原样输出; 另一部分是格式化规定字符, 以"%"开始, 后跟一个或几个规定字符,用来确定输出内容格式。

格式符 说明
%d 十进制有符号整数
%u 十进制无符号整数
%f 浮点数
%s 字符串
%c 单个字符
%p 指针的值
%e 指数形式的浮点数
%x %X 无符号以十六进制表示的整数
%o 无符号以八进制表示的整数
%g 自动选择合适的表示法
###############################################

函数名 说明
atan2( y, x ) 返回 y/x 的反正切。
cos( x ) 返回 x 的余弦；x 是弧度。
sin( x ) 返回 x 的正弦；x 是弧度。
exp( x ) 返回 x 幂函数。
log( x ) 返回 x 的自然对数。
sqrt( x ) 返回 x 平方根。
int( x ) 返回 x 的截断至整数的值。
rand( ) 返回任意数字 n，其中 0 <= n < 1。
srand( [Expr] ) 将 rand 函数的种子值设置为 Expr 参数的值，或如果省略 Expr 参数则使用某天的时间。返回先前的种子值。
####################################

## 获取随机数
[root@localhost ~]# awk 'BEGIN{srand();fr=int(10*rand());print fr;}'
7
[root@localhost ~]#

## AWK扩展用法

1. getline 变量名
[root@localhost ~]# awk 'BEGIN{print "Enter your name:";getline name;print name;}'
Enter your name:
hello
hello
[root@localhost ~]#

[root@localhost home]# awk 'BEGIN{while(getline < "/etc/passwd"){print $0;};close("/etc/passwd");}' | head -2
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
逐行读取外部文件(getline使用方法）
[root@localhost home]# awk 'BEGIN{while("cat /etc/passwd"|getline){print $0;};close("/etc/passwd");}' | head -2
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
[root@localhost home]#

##合并文件案例:
1.
[root@localhost home]# more a.txt
100 wang man
200 wangsan woman
300 wangming man
400 wangzheng man
[root@localhost home]# more b.txt
100 90 80
200 80 70
300 60 50
400 70 20
[root@localhost home]# awk '{printf("%s ", $0); getline<"b.txt" ;print $2,$3}' a.txt
100 wang man 90 80
200 wangsan woman 80 70
300 wangming man 60 50
400 wangzheng man 70 20
[root@localhost home]#
#
#### next 用法
#读取文件的偶数行
当记录行号除以2余 1，就跳过当前行。下面的print NR,$0也不会执行。 下一行开始，程序有开始判断NR%2 值。
这个时候记录行号是：2 ，就会执行下面语句块：'print NR,$0'
[root@localhost home]# more a.txt
100 wang man
200 wangsan woman
300 wangming man
400 wangzheng man
[root@localhost home]# awk 'NR%2==1 {next} {print NR,$0}' a.txt
2 200 wangsan woman
4 400 wangzheng man
[root@localhost home]#


2. 变量名=system("命令")
[root@localhost home]# awk 'BEGIN{b=system("ls -al");print b;}'
总用量 4
drwxr-xr-x. 3 root root 18 12月 13 09:02 .
dr-xr-xr-x. 20 root root 4096 12月 13 08:03 ..
drwx------. 5 jack jack 128 12月 10 16:36 jack
0
[root@localhost home]#

## 时间函数#
函数名 说明
----------------------------- ------------------------------------------
mktime( YYYY MM DD HH MM SS[ DST]) 生成时间格式
strftime([format [, timestamp]]) 格式化时间输出，将时间戳转为时间字符串
systime() 得到时间戳,返回从1970年1月1日开始到当前时间(不计闰年)的整秒数
#########
strftime日期和时间格式说明符

格式 描述
%a 星期几的缩写(Sun)
%A 星期几的完整写法(Sunday)
%b 月名的缩写(Oct)
%B 月名的完整写法(October)
%c 本地日期和时间
%d 十进制日期
%D 日期 08/20/99
%e 日期，如果只有一位会补上一个空格
%H 用十进制表示24小时格式的小时
%I 用十进制表示12小时格式的小时
%j 从1月1日起一年中的第几天
%m 十进制表示的月份
%M 十进制表示的分钟
%p 12小时表示法(AM/PM)
%S 十进制表示的秒
%U 十进制表示的一年中的第几个星期(星期天作为一个星期的开始)
%w 十进制表示的星期几(星期天是0)
%W 十进制表示的一年中的第几个星期(星期一作为一个星期的开始)
%x 重新设置本地日期(08/20/99)
%X 重新设置本地时间(12：00：00)
%y 两位数字表示的年(99)
%Y 当前月份
%Z 时区(PDT)
%% 百分号(%)
##########################

[root@localhost home]# awk 'BEGIN{tstamp=mktime("2001 01 01 12 12 12");print strftime("%c",tstamp);}'
2001年01月01日 星期一 12时12分12秒
[root@localhost home]#
求2个时间段中间时间差,介绍了strftime使用方法
[root@localhost home]# awk 'BEGIN{tstamp1=mktime("2001 01 01 12 12 12");tstamp2=mktime("2001 02 01 0 0 0");print tstamp2-tstamp1;}'
2634468
[root@localhost home]#

 


###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
break 当 break 语句用于 while 或 for 语句时，导致退出程序循环。
continue 当 continue 语句用于 while 或 for 语句时，使程序循环移动到下一个迭代。
next 能能够导致读入下一个输入行，并返回到脚本的顶部。这可以避免对当前输入行执行其他的操作过程。
exit 语句使主输入循环退出并将控制转移到END,如果END存在的话。如果没有定义END规则，或在END中应用exit语句，则终止脚本的执行
###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


###########################
AWK
----------
模式部分: 决定动作语句何时出发及触发事件,如果省略将时刻保持执行状态.
动作部分: 在大括号{ }内指明.
模式:
BEGIN.....END.....
begin: 设置计数和打印头
end:完成文本浏览动作后打印输出文件总数和结尾状态标记.
####################################################
{ } 花括号里面的是动作, ( )圆括号里面的是条件
---------------------------------------------------
案例一:
awk 'BEGIN {print "Name\n-------"} {print $1} END {"end-of-report"}' grade.txt

案例二:
awk -F ":" '$4=="50"' /etc/passwd

awk -F ":" '{if($1~/root/) print $0}' /etc/passwd

awk -F ":" '$4=="50" {print $0}' /etc/passwd

[root@localhost ~]# awk '/bash/' /etc/passwd

案例三:
[root@localhost ~]# awk -F ":" '{if($3<$4) print $0 "--------"}' /etc/passwd
adm:x:3:4:adm:/var/adm:/sbin/nologin--------
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin--------
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin--------
games:x:12:100:games:/usr/games:/sbin/nologin--------
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin--------
[root@localhost ~]#

案例四: 定义变量t=0,匹配到每次加1,末尾打印内容
[root@localhost ~]# awk 'BEGIN{t=0} {if($0~/bash$/) t++} END{ print t}' /etc/passwd
2
[root@localhost ~]#

[root@localhost ~]# awk '$0~/(root|jack)/' /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
jack:x:1000:1000:jack:/home/jack:/bin/bash
dockerroot:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost ~]#

案例五: && || !
[root@localhost ~]# awk '{if($3 > $2 && $0~/rpc/) print $0}' /etc/passwd
rpcuser:x:29:29:RPC Service User:/var/lib/nfs:/sbin/nologin
[root@localhost ~]#

##内置变量
NF 浏览记录的域个数
NR 已读取的记录数

[root@localhost ~]# awk 'END{print NR}' /etc/passwd #输入文件的记录数
49
[root@localhost ~]#
[root@localhost ~]# awk -F ":" 'END{print NF,NR,FILENAME}' /etc/passwd
7 49 /etc/passwd
# NF表示以冒号做分隔读取了几个区域;
# NR表示读取的记录数;
# FILENAME表示文件名
#===============================
[root@localhost ~]# awk -F ":" '{if($0~/bash/ && $3=$4 && NR>0) print $0}' /etc/passwd
jack x 1 1000 jack /home/jack /bin/bash
[root@localhost ~]#

[root@localhost network-scripts]# echo $PWD | awk -F / '{print NF}'
4
[root@localhost network-scripts]# echo $PWD | awk -F / '{print $NF}'
network-scripts
[root@localhost network-scripts]# echo $PWD | awk -F / '{print $4}'
network-scripts

#定义变量bline为3,当第三列小于3的时候打印满足条件全部内容
[root@localhost ~]# awk -F ":" 'BEGIN {bline=3} {if ($3<bline) print $0}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
[root@localhost ~]#

##### 当条件有多个圆括号的时候需要添加分号 ############
#域值修改
[root@localhost ~]# awk -F ":" '{if($1=="root") $3=$3+100; print $1,$3}' aa
root 100
bin 1
daemon 2
[root@localhost ~]# more aa
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
[root@localhost ~]#

#对匹配到的字符串,进行重新变量赋值
[root@localhost ~]# awk -F ":" '{if($1=="root")($1="admin") ; print $0}' aa
admin x 0 0 root /root /bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
[root@localhost ~]#

## 模式后面 使用花括号将只对修改的部分进行显示结果
[root@localhost ~]# awk -F ":" '{if($1=="root") {$1="admin" ; print $0} }' aa
admin x 0 0 root /root /bin/bash
[root@localhost ~]#

[root@localhost ~]# awk -F ":" '{if($1=="root") ($1="admin") ($3=$3+100); { print $0} }' aaadmin x 100 0 root /root /bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin

## 模式后面 使用花括号将只对修改的部分进行显示结果
[root@localhost ~]# awk -F ":" '{if($1=="root") {($1="admin")($3=$3+100); print $0} }' aa
admin x 100 0 root /root /bin/bash
[root@localhost ~]#


## 创建新域列 $10
[root@localhost ~]# awk -F ":" '{if($1=="root") {($1="admin")($10=$3+100); print $10} }' aa
100
[root@localhost ~]#

 


## 创建自定义列
[root@localhost ~]# awk -F ":" 'BEGIN {print "Uname \t\t Login"} {if($3<$4) print $1,"\t\t"$7}' /etc/passwd
Uname Login
adm /sbin/nologin
lp /sbin/nologin
mail /sbin/nologin
games /sbin/nologin
ftp /sbin/nologin
[root@localhost ~]#


## 将整个文件的第三域相加
[root@localhost ~]# awk -F ":" '(total+=$3); END{print "第三列相加结果为: "total}' aa
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
第三列相加结果为: 3
[root@localhost ~]#

## 只显示匹配的内容
[root@localhost ~]# awk -F ":" '{(total+=$3)}; END{print "第三列相加结果为: "total}' aa
第三列相加结果为: 3
[root@localhost ~]#

## 创建变量tot,设置自动相加,在结尾打印汇总结果
[root@localhost ~]# ls -l | awk ' / ^[^X]/ {print $9 "\t" $5} {tot+=$5} END{print "汇总后结果为:" tot}'
汇总后结果为:14523
[root@localhost ~]#

######################
内置函数
######################

## 打印$1长度---->>> length()
[root@localhost ~]# awk -F ":" 'BEGIN {Uname "\t" Login} {if($3>$4) print length($1),$0}' /etc/passwd
4 sync:x:5:0:sync:/sbin:/bin/sync
8 shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
4 halt:x:7:0:halt:/sbin:/sbin/halt
8 operator:x:11:0:operator:/root:/sbin/nologin
7 polkitd:x:999:998:User for polkitd:/:/sbin/nologin
14 libstoragemgmt:x:998:996:daemon account for libstoragemgmt:/var/run/lsm:/sbin/nologin


## gsub替换; 使用正则表达式替换, (/目标模式/,替换模式)
[root@localhost ~]# awk -F ":" 'gsub(/root/,"admin") {print $0}' /etc/passwd
admin:x:0:0:admin:/admin:/bin/bash
operator:x:11:0:operator:/admin:/sbin/nologin
dockeradmin:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost ~]#

[root@localhost ~]# awk -F: '{gsub(/bash/,"admin",$0);print $0}' passwd
root:x:0:0:root:/root:/bin/admin
root:x:0:0:/bin/admin:/root:/bin/admin
root:x:0:0:/bin/admin:/root:/bin/admin
jack:x:1000:1000:jack:/home/jack:/bin/admin
[root@localhost ~]#


## gsub()带条件替换;当替换为字符串需要使用" ";替换内容为整形不需要" "
[root@localhost ~]# awk -F ":" '{if($3<$4) { print $0}}' /etc/passwd
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin


[root@localhost ~]# awk -F ":" '{if($3<$4) { gsub(/adm/,"jack");print $0}}' /etc/passwd
jack:x:3:4:jack:/var/jack:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
[root@localhost ~]#

#################################################################################
案例: 对比 sub() gsub()区别
#################################
#
#gsub()全局替换
#sub() 替换每行的第一个
#substr() 显示指定string长度位置
#
#################################
[root@localhost ~]# more passwd 源文件
root:x:0:0:root:/root:/bin/bash
root:x:0:0:/bin/bash:/root:/bin/bash
root:x:0:0:/bin/bash:/root:/bin/bash
jack:x:1000:1000:jack:/home/jack:/bin/bash
[root@localhost ~]# awk -F: '$0~/bash/ {gsub(/bash/,"admin");print $0}' passwd #替换全文bash为admin
root:x:0:0:root:/root:/bin/admin
root:x:0:0:/bin/admin:/root:/bin/admin
root:x:0:0:/bin/admin:/root:/bin/admin
jack:x:1000:1000:jack:/home/jack:/bin/admin
[root@localhost ~]#
[root@localhost ~]# awk -F: '$0~/bash/ {sub(/bash/,"admin");print $0}' passwd #替换每行第一个bash为admin
root:x:0:0:root:/root:/bin/admin
root:x:0:0:/bin/admin:/root:/bin/bash
root:x:0:0:/bin/admin:/root:/bin/bash
jack:x:1000:1000:jack:/home/jack:/bin/admin
[root@localhost ~]#
###################################################################################
# substr(str,n,m) #显示字符串str从n到m长度大小的内容

[root@localhost ~]# awk '$1~/root/ {print substr($1,1,2)}' /etc/passwd
ro
op
do
[root@localhost ~]# awk '$1~/root/ {print $0}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/root:/sbin/nologin
dockerroot:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost ~]#
[root@localhost ~]# awk '$1~/root/ {print substr($1,1,2)}' /etc/passwd #
ro
op
do
[root@localhost ~]#

#
[root@localhost ~]# awk 'BEGIN {str="Iloveyou"}END{print substr(str,2)}' bb ##其中bb可以随便写,begin定义内容,end截取内容
loveyou
[root@localhost ~]#


## 查询字符串s中t出现的第一位置,字符串需要用双引号括起来. index( )
[root@localhost ~]# awk 'BEGIN {print index("root","o")}' /etc/passwd
2

## 测试目标字符串是否包含查找字符串的一部分,查找到了就返回所在位置,没有找到就返回0
[root@localhost ~]# awk 'BEGIN {print match("ABCD",/D/)}'
4
[root@localhost ~]# awk 'BEGIN {print match("ABCD",/d/)}'
0
[root@localhost ~]#


## split 返回字符串数组元素个数
#将第一行切割为以冒号作为分隔符的数组
[root@localhost ~]# head -1 /etc/passwd | awk 'BEGIN{ } {print split($0,array,":")}'
7
[root@localhost ~]#

# sub(/替换前内容/,"替换后字符串",$0)
[root@localhost ~]# awk -F: '{if($1=="root") {print $0}}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
[root@localhost ~]#
[root@localhost ~]#
[root@localhost ~]# awk -F: '{if($1=="root") {sub(/root/,"admin",$0) ;print $0}}' /etc/passwd #sub(/root/,"admin",$0)中的$0可以不写
admin:x:0:0:root:/root:/bin/bash
[root@localhost ~]#

 

### 定义变量AGE,向awk传值
[root@localhost ~]# awk -F: '{if($3<AGE) print $0}' AGE=5 /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@localhost ~]#


[root@localhost ~]# who
root pts/0 2018-12-12 09:19 (192.168.80.8)
[root@localhost ~]#
[root@localhost ~]# who | awk '{if($1==user) print $1 " You are connected to " $2}' user=$LOGNAME #传递变量
root You are connected to pts/0
[root@localhost ~]#

####################
将awk写入到脚本文件
####################
#!/bin/awk -f
BEGIN { }
{ }
END { }
#############################################

#awk; 定义变量t,每次值加1,使用split()切割为数组, 使用for循环来遍历数组内容
[root@localhost ~]# head -1 /etc/passwd |awk -F ":" 'BEGIN{t=0} {split($0,my,":")}END{for(i in my) {t+=1;print "my["t"]="my[i]}}'
my[1]=0
my[2]=root
my[3]=/root
my[4]=/bin/bash
my[5]=root
my[6]=x
my[7]=0
[root@localhost ~]#


####
sed
####
##
1. [root@localhost ~]# sed -n '10p' /etc/passwd
operator:x:11:0:operator:/root:/sbin/nologin
[root@localhost ~]#


2.[root@localhost ~]# sed -n '/^root/p' /etc/passwd
root:x:0:0:root:/root:/bin/bash
[root@localhost ~]#

3. 模式与行号混合方式;格式: line_number,/pattern/
案例:
4,/the/ #表示查询第四行的the

4. 打印模式匹配的行号,使用格式/pattern/=
[root@localhost ~]# sed -n -e '/root/p' -e '/root/=' /etc/passwd
root:x:0:0:root:/root:/bin/bash
1
operator:x:11:0:operator:/root:/sbin/nologin
10
dockerroot:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
48
[root@localhost ~]#

5. a\，可以将指定文本一行或多行附加到指定模式位置;"a\"中的反斜线表示换行
6. i\,可以将指定文本一行或多行插入到指定模式位置;"a\"中的反斜线表示换行
7. c\,将指定模式匹配的行替换;"c\"中的反斜线表示换行
8. d\,将指定模式匹配的行删除;"d\"中的反斜线表示换行

[root@localhost ~]# sed -n '/^root/'p /etc/passwd
root:x:0:0:root:/root:/bin/bash
[root@localhost ~]# sed -n '/^root/ c\ "admin"' /etc/passwd
"admin"
[root@localhost ~]# sed -n '1 c\ jack' /etc/passwd #将文件的第一行替换为字符串jack
jack
[root@localhost ~]#
[root@localhost ~]# sed -n '1,2'p /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
[root@localhost ~]# sed -n '1,2 c\ admin' /etc/passwd #将第一行到第二行替换为字符串admin
adminp
[root@localhost ~]#

#####################3
替换命令: 用替换模式替换指定模式

[address,[address]] s/ pattern-to-find / replacement-pattern/ [g p w n] #注意: n选项将会使p选项无效
发现模式 替换模式

g: 默认只替换第一次出现的模式,使用g表示全局替换
p: 缺省将所有被替换行写入标准输出,加p选项将使-n选项无效
w: 文件名,使用此选项将输出重定向到一个文件
#--------------------------------------
[root@localhost ~]# sed -n 's/root/ROOT/'p /etc/passwd
ROOT:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost ~]#
[root@localhost ~]# sed -n 's/root/ROOT/g'p /etc/passwd
ROOT:x:0:0:ROOT:/ROOT:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost ~]#
[root@localhost shells]# sed -n 's/root/ROOT/w file.txt' /etc/passwd #替换一次,保存文件
[root@localhost shells]# ls
file.txt
[root@localhost shells]# more file.txt
ROOT:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost shells]#
[root@localhost shells]# sed -n 's/root/ROOT/g w file.txt' /etc/passwd #全局替换
[root@localhost shells]# more file.txt
ROOT:x:0:0:ROOT:/ROOT:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost shells]#

[root@localhost shells]# sed -n 's/root/ROOT/g p w file.txt' /etc/passwd #p屏幕显示结果;w file.txt保存为文件;g表示全局匹配
ROOT:x:0:0:ROOT:/ROOT:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost shells]# ls
file.txt
[root@localhost shells]# more file.txt
ROOT:x:0:0:ROOT:/ROOT:/bin/bash
operator:x:11:0:operator:/ROOT:/sbin/nologin
dockerROOT:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost shells]#

#####################################
sed -n 's/pattern/replacement-pattern-string &/p'
#在指定的字符串前插入内容:
&:保存发现模式以便重新调用它,然后把发现模式内容放在替换字符串后面

案例一: 在root字符串前插入"--ADMINISTRATOR--"
[root@localhost shells]# sed -n 's/root/"--ADMINISTRATOR--" &/p' /etc/passwd
"--ADMINISTRATOR--" root:x:0:0:root:/root:/bin/bash
operator:x:11:0:operator:/"--ADMINISTRATOR--" root:/sbin/nologin
docker"--ADMINISTRATOR--" root:x:988:982:Docker User:/var/lib/docker:/sbin/nologin
[root@localhost shells]#
[root@localhost shells]#
##############################################3

sed -n '[address[,address]] w filename' pathname #将指定的行保存到filename

案例:
[root@localhost shells]# ls
[root@localhost shells]# sed -n '1,2 w file.txt' /etc/passwd
[root@localhost shells]# ls
file.txt
[root@localhost shells]# more file.txt
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
[root@localhost shells]#

##################################################

address r filename #从一个文件读取文件内容到另一个文件中

案例:
[root@localhost shells]# sed '/root/ r jack.txt' /etc/passwd | more ##将jack.txt文件读取存放到/root/模式后
root:x:0:0:root:/root:/bin/bash
####
jack
####
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin

##################################################
[root@localhost ~]# more ab
Mr Willis
[root@localhost ~]# sed 's/Mr/ & Jack/g' ab
Mr Jack Willis
[root@localhost ~]# sed 's/Mr/ & Jack/p' ab #将会打印所有文件内容,
Mr Jack Willis
Mr Jack Willis
[root@localhost ~]# sed -n 's/Mr/ & Jack/p' ab
Mr Jack Willis
[root@localhost ~]#

[root@localhost ~]# echo "file" | sed 's/$/.doc/g' #添加文件后缀
file.doc
[root@localhost ~]#

@@@@@@@@@@@@@@@@
1. sed 's///g'

2. sed 'address[,address] w filename'

3. sed 'address[,address] r filename'

4. sed -n 's/pattern/replacement-pattern-string &/p'

5. a\，可以将指定文本一行或多行附加到指定模式位置;"a\"中的反斜线表示换行

6. i\,可以将指定文本一行或多行插入到指定模式位置;"a\"中的反斜线表示换行

7. c\,将指定模式匹配的行替换;"c\"中的反斜线表示换行

8. d\,将指定模式匹配的行删除;"d\"中的反斜线表示换行

9. sed -n '1,$ l' #l将显示所有控制字符,很少用
@@@@@@@@@@@@@@@@

 

 

 

 

 

 

 

 

 

 

 

 


####
awk
####

 

一.条件判断语句(if)

if(表达式) #if ( Variable in Array )
语句1
else
语句2

格式中"语句1"可以是多个语句，如果你为了方便Unix awk判断也方便你自已阅读，你最好将多个语句用{}括起来。Unix awk分枝结构允许嵌套，其格式为：

if(表达式)

{语句1}

else if(表达式)
{语句2}
else
{语句3}

[chengmo@localhost nginx]# awk 'BEGIN{
test=100;
if(test>90)
{
print "very good";
}
else if(test>60)
{
print "good";
}
else
{
print "no pass";
}
}'

very good

 

每条命令语句后面可以用“；”号结尾。


#------------------------------------------
二.循环语句(while,for,do)

1.while语句

格式：

while(表达式)

{语句}

例子：

[chengmo@localhost nginx]# awk 'BEGIN{
test=100;
total=0;
while(i<=test)
{
total+=i;
i++;
}
print total;
}'
5050
#------------------------------------------
2.for 循环

for循环有两种格式：

格式1：

for(变量 in 数组)

{语句}

例子：

[chengmo@localhost nginx]# awk 'BEGIN{
for(k in ENVIRON)
{
print k"="ENVIRON[k];
}
}'

AWKPATH=.:/usr/share/awk
OLDPWD=/home/web97
SSH_ASKPASS=/usr/libexec/openssh/gnome-ssh-askpass
SELINUX_LEVEL_REQUESTED=
SELINUX_ROLE_REQUESTED=
LANG=zh_CN.GB2312

。。。。。。

说明：ENVIRON 是awk常量，是子典型数组。

格式2：

for(变量;条件;表达式)

{语句}

例子：

[chengmo@localhost nginx]# awk 'BEGIN{
total=0;
for(i=0;i<=100;i++)
{
total+=i;
}
print total;
}'

5050
#------------------------------------------
3.do循环

格式：

do

{语句}while(条件)

例子：

[chengmo@localhost nginx]# awk 'BEGIN{
total=0;
i=0;
do
{
total+=i;
i++;
}while(i<=100)
print total;
}'
5050

以上为awk流程控制语句，从语法上面大家可以看到，与c语言是一样的。有了这些语句，其实很多shell程序都可以交给awk，而且性能是非常快的。

break 当 break 语句用于 while 或 for 语句时，导致退出程序循环。
continue 当 continue 语句用于 while 或 for 语句时，使程序循环移动到下一个迭代。
next 能能够导致读入下一个输入行，并返回到脚本的顶部。这可以避免对当前输入行执行其他的操作过程。
exit 语句使主输入循环退出并将控制转移到END,如果END存在的话。如果没有定义END规则，或在END中应用exit语句，则终止脚本的执行。

三、性能比较
[chengmo@localhost nginx]# time (awk 'BEGIN{ total=0;for(i=0;i<=10000;i++){total+=i;}print total;}')
50005000

real 0m0.003s
user 0m0.003s
sys 0m0.000s
[chengmo@localhost nginx]# time(total=0;for i in $(seq 10000);do total=$(($total+i));done;echo $total;)
50005000

real 0m0.141s
user 0m0.125s
sys 0m0.008s

实现相同功能，可以看到awk实现的性能是shell的50倍！