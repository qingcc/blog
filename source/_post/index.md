---
title: index
date: 2019-12-25 19:12:57
tags: [golang, about]
---
#对接供应商
每个供应商需要实现SplHotelServiceStage接口（包含6个方法）以及1个获取酒店静态数据的接口
- GetInventoryRate(invRateReq InvRateRequest) SplServiceResult
- CheckRoomAvail(roomAvailReq RoomAvailRequest) SplServiceResult
- CreateOrder(orderRequest OrderRequest) SplServiceResult
- CancelOrder(rq SplCancelOrderRequest) SplServiceResult
- CheckCancelOrder(order SplCancelOrderRequest) SplServiceResult （暂不使用）
- QueryOrder(orderQuery OrderQuery) SplServiceResult
<!--more-->
- 文件结构：spls/suppliers/xxxx 供应商名称
-       |-model 定义结构体（接口文档中请求参数结构体，返回数据结构体）
        |-service 服务
            |-parser 对供应商接口返回的数据进行处理填充到SplServiceResult
            |-xxxxService 实现SplHotelServiceStage接口的所有方法
        |-staticData 获取该供应商的酒店静态数据
        |-tools   
            |-test 测试接口
            |-sendUtil 请求供应商接口的公共方法

开发之前（进行中）需要预先确定的：
- 添加好配置（核心包等）前后端添加新供应商
- 建好表（spl_rate_00 , spl_roomtype_00 , spl_rateplan_00 , spl_roomtype_mapping_00）
- 服务器ip是否添加白名单（如果需要）
- 确认好货币单位（是CNY还是其他，元还是分）

目的：传入指定的数据（结构体），获取规范的返回数据（结构体）。

供应商的所有接口的实现方式都一样：以取消订单接口为例
- 第一步：通过接口的传入数据（结构体）， 筛取所需数据填充到供应商接口需要的结构体中（NewRequest()）。
- 第二步：调用该供应商接口的公共方法（tools.SendDaieiData()）。
- 第三步：处理供应商接口返回的标准http返回（checkError()）。
- 第四步：对供应商接口返回的数据处理(parse.ParseCancelOrder())。

//取消单接口， 传入数据cancelOrderRq，返回数据result：

    func (s *DaieiService) CancelOrder(cancelOrderRq commobj.SplCancelOrderRequest) (result commobj.SplServiceResult) {
        req := cancelOrder.NewRequest(cancelOrderRq)//返回供应商接口的请求参数
        url := common.NewRequest(common.CANCEL_ORDER_URL, req)
        res := new(cancelOrder.CancelOrderResponse) //声明接口返回数据变量，传入该变量的指针到公共方法。
        httpMessageResult := tools.SendDaieiData(url, res, false)
        //日志，将请求和响应写入日志
        result.SplMessageLogs = append(result.SplMessageLogs, httpMessageResult)
        if success := checkError(httpMessageResult, res.CommonResponse, &result); !success {
            return
        }
        parser.ParseCancelOrder(*res, &result)
        if !result.IsSuccess {
            result.OrderDetail = domain.OrderDetail{SupplierOrderNum: cancelOrderRq.SupplierOrderNum}
        }
        return
    }

标准请求方法tools.SendDaieiData(url, res, false)，供应商的所有接口都通过该方法请求并将返回值填充到res变量。
- 第一个参数传入供应商接口请求结构体（该方法中是将请求参数拼接到url中传入，所以直接生成完整的url字符串并传入）
- 第二个参数传入供应商接口返回的结构体指针（传入的是指针，会在该方法中，将返回的数据填充到该指针）
- 第三个参数是否打印传入的请求和返回

处理供应商接口返回的数据parser.ParseCancelOrder(*res, &result)
传入供应商响应数据res，和规范的返回数据result的地址，会在该方法中根据res筛选数据填充到result中。

酒店静态数据：

    h := domain.Hotel{}
	h.SupplierId = domain.SPL_DAIEI_ID          //供应商id
	h.HotelCode = strconv.Itoa(hotel.HotelID)   //酒店code
	h.HotelName = hotel.HotelEN                 //酒店英文名
	h.HotelNameCN = hotel.HotelCN               //酒店中文名
	h.SplCountryCode = country.CountryCode      //供应商国家code 一般情况下填充SplCountryCode而不填充CountryCode(SplCountryCode为2位字母）
	h.CityCode = strconv.Itoa(city.CityID)      //城市code
	h.Longitude = strconv.FormatFloat(hotel.Longitude, 'f', -1, 64) //经度
	h.Latitude = strconv.FormatFloat(hotel.Latitude, 'f', -1, 64)   //纬度
	h.StarRating, _ = strconv.Atoi(hotel.StarLevel)    //星级
	h.Status = domain.ACTIVE                           //状态 默认 domain.ACTIVE

    h.SHotelId 不要赋值, 该字段是匹配酒店后填充的

