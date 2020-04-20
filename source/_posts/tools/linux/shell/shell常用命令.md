[原文链接](https://www.cnblogs.com/chen-lhx/p/5743438.html)

[TOC]

Shell脚本是Linux开发工作中常用的工具，但是我一直没有找到一个适合自己的简明扼要的HandBook。在工作过程中整理了一下，贴在这里已备查看。

 

1           Shell中的特殊符号

1.1           $  美元符号。用来表示变量的值。如变量NAME的值为Mike，则使用$NAME就可以得到“Mike”这个值。

1.2          #  井号。除了做为超级用户的提示符之外，还可以在脚本中做为注释的开头字母，每一行语句中，从#号开始的部分就不执行了。

1.3           “”  双引号。shell不会将一对双引号之间的文本中的大多数特殊字符进行解释，如#不再是注释的开头，它只表示一个井号“#”。但$仍然保持特殊含义。（在双引号中的$加变量名，即：$PARAM_NAME，依然会转换成变量的值。）

1.3.1     双引号对于某些特殊符号是不起作用的， 例如：”,$,\,`(反引号)

1.3.2     双引号和单引号不能嵌套。即：echo ‘””’  输出””,  echo “’’” 输出’’

1.4           ‘’  单引号。shell不会将一对单引号之间的任何字符做特殊解释。（在双引号中的$加变量名，即：$PARAM_NAME，不会转换成变量的值。）

1.4.1     echo “$HOME”    (结果：/home/xiongguoan)

1.5          ``  倒引号。命令替换。在倒引号内部的shell命令首先被执行，其结果输出代替用倒引号括起来的文本，不过特殊字符会被shell解释。

1.5.1     echo ‘$HOME’    (结果:$HOME)

1.6          \  斜杠。用来去掉在shell解释中字符的特殊含义。在文本中，跟在\后面的一个字符不会被shell特殊解释，但其余的不受影响。

1.7          []中括号， 主要是用来测试条件的，通常放在if语句的后面。 （不过还是不太明白）,但是中括号本身不会在测试语句执行后消失。

1.7.1     echo [$HOME]   (结果：出现错误)

1.7.2     echo [$HOME ]   (结果：[/home/xiongguoan ]) (注意：HOME后面有空格哦。)

1.7.3     echo [$HOME –eq ‘/xiong’]  (结果：[/home/xiongguoan –eq /xiong])

 

1.8          {}大括号，主要是和$符号配合，作为字符串连接来使用

1.8.1     echo ${HOME}ismydir   （结果：/home/xiongguoanismydir）

 

2           预定义的变量

2.1          特殊变量

 

$      shell变量名的开始，如$var

|      管道，将标准输出转到下一个命令的标准输入

$#     记录传递给Shell的自变量个数

#      注释开始

&      在后台执行一个进程

？     匹配一个字符

*      匹配0到多个字符(与DOS不同，可在文件名中间使用，并且含.)

$-     使用set及执行时传递给shell的标志位

$!     最后一个子进程的进程号 

$?     取最近一次命令执行后的退出状态(返回码)

$*     传递给shell script的参数

$@     所有参数，个别的用双引号括起来

$0     当前shell的名字

$n     (n:1-) 位置参数

$$     进程标识号(Process Identifier Number, PID)

>      输出重定向

  <      输入重定向

  >>      输出重定向（追加方式）

  []     列出字符变化范围，如[a-z]

 

 

2.2          代值变量

 

* 任意字符串 

? 一个任意字符 

[abc] a, b, c三者中之一 

[a-n] 从a到n的任一字符 

 

 

2.3          特殊字符的表达

 

\b 退回  
\c 打印一行时没有换行符 这个我们经常会用到  
\f 换页  
\r 回车  
\t 制表  
\v 垂直制表  
\\ 反斜线本身 

 

2.4          其他字符

2.4.1     分号

; 表示一行结束

2.4.2     圆括号

() 表示在新的子shell中执行括号内的命令（这样可以不改变当前shell的状态。）

但是圆括号在单/双引号内失去作用，只作为普通字符。

2.4.3     花括号

2.4.3.1    分割命令的用法

与圆括号相似，但是：1. 花括号内的命令在当前shell中执行；2.花括号必须作为命令的第一个字符出现。

2.4.3.2    引用变量的用法

在$后面，表示变量名的开始和结束

 

2.4.4     方括号

相当与test命令，用来执行测试条件，通常用在需要判断条件的语句后面，例如：if,while等等。

 

 

3           设置变量

3.1          格式：VARNAME=value （i.e. PARAM=’hello’）

3.2          注意：

3.2.1     等号的前后不能有空格

3.2.2     如果变量的值是一个命令的执行结果，请加上反引号（`）。

 

4           引用变量

4.1          $VARNAME

4.1.1     e.i.  echo $HOME   （结果：/home/xiongguoan）

4.2          变量默认值

4.2.1     在引用一个变量的时候可以设定默认值。如果在此之前，该变量已经设定了值，则此默认值无效。如果此时变量没有被设定值，则使用此默认值（但是没有改变此变量的值）。

4.2.2     echo Hello ${UNAME:-there}     #其中there是UNAME的默认值

4.2.3     其他关于默认值与判读变量的方法：

 

利用大括号表示变量替换

表示形式

说明

${VARIABLE}

基本变量替换。大括号限定变量名的开始和结束

${VARIABLE:-DEFAULT}

如果VARIABLE没有值，则这种表示形式返回DEFAULT的值

${VARIABLE:=DEFAULT}

如果VARIABLE没有值，则这种表达形式返回DEFAULT的值。另外，如果VARIABLE没有设置，则把DEFAULT的值赋予它

${VARIABLE:+VALUE}

如果VARIABLE被设置，则这种表示形式返回VALUE；否则，返回一个空串

${# VARIABLE}

这种表示形式返回VARIABLE值的长度，除非VARIABLE是* 或者@在为*或者@的特殊情况下，则返回$@所表示的元素的个数。要记住，$ @保存传给该脚本的参数清单

${VARIABLE:?MESSAGE}

如果VARIABLE没有值，则这种表示形式返回MESSAGE的值。Shell也显示出VARIABLE的名字，所以这种形式对捕获得错误很有用

 

 

4.2.4     注意：

4.2.4.1    使用${VALIABLE:?MESSAGE},如果发现此变量此时没有值，则脚本停止运行并显示行号和变量名称。 主要用于调试。

4.2.4.2     

 

5           位置变量

5.1          使用$1,$2,$3…$9,${10},${11}…来代表输入的参数。其中$0代表被执行的命令或者脚本的名字。$1,$2…代表输入的第1,2…个参数

5.2          例子：

# cat count.sh#!/bin/sh

A=$1             # 将位置$1的数值读入，并赋给变量A

B=$2             # 将位置$2的数值读入，并赋给变量B

C=$[$A+$B]       # 将变量A与B的值相加，将结果赋给C

echo $C          # 显示C的数值

 

结果：

# ./count.sh  3  6

9

# ./count.sh 34  28

62

5.3          $@和$*代表参数的列表，$#代表参数的数量 （不知道$@和$*之间的差别）

 

 

6           运算符和优先级

 

Shell运算符和它们的优先级顺序

级别

运算符

说明

13

-, +

单目负、单目正

12

!, ~

逻辑非、按位取反或补码

11

* , / , %

乘、除、取模

10

+, -

加、减

9

<< , >>

按位左移、按位右移

8

< =, > =,  < , >

小于或等于、大于或等于、小于、大于

7

= = , ! =

等于、不等于

6

&

按位与

5

^

按位异或

4

 |

按位或

3

&&

逻辑与

2

| |

逻辑或

1

=, + =, - =, * =, /=, % =, & =, ^ =, | =, << =, >> =

赋值、运算且赋值

 

 

 

7           source / export / let / unset

7.1          source

7.1.1     正常情况下，脚本中执行的参数设置只能影响到shell脚本本身的执行环境，不能影响到调用此shell的脚本。

7.1.2     使用source命令执行脚本，可以让脚本影响到父shell的环境（即调用此shell的当前shell）。

7.1.3     例如：source env.sh

7.2          export

7.2.1     在bash下，使用export建立环境变量后，会影响到子shell脚本和当前shell的环境变量

7.3          unset

7.3.1     删除环境变量

7.3.2     i.e.

#export newval=1

#echo $newval

1

#unset newval

#echo $newval

    (ß此处为空行,newval已经被删除)

7.4          let

7.4.1     在bash中只用此命令可以建立一个临时的变量，此变量不会影响到子shell

 

8            逻辑判断

8.1          if

8.1.1     单格式与嵌套

 

if 条件表达式  
then #当条件为真时执行以下语句  
命令列表  
else #为假时执行以下语句  
命令列表  
fi

 

if　语句也可以嵌套使用  

if 条件表达式1  
then  
if 条件表达式2  
then  
命令列表  
else  
if 条件表达式3  
then  
命令列表  
else  
命令列表  
fi  
fi  
else  
命令列表  
fi 

 

8.1.2     多分支格式

 

if test -f "$1"  
then  
lpr $1  
elif test -d "$1" #elif　同else if  
then  
(cd $1;lpr $1)  
else  
echo "$1不是文件或目录"  
fi

 

8.2          case

8.2.1     格式

case $newval in

1)          #这里是可能值1

echo 1

;;      #表示第一个分支结束

2)           #这里是可能值 2

