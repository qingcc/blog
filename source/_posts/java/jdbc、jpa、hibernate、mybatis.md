# jdbc、jpa、spring data jpa、hibernate、mybatis 相关概念
[jdbc,jpa,spring data jpa,hibernate,mybatis区别](https://blog.csdn.net/u014209205/article/details/79885648)

## 基础概念
`jdbc`(`Java DataBase Connectivity`)是`java`连接数据库操作的原生接口。`JDBC` 对 `Java` 程序员而言是`API`，对实现与数据库连接的服务提供商而言是接口模型。
作为`API`，`JDBC`为程序开发提供标准的接口，并为各个数据库厂商及第三方中间件厂商实现与数据库的连接提供了标准方法。
一句话概括：`jdbc` 是所有框架操作数据库的必须要用的，由数据库厂商提供，但是为了方便`java`程序员调用各个数据库，各个数据库厂商都要实现`jdbc`接口。

`jpa`(`Java Persistence API`)是 `java` 持久化规范，是 `orm` 框架的标准，主流 `orm` 框架都实现了这个标准。
`ORM`是一种思想，是插入在应用程序与`JDBC API`之间的一个中间层， `JDBC` 并不能很好地支持面向对象的程序设计，
`ORM` 解决了这个问题，通过 `JDBC` 将字段高效的与对象进行映射。具体实现有 `hibernate`、`spring data jpa`、`open jpa`。

`spring data jpa` 是对 `jpa` 规范的再次抽象，底层还是用的实现 `jpa` 的 `hibernate` 技术。

`hibernate` 是一个标准的 `orm` 框架，实现 `jpa` 接口。

`mybatis` 也是一个持久化框架，但不完全是一个 `orm` 框架，不是依照的 `jpa` 规范。

`jdbc`示意图:  
![Image](https://img-blog.csdnimg.cn/20191226221302985.png)

`jpa`示意图:  
![Image](https://img-blog.csdnimg.cn/20191226221302985.png)
### 什么是`orm`?
`orm`(`Object Relation Mapping`) 对象关系映射，是对象持久化的核心，是对 `jdbc` 的封装。

## `jdbc` 和 `jpa` 的区别
本质上，这两个东西不是一个层次的，`jdbc` 是数据库的统一接口标准，`jpa` 是 `orm` 框架的统一接口标准。用法有区别，
`jdbc` 更注重数据库，`orm` 则更注重于 `java` 代码，但是实际上 `jpa` 实现的框架底层还是用 `jdbc` 去和数据库打交道。


### `hibernate` VS `mybatis` VS `jdbc`
`jdbc` 是比较底层的数据库操作方式，`hibernate` 和 `mybatis` 都是在 `jdbc` 的基础上进行了封装。

`hibernate` 是将数据库中的数据表映射为持久层的 `java` 对象，实现对数据表的完整性控制。`hibernate` 的主要思想是面向对象，标准的 `orm`。
不建议自己写 `sql` 语句，如果确实有必要推荐 `hql` 代替。`hibernate` 是全表映射，只需提供 `java bean` 和数据库表映射关系，

`mybatis` 是将`sql` 语句中的输入参数 `parameterMap` 和输出结果 `resultMap` 映射为 `java` 对象，放弃了对数据表的完整性控制，获得了更大的灵活性。
`mybatis` 拥抱 `sql` ,在 `sql` 语句方面有更大的灵活性，`mybatis` 不是面向对象，不是标准的 `orm` ,更像是 `sql mapping` 框架。
`mybatis` 是半自动的，需要提供 `java bean` , `sql` 语句和数据库表的映射关系。

## 开发难度：

`Hibernate` 因为是封装了完整的对象关系映射，内部实现比较复杂，学习周期大。

`mybatis` 主要是配置文件中 `sql` 语句的编写

`spring data` 上手快，通过命名规范，注解查询可简化操作

## 总结
如果是进行底层编程，需要对性能要求高，应采用 `jdbc` 方式。

如果直接操作数据库表，没有过多的定制，建议使用 `hibernate` 方式。

如果要灵活使用 `sql` 语句，建议采用 `mybatis` 方式。