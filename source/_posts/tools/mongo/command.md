# mongo 语句

[MongoDB 去重(distinct)查询后求总数(count)](https://blog.csdn.net/user_longling/article/details/80864511)


mongo命令查询可以通过`aggreate` 来实现数据聚合 在 `aggregate中的[]`中，每个`{}`都是对之前查询到的数据的处理
- 第1个`{$match:{status:2}}` 匹配`status=2`的文档， `update_date:{"$gt":ISODate("2021-08-11 16:00:00")}` 查询在2021-08-12号之后有做更新的报价(存储的时间是标准时区)
- 第2个`{"$project" : {"cnt":{"$size":"$avail_dates"}, hotel_code:1}}` 将数组`avail_dates`的长度存入字段`cnt`, 并查询`hotel_code`字段, 如果需要其他字段，可以继续添加
- 第3个`{"$match":{cnt:{"$gt":0}}}` 过滤掉avail_dates为空的报价
- 第4个`{$group : {_id : "$hotel_code", count:{$sum:1}}}`, 以`hotel_code`聚合相当于`group by hotel_code`，查询每个hotel_code的报价数量
- 第5个`{$group:{_id:null,count:{$sum:1}}}` 是在之前一步的基础上再次聚合，即查询有报价酒店的数量，最后返回的是1个数值(有价酒店的数量)， 如果改成`{$group:{_id:null,count:{$sum:"$count"}}}` 则查询的是所有价格的报价的数量
```
# 直接查询出某供应商的有价酒店数量，已去除status!=2，更新时间不满足，avail_dates.len=0的报价 
db.getCollection('spl_rate_44').aggregate([
    {$match:{status:2, update_date:{"$gt":ISODate("2021-08-11 16:00:00")}}},
    {"$project" : {"cnt":{"$size":"$avail_dates"}, hotel_code:1}},
    {"$match":{cnt:{"$gt":0}}},
    {$group : {_id : "$hotel_code", count:{$sum:1}}},
    {$group:{_id:null,count:{$sum:1}}}
     ])
```