echo 2

;;      #第二个分支结束

*)      #表示其他可能值，必须在最后，否则他后面的语句无法执行

echo unkown

esac    #case 语句结束

8.2.2      

8.3          while /until

8.3.1     格式

while 表达式

do

命令列表

done

 

8.3.2     例如：

Sum=0  
i=0  
while true #true是系统的关键词 表示真  
do  
i=`expr $i + 1`  
Sum=`expr $Sum + $i`  
if [ $i = "100" ]  
then  
break;  
fi  
done  
echo $i $Sum  
最后这个程序显示的是 100 5050 

 

下面将这个程序再改动一下  


Sum=0  
i=0  
while [ $i != "100" ]  
do  
i=`expr $i + 1`  
Sum=`expr $Sum + $i`  
done  
echo $i $Sum  

改动后的程序运算结果和上面是一样 但程序比上面的要简练  

在这个循环中还可以以until做为测试条件 它正好与while测试的条件相反,也就是当条件为假时将继续执行循环体内的语句,否则就退出循环体,下面还用这个例子.  


Sum=0  
i=0  
until [ $i = "100" ]  
do  
i=`expr $i + 1`  
Sum=`expr $Sum + $i`  
done  
echo $i $Sum  
当i不等于100时循环 就是当条件为假时循环,否则就退出,而第一个例子是当i不等于100  
时循环,也就是测试条件为真时循环. 

 