抓取报价接口返回值处理：(参照common.md)
若静态数据中无房型数据，则需要填充房型HotelSearchItem.RoomTypeList domain.RoomTypeList，若有，则不填充

    commobj.SplServiceResult.HotelSearchItem{
        SessionContent  (非必填)
        RTRPRList  []RoomTypeRatePlanRate 报价数据
            RoomTypeRatePlanRate{
                Status              //状态
                StandardOccupancy
                Occupancy
                MaxOccupancy        //最大入住人数
                Currency {
                    Code
                }
                TotalPrice          //总价
                TotalNetRate        
                []Rates{                //单间夜价格库存
                    StayDate            //价格库存信息所属的日期
                    NetRate             //单间夜的价格, **_以分为单位_**
                    Status              //默认从供应商API返回的单天价格状态为domain
                    InvCount            //该日期剩余库存, 可以默认填4等，若为0，则status会被设置为3，现在只卖即时房型（可通过程序直接下单，不需要人工操作）
                }
                []CancellationPolicies{ //取消策略
                    AdvancedHour        //距离入住时间多少小时
                    ChargeType          //扣费类型 0(default): amount, 1: percentage, 2: nights, 3: first night, 4:扣全款
                    CurrencyCode        //扣费货币
                    ChargeAmount        //取消时扣除的费用
                }
                RoomTypeCode            //报价对应的房型代码（在该供应商下，必须唯一）
                RatePlanCode            //报价的标识代码
                SupplierId              //供应商id
                RateCode                //通常用于存储报价额外信息的标识码
                RatePlanName            //报价名称
                PriceModelType          //报价售卖模式
                MealType                //早餐类型（根据MealCount为不同的值）
                MealDesc                //早餐 的描述
                MealCount               //通过MealType字段计算得出
                HotelCode               //报价所属的供应商酒店代码
                
            }
    }
    
创建订单：

    commobj.SplServiceResult{
        IsSuccess   bool    //是否成功
        OrderDetail domain.OrderDetail{
            SupplierOrderNum            //供应商订单号, 用于查询或取消订单   
            OrderStatusSupplier         //供应商订单状态
            SupplierId                  //供应商id
            SupplierCurrency            //供应商订单货币三字码, 如USD, CNY等
            SupplierPrice               //供应商订单成本, **_以分为单位_** （必填项，若不填，则下单记录中没有成本价字段）
        }
        Orders      []domain.OrderDetail           //把上面的OrderDetail追加到Orders
    }    

查询订单：

    commobj.SplServiceResult{
        IsSuccess   bool    //是否成功
        OrderDetail domain.OrderDetail{
            SupplierOrderNum            //供应商订单号, 用于查询或取消订单   
            OrderStatusSupplier         //供应商订单状态
            SupplierId                  //供应商id
            SupplierCurrency            //供应商订单货币三字码, 如USD, CNY等
            SupplierPrice               //供应商订单成本, **_以分为单位_**
            SplHotelCode                //酒店id
            CityName                    //城市名称
            HotelName                   //酒店名称
            CheckIn                     //入住时间
            CheckOut                    //离店时间
            RoomCount                   //预定房间数
        }
        Orders      []domain.OrderDetail           //把上面的OrderDetail追加到Orders
    }    

取消订单：

     commobj.SplServiceResult{
        IsSuccess   bool    //是否成功
        OrderDetail domain.OrderDetail{
            SupplierOrderNum            //供应商订单号, 用于查询或取消订单   
            OrderStatusSupplier         //供应商订单状态
        }
        Orders      []domain.OrderDetail           //把上面的OrderDetail追加到Orders
    }    

#需要注意的地方
- 抓取静态数据的时候，h.SHotelId 不要赋值, 该字段是匹配酒店后自动填充的
- 如果抓取报价接口关于房型的RoomTypeCode有使用func (rt *RoomType) Init()方法，需要存入的是调用该方法之后的roomType.RoomTypeCode,该方法是接受参数生成RoomTypeCode并填充到该结构体
- 测试前需要将服务器ip添加到供应商白名单，否则所有接口都不能正常访问
- 表是否都建好了（spl_rate_00 , spl_roomtype_00 , spl_rateplan_00 , spl_roomtype_mapping_00）
- 供应商是否添加（前端和后端，前端代码中需要添加，后端数据表中需要添加）
- 测试时，先匹配酒店（生成标准酒店id），再抓取报价（spl_rate_00需要有数据），之后才是房型匹配。此时，应该能在tourmind上面搜索到报价
- 抓取到报价，在tourmind上有显示但点击进入时提示房间已售完（验价失败），需要修改验价接口。添加新供应商时，需要修改配置（可能是其他的包，在确定开发时，需要马上添加，以免耽误之后测试），另需要开放权限（售卖）
- 请求接口的请求头中是否设置错误（如解析json数据，但传递的是xml等）
- 字段RatePlanCode等的长度是否超出
- b2b上预定多间房时，填入的所有信息都会填充到orderRequest.RoomOccupancyList[0]中，每家供应商的规则可能不同，此处需要根据预定房间数量将入住人信息拆分









