[原文链接](http://www.bubuko.com/infodetail-2138939.html)

[TOC]

# 1. 认识 `YAML`
　　`YAML`是一个类似 `XML`、`JSON` 的标记性语言。`YAML` 强调以数据为中心，并不是以标识语言为重点。因而 `YAML` 本身的定义比较简单，号称“一种人性化的数据格式语言”。

## 1.1 `YAML` 的设计目标：

- 人类容易阅读

- 可用于不同程序间的数据交换

- 适合描述程序所使用的数据结构，特别是脚本语言

- 丰富的表达能力与可扩展性

- 易于使用

## 1.2 `YAML` 与 `XML`、`JSON`

- `YAML` 与 `XML`

具有 `XML` 同样的优点，但比 `XML` 更加简单、敏捷等

- `YAML` 与 `JSON`

`JSON` 可以看作是 `YAML` 的子集，也就是说 `JSON` 能够做的事情，`YAML` 也能够做

`YAML` 能表示得比 `JSON` 更加简单和阅读，例如“字符串不需要引号”。所以 `YAML` 容易可以写成 `JSON` 的格式，但并不建议这种做

`YAML` 能够描述比 `JSON` 更加复杂的结构，例如“关系锚点”可以表示数据引用（如重复数据的引用）。

## 1.3 YAML 组织结构

　　`YAML` 文件可以由一或多个文档组成（也即相对独立的组织结构组成），文档间使用`---`（三个横线）在每文档开始作为分隔符。同时，文档也可以使用`...`（三个点号）作为结束符（可选）。如下图所示：

![Image](https://static.oschina.net/uploads/img/201508/23213149_GNnv.png)


如果只是单个文档，分隔符`---`可省略。

每个文档并不需要使用结束符`...`来表示结束，但是对于网络传输或者流来说，作为明确结束的符号，有利于软件处理。（例如不需要知道流关闭就能知道文档结束）

　　`YAML` 认为数据由以下三种结构组成：（每个文档由三种结构混合组成）

- 标量 （相当于数据类型）

- 序列 （相当于数组和列表）

- 键值表（相当于 `Map` 表）

# 2. YAML 编写规范

- 规范一：文档使用 `Unicode` 编码作为字符标准编码，例如 `UTF-8`

- 规范二：使用`#`来表示注释内容

```
# 客户订单
date: 2015-02-01
customer:
  - name: Jai
items:
  - no: 1234         # 订单号
  - descript: cpu
```

- 规范三：使用空格作为嵌套缩进工具。通常建议使用两个空格缩进，不建议使用 `tab` （甚至不支持）

- 规范四：序列表示

使用`-`（横线） + 单个空格表示单个列表项

```
--- # 文档开始
- 第一章 简介
- 第二章 设计目录
```

使用`[]`表示一组数据

```
--- # 文档开始
[blue, red, green]
```

组合表示。每个结构都可以嵌套组成复杂的表示结构。

```
--- # 文档开始
- [blue, red, green]     # 列表项本身也是一个列表
- [Age, Bag]
- site: {osc:www.oschina.net, baidu: www.baidu.com}  # 这里是同 键值表 组合表示
```

- 规范五：键值表

使用 `:`（冒号） + 空格表示单个键值对

```
# 客户订单
date: 2015-02-01
customer:
  - name: Jai
items:
  - no: 1234         # 订单号
  - descript: cpu
  - price: ￥800.00
```

使用`{}`表示一个键值表

```
# 客户订单
date: 2015-02-01
customer:
  - name: Jai
items: {no: 1234, descript: cpu, price: ￥800.00}
```

`?` 问号+空格表示复杂的键。当键是一个列表或键值表时，就需要使用本符号来标记。

```
 # 使用一个列表作为键
 ? [blue, reg, green]: Color
 # 等价于
 ? - blue
   - reg
   - gree
 : Color
```

组合表示。每个结构都可以嵌套组成复杂的表示结构。 

```
 Color:
    - blue
    - red
    - green

 # 相当于 (也是 JSON 的表示)
 {Color: [blue, red, green]}

 div:
    - border: {color: red, width: 2px}
    - background: {color: green}
    - padding: [0, 10px, 0, 10px]

 # 使用缩进表示的键值表与列表项
 items:
    - item: cpu
      model: i3
      price: ￥800.00
    - item: HD
      model: WD
      price: ￥450.00

 # 上面使用 “-” 前导与缩进来表示多个列表项，相当于下面的JSON表示
 items: [{item:cpu, model:i3, price:￥800.00}, {item:HD, model:WD, price: ￥450.00}]
```

+ 规范六：文本块

    - 使用 `|` 和文本内容缩进表示的块：保留块中已有的回车换行。相当于段落块
```
yaml: |      # 注意 ":" 与 "|" 之间的空格
   JSON的语法其实是YAML的子集，大部分的JSON文件都可以被YAML的解释器解释。
   如果你想更深入的学习YAML，我建议你去 http://www.yaml.org 看看
```

   - 使用 `>` 和文本内容缩进表示的块：将块中回车替换为空格，最终连接成一行。

```
yaml: >      # 注意 ":" 与 ">" 之间的空格，另外可以使用空行来分段落
   JSON的语法其实是YAML的子集，
   大部分的JSON文件都可以被YAML的解释器解释。

   如果你想更深入的学习YAML，我建议你去 http://www.yaml.org 看看
```

使用定界符`“”`（双引号）、`‘’`（单引号）或回车表示的块：最终表示成一行。

```
yaml:     # 使用回车的多行，最终连接成一行。
   JSON的语法其实是YAML的子集，
   大部分的JSON文件都可以被YAML的解释器解释。

yaml:     # 使用了双引号，双引号的好处是可以转义，即在里面可以使用特殊符号
   "JSON的语法其实是YAML的子集，
   大部分的JSON文件都可以被YAML的解释器解释。"
```

+ 规范七：数据类型的约定

    - 对一些常用数据类型的表示格式进行了约定，包括:

```
 integer: 12345     # 整数标准形式
 octal: 0o34        # 八进制表示，第二个是字母 o
 hex: 0xFF          # 十六进制表示

 float: 1.23e+3     # 浮点数
 fixed: 13.67       # 固定小数
 minmin: -.inf      # 表示负无穷
 notNumber: .NaN    # 无效数字

 null:              # 空值
 boolean: [true, false] # 布尔值
 string: ‘12345‘    # 字符串

 date: 2015-08-23   # 日期
 datetime: 2015-08-23T02:02:00.1z  # 日期时间
 iso8601: 2015-08-23t21:59:43.10-05:00  # iso8601 日期格式
 spaced: 2015-08-23 21:59:43.10 -5      # ?
```

   - `!`（叹号）显式指示类型，或自定义类型标识。单叹号通常是自定义类型，双叹号是内置类型

```
 isString: !!str 2015-08-23     # 强调是字符串不是日期数据
 picture: !!binary |            # Base64  图片
     R0lGODlhDAAMAIQAAP//9/X
     17unp5WZmZgAAAOfn515eXv
     Pz7Y6OjuDg4J+fn5OTk6enp
     56enmleECcgggoBADs=
 #下面是内置类型
 !!int               # 整数类型
 !!float             # 浮点类型
 !!bool              # 布尔类型
 !!str               # 字符串类型
 !!binary            # 也是字符串类型
 !!timestamp         # 日期时间类型
 !!null              # 空值
 !!set               # 集合
 !!omap, !!pairs     # 键值列表或对象列表
 !!seq               # 序列，也是列表
 !!map               # 键值表

 #下面是一些例子：
 --- !!omap
 - Mark: 65
 - Sammy: 63
 - Key: 58

 --- !!set           # 注意，“?”表示键为列表，在这里列表为 null
 ? Mark
 ? Sammy
 ? Key

 # 下面是自定义的类型或标识
 %TAG ! tag:clarkevans.com,2002:   # % 是指令符号
 --- !shape
 # Use the ! handle for presenting
 # tag:clarkevans.com,2002:circle
 - !circle
   center: &ORIGIN {x: 73, y: 129}
   radius: 7
 - !line
   start: *ORIGIN
   finish: { x: 89, y: 102 }
 - !label
   start: *ORIGIN
   color: 0xFFEEBB
   text: Pretty vector drawing.
```

+ 规范八：锚点与引用，定义数据的复用。

    - 第一步：使用 `&` 定义数据锚点（即要复制的数据）
    - 第二步：使用 `*` 引用上述锚点数据（即数据的复制目的地）

```
 ---
 hr:
   - Mark McGwire
   # Following node labeled SS
   - &SS Sammy Sosa            # 定义要复制的数据
 rbi:
   - *SS # Subsequent occurrence   这里是数据复制目标
   - Ken Griffey
```