8.4          for

8.4.1     枚举用法

8.4.1.1    格式

 

 

for 变量 in 名字列表  
do  
命令列表  
done 

 

8.4.1.2    格式

for n in {1..10}

do

echo $n

done

 

for letter in a b c d e;

do

echo $letter

done

 

 

8.4.2     文件用法

 

8.4.2.1    格式

for file in *

do

       echo $file

done

 

8.4.2.2    例子

 

for File in a1 a2 a3 a4 a5  
do  
diff aa/$File bb/$File  
done 

 

 

8.4.3     累加格式

for (( i=1;$i<10;i++))

do

echo $i

done

 

for(( i=1;$i<10;i=$[$i+1’ ])

do

echo $i

done

8.4.4      

8.5          其他循环控制语句

break 命令不执行当前循环体内break下面的语句从当前循环退出.  
continue 命令是程序在本循体内忽略下面的语句,从循环头开始执行.

 

8.6          逻辑判断的表达

 

一、判断文件的属性  

格式：-操作符 filename  
-e 文件存在返回1， 否则返回0  
-r 文件可读返回1,否则返回0  
-w 文件可写返回1,否则返回0  
-x 文件可执行返回1,否则返回0  
-o 文件属于用户本人返回1, 否则返回0  
-z 文件长度为0返回1, 否则返回0.  
-f 文件为普通文件返回1, 否则返回0  
-d 文件为目录文件时返回1, 否则返回0  

二、测试字符串  
字符串1 = 字符串2　当两个字串相等时为真  
字符串1 != 字符串2 当两个字串不等时为真  
-n 字符串　 　　　 当字符串的长度大于0时为真  
-z 字符串　　　　　 当字符串的长度为0时为真  
字符串　　　　　　 当串字符串为非空时为真  

三、测试两个整数关系  
数字1 -eq 数字2　　　　 两数相等为真  
数字1 -ne 数字2　　　　 两数不等为真  
数字1 -gt 数字2　　　　 数字1大于数字2为真  
数字1 -ge 数字2 　　　 数字1大于等于数字2为真  
数字1 -lt 数字2　　　　 数字1小于数字2为真  
数字1 -le 数字2　　　　 数字1小于等于数字2为真  

四、逻辑测试  
-a 　 　　　　　 与  
-o　　　　　　　 或  
!　　　　　　　　非 

 

9           shell中的表达式

9.1          shell 输出重定向

9.1.1     管道  |

就管道符前的命令的输出作为管道符后的命令的输入。

 

ls | grep ‘.txt’

将ls的输出作为grep 的输入。 grep从输入中找出所有包含.txt的行。

 

9.1.2     输出  >

将右尖括号前的命令的输入重定向到尖括号后的文件中。

 

例如：

ls *.sh > list.txt

将当前目录下所有末尾名为sh的文件的列表写入到list.txt

 

9.1.3     输入 <

将左箭头后面的文件作为左箭头前的命令的输入。

例如：

grep “a” < test.sh

将test.sh中找到所有包含a的行

 

9.1.4     错误输出重定向

默认bash有3个标准输入输出设备。

0 标准输入

1 标准输出

2错误输出

 

如果执行脚本的时候发生错误，会输出到2上。

要想就将错误的输出也输出在标准输出上，需要重定向。

例如：

./test.sh > a.log 2>&1

后面2>&1就是将标准错误的输出重定向到标准输出上。

 

9.2          tee

9.2.1     将此命令的输入分叉，一支输出到屏幕一支可以重定向到其他位置。

例如： ./test.sh | tee >a.txt 2>&1

运行test.sh，通过tee输出到a.txt，同时屏幕上可以看到输出。并且将错误输出重定向到标准输出( 2>&1 )

9.3          cpio

9.3.1     文件或目录打包

9.3.1.1    含子目录打包

　　find . -name '*.sh' | cpio -o > shell.cpio

　　将当前目录及其子目录下的sh文件打包成一个文件库为shell.cpio。　

9.3.1.2    不含子目录的打包

ls *.sh | cpio -o > shell.cpio

　　将当前目录下的sh文件(不含子目录)打包成一个文件库为shell.cpio。　

9.3.2     　压缩

文件打包完成后,即可用Unix中的compress命令（/usr/bin下）压缩打包文件。对一般的文本文件,压缩率较高,可达81％。

例如：compress shell.cpio则将文件库压缩为shell.cpio.Z（自动添加.Z并删除shell.cpio ）。　

9.3.3     　解压

uncompress shell.cpio.Z则自动还原为shell.cpio。　

9.3.4     　解包展开

将按原目录结构解包展开到当前所在目录下。若以相对路径打包的,当解包展开时,也是以相对路径存放展开的文件数据;若以绝对路径打包的,当解包展开时,也是以绝对路径存放展开的文件数据。因此注意若为相对路径,应先进入相应的目录下再展开。　

 

　cd /u1

　cpio –id < shell.cpio 解压到当期目录。　

　cpio –iud < shell.cpio则文件若存在将被覆盖,即强制覆盖。　

　cpio –id < shell.cpio env.sh 解压缩env.sh

9.3.5     　显示包内的文件

　　cpio –it < shell.cpio 　

 

9.4          exec

9.4.1     将此命令后的参数作为命令在当前的shell中执行，当前的shell或者脚本不在执行。

例如： exec ls

当前进程替换为ls,执行结束后就退出了。

例如：在a.sh 中包含

exec b.sh 则当a.sh 执行到此句后，被b.sh替换，a.sh中此句后的语句不会再被执行。

 

9.5          fork

9.5.1     将此命令的参数，新建一个进程来执行

 

例如：在a.sh 中包含

fork b.sh 则当a.sh 执行到此句后，被b.sh替换，a.sh中此句后的语句继续执行。b.sh在新的进程中同时执行。

 

9.6          expr

9.6.1     expr argument operator argument

9.6.2     一般用于整数的运算。 例如：

#set newval=1

#echo $newval

1

#set newval=`expr $newval + 1`

#echo $newval

2

#set newval=$newval+1

#echo $newval

2+1

 

9.7          test

9.7.1     测试，通常用在需要判断的语句后面，例如：if,while,等等。

9.7.2     很多时候可以和中括号[]互换，我不知道区别是什么。

9.7.3     例子：

i=1

if test”$ i” == “1”

then

echo true

else

echo false

fi

 

9.8          exit

退出当前的shell，执行结果可以在shell中用$?查看

例如：exit 2

9.9          read

从标准输入读取数据。

例： 
$ read var1 var2 var3 
Hello my friends 
$ echo $var1 $var2 $var3 
Hello my friends 
$ echo $var1 
Hello

 

9.10       shift

9.10.1 每次调用的时候，将参数列表中的第一个参数去掉。这样可以循环得到第一个参数。

9.10.2 例子

#cat t.sh

sum=0

until [ $# -eq 0 ]

do

echo $*

sum=`expr $sum + $1`

shift

done

echo result is: $sum

 

#./t.sh 1 2 3

1 2 3

2 3

3

 

 

10       附件一：例子脚本

10.1        脚本1

 

10.2        

11       附件二：Linux 易被遗漏的命令解析

11.1       grep

11.1.1 grep ‘string’ filename

11.1.1.1e.i.: grep ‘list’ mytxt.txt 在mytxt.txt中寻找包含list字符串的所有行

11.1.2 “-v” : 相反的。 即不包含字符串。

11.1.2.1e.i.: grep –v ‘list’ mytxt.txt

11.1.3 cat mytxt | grep ‘list’

将cat mytxt作为源， 从中查找包含list字符串的行

11.2       find

11.2.1 -atime n ： 指查找系统中最后n*24小时访问的文件；

11.2.2 -ctime n ： 指查找系统中最后n*24小时被改变状态的文件；

11.2.3 -mtime n ： 指查找系统中最后n*24小时被修改的文件。

11.2.4 在当前目录下(包含子目录)，查找所有txt文件并找出含有字符串"bin"的行
find ./ -name "*.txt" -exec grep "bin" {} \;

11.2.5 在当前目录下(包含子目录)，删除所有txt文件
find ./ -name "*.txt" -exec rm {} \;

 

11.3       du

11.3.1 显示文件的大小

11.3.2 i.e.

#du *.txt

1230   myfile1.txt

456    myfile2.txt

 

11.4       awk

11.4.1 提取输入中的某个参数

11.4.2 i.e. 提取输入中每一行的第一个参数

#echo `du *.txt | awk ‘{print $1}’`

1230 456

提取子字符串

#echo `du *.bin | awk '{print substr($1,2,3)}'`

 

11.5       前后台运行

11.5.1 将某个程序在后台启动起来，只需要在命令的最后加上 & 符号。

例如： ./test.sh &

 

11.5.2 将当前正在运行的程序切换到后台

11.5.2.1当按下^z的时候，当前的应用程序就会切换到后台，但是此时的状态是停止的状态。

11.5.2.2使用jobs命令可以看到当前在后台运行的程序的列表。

例如：jobs

[1]+ stopped top

[2]+stopped find | grep *.txt > a.log

 

11.5.2.3使用bg命令可以将某个后台程序继续运行。

#bg %2

#jobs

[1]+ stopped top

[2]+ Running find | grep *.txt > a.log

 

11.5.3 将后台运行的程序切回到前台

#fg %2

将find 命令切回到前台

11.6       shell的执行选项

 

-n 测试shell script语法结构，只读取shell script但不执行 
-x 进入跟踪方式，显示所执行的每一条命令，用于调度 
-a Tag all variables for export 
-c "string" 从strings中读取命令 
-e 非交互方式 
-f 关闭shell文件名产生功能 
-h locate and remember functions as defind 
-i 交互方式 
-k 从环境变量中读取命令的参数 
-r 限制方式 
-s 从标准输入读取命令 
-t 执行命令后退出(shell exits) 
-u 在替换中如使用未定义变量为错误 
-v verbose,显示shell输入行

 

11.7       alias

建立别名

alias dir ls

11.8        xargs

执行本命令的第一个参数，并将xargs的输入作为被执行命令的参数

例如：

find . -name '*.c' | xargs cat

将本目录及其子目录下所有的C文件使用cat命令显示其内容。

 

12       附件三：Bash中影响环境变量的命令

 

Shell有若干以变量为工作对象的命令，其中有些命令似乎重复了。例如，可以用declare、export和typeset命令来创建全局（或转出）的变量。typeset命令是declare的同义词。

 

Declare 命令

 

语法：

declare [options] [name [= value]]

 

摘要：

用于显示或设置变量。

declare命令使用四个选项：

-f   只显示函数名

-r   创建只读变量。只读变量不能被赋予新值或取消设置，除非使用declare或者typeset命令

-x   创建转出（exported）变量

-i   创建整数变量。如果我们想给一个整数变量赋予文本值，实际上是赋予0使用+ 代替-，可以颠倒选项的含义。

 

如果没有使用参数，则declare显示当前已定义变量和函数的列表。让我们关注一下-r选项：

 

$ declare  –r  title=" paradise Lost"

$ title = " Xenogenesis"

bash: title: read-only variable

$ declare title= " Xenogenesis"

$ echo $title

Xecogenesis

$ typeset title = " The Longing Ring”

$ echo $title

The Longing Ring

 

这个示例表明，只有declare或typeset命令可以修改只读变量的值。

 

 

 

export命令

 

语法：

 export [options] [name [= value]]

摘要：

用于创建传给子Shell的变量。

export命令使用四个选项：

--   表明选项结束。所有后续参数都是实参

-f   表明在“名-值”对中的名字是函数名

-n   把全局变量转换成局部变量。换句话说，命名的变量不再传给子Shell

-p   显示全局变量列表

 

如果没有用参数，则假定是一个-p参数，并且显示出全局变量的列表：

 

$ export

declare –x ENV = "/home/medined/ . bashrc"

declare –x HISTFILESIZE = "1000"

…

declare –xi numPages = "314"

declare –xr title = "The Longing Ring"

declare –xri numChapters = "32"

 

这种显示的一个有趣的特性是，它告诉我们哪些变量只能是整数、是只读的，或者二者皆可。

 

let命令

 

语法：

let expression

摘要：

用于求整数表达式的值。

 

let命令计算整数表达式的值。它通常用来增加计数器变量的值，如例5-9所示。

 

例5-9 let——使用let命令

# ! /bin/bash

count=1

for element in $@

do

   echo " $element is element $count"

   let count+=1

done

 

下面是这个脚本运行结果示例：

$ chmod + x let

$ . /let one two three

one is element 1

two is element 2

three is element 3

 

注意：如果我们习惯在表达式中使用空格，那么要用双引号把表达式括起来，如：

let "count + =1"

否则会导致语句错误。

 

local 命令

 

语法：

       local [name [= value]]

摘要：

       用于创建不能传给子Shell的变量。这个命令仅在过程内部有效。

 

简单说来，local命令创建的变量不能被子Shell存取。因此，只能在函数内部使用local命令。我们可以在命令行或脚本中使用“变量=值”这种形式的赋值命令。如果使用local时不带实参，那么当前已定义的局部变量列表就送往标准输出显示。

 

readonly命令

 

语法：

       readonly [options] [name[ = value]]

摘要：

用于显示或者设置只读变量。

Readonly命令使用两个选项：

--    表明选项结束。所有后续参数都是实参

-f    创建只读函数

 

如果没有用参数，则readonly显示当前已定义的只读变量和函数的列表。

 

set命令

 

语法：

       set [--abefhkmnptuvxidCHP] [-o option] [name [= value]]

摘要：

用于设置或者重置各种Shell选项。

 

set 命令可实现很多不同的功能——并非其中所有的功能都与变量有关。由于本节的其他命令重复了通过set命令可用的那些变量选项，所以这里对set命令不做详细说明。

 

shift命令

 

语法

shift [n]

摘要：

用于移动位置变量。

 

shift命令调整位置变量，使$3的值赋予$2，而$2的值赋予$1。当执行shift命令时，这种波动作用影响到所定义的各个位置变量。往往使用shift命令来检查过程参数的特定值——如为选项设置标志变量时。

 

typeset命令

 

语法：

typeset [options] [name [= value]]

摘要：

用于显示或者设置变量。

 

typeset 命令是declare命令的同义词。

 

 

unset命令

 

语法：

unset [options] name [name …]

摘要：

用于取消变量定义。

unset命令使用两个选项：

--  表明选项结束，所有后续参数都是实参

-f  创建只读函数

 

unset命令从Shell环境中删除指定的变量和函数。注意，不能取消对PATH、IFS、PPID、PS1、PS2、UID和EUID的设置。如果我们取消RANDOM、SECONDS、LINENO或HISTCMD等变量的设置，它们就失去特有属性。