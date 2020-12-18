[原文链接](https://blog.csdn.net/zhuge1127/article/details/82494783?utm_source=blogxgwz0)  
https://backlog.com/git-tutorial/cn/stepup/stepup2_8.html

package main

import (
	"flag"
	"fmt"
	log "github.com/sirupsen/logrus"
	"github.com/tealeg/xlsx"
	"strconv"
	"strings"
	"sync"
	"time"
	"tourmind.cn/hlz/domain"
	common2 "tourmind.cn/spls/common"
	"tourmind.cn/spls/suppliers/huizhi/model/common"
	"tourmind.cn/spls/suppliers/huizhi/model/static"
	"tourmind.cn/spls/suppliers/huizhi/tools"
)

var (
	filename    = flag.String("f", "汇智top100.xlsx", "static data excel file name")
	filenameNew = flag.String("fn", "汇智直采酒店.xlsx", "static data excel file name")
)

func main() {
	flag.Parse()
	//getStatic()
	//readfile("hot_hotel.xlsx")
	readfile(*filename)
	readfileNew(*filenameNew)
}

func readfile(file string) {
	// 打开文件
	xlFile, err := xlsx.OpenFile(file)
	if err != nil {
		log.Println("打开文件失败！" + err.Error())
		return
	}

	ids := make([]string, 0, 10)
	if len(xlFile.Sheets) == 0 {
		log.Println("没有找到工作表")
	}
	lockMap := Map{hotelMap: map[string]domain.Hotel{}, roomTypeMap: map[string]domain.RoomType{}}
	for k, row := range xlFile.Sheets[0].Rows {
		if k == 0 {
			if len(row.Cells) != 12 {
				log.Println("字段有变动！")
				return
			}
			continue
		}
		ids = append(ids, row.Cells[0].String())
		if len(ids) == 10 {
			roomType(strings.Join(ids, ","), &lockMap)
			ids = make([]string, 0, 10)
		}
		if err := fill(row, lockMap); err != nil {
			return
		}
		if len(lockMap.hotelMap)%1000 == 0 {
			log.Println("1000个酒店")
			hotelList := make([]domain.Hotel, 0)
			for _, v := range lockMap.hotelMap {
				hotelList = append(hotelList, v)
			}
			common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
			lockMap.hotelMap = map[string]domain.Hotel{}
		}
	}
	hotelList := make([]domain.Hotel, 0)
	for _, v := range lockMap.hotelMap {
		hotelList = append(hotelList, v)
	}
	common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
	common2.UpdateRoomTypeMap(domain.SPL_HUIZHI_ID, lockMap.roomTypeMap)
	fmt.Println("\n\nimport success")
}

func fill(row *xlsx.Row, lockMap Map) (err error) {
	hotel_code := row.Cells[0].String()
	hotel_name := row.Cells[1].String()
	hotel_name_en := row.Cells[2].String()
	country := row.Cells[3].String()
	country_code := row.Cells[4].String()
	city := row.Cells[5].String()
	city_code := row.Cells[6].String()
	star := row.Cells[7].String()
	phone := row.Cells[8].String()
	longitude := row.Cells[9].String()
	latitude := row.Cells[10].String()
	address := row.Cells[11].String()
	h := domain.Hotel{
		SupplierId:     domain.SPL_HUIZHI_ID,
		HotelCode:      hotel_code,
		CountryNameCN:  country,
		SplCountryCode: country_code,
		CityCode:       city_code,
		HotelName:      hotel_name_en,
		HotelNameCN:    hotel_name,
		Longitude:      longitude,
		Latitude:       latitude,
		Status:         domain.ACTIVE,
		AddressCN:      address,
		Address:        address,
		Phone:          phone,
		CityNameCN:     city,
	}
	//h.SupplierId = domain.SPL_HUIZHI_ID
	//h.HotelCode = hotel_code
	//h.CountryNameCN = country
	//h.HotelName = hotel_name_en
	//h.HotelNameCN = hotel_name
	//h.Longitude = longitude
	//h.Latitude = latitude
	//h.StarRating, _ = strconv.Atoi(star)
	//h.Status = domain.ACTIVE
	//h.AddressCN = address
	//h.Phone = phone
	//h.CityNameCN = city
	h.StarRating, err = strconv.Atoi(star)
	if err != nil {
		if star == "" {
			h.StarRating = 0
		} else {
			if sp := strings.Split(star, "."); len(sp) == 2 {
				h.StarRating, err = strconv.Atoi(sp[0])
				if err != nil {
					log.Println("酒店星级转换失败，酒店id：", hotel_code)
					return
				}
			} else {
				log.Println("酒店星级转换失败，酒店id：", hotel_code)
				return
			}
		}
	}
	h.HotelId, err = strconv.Atoi(hotel_code)
	if err != nil {
		log.Println("酒店id转换失败，酒店id：", hotel_code)
		return
	}
	//log.Printf("%+v", h)
	lockMap.setHotel(h.HotelCode, h)
	return
}

//新的静态数据文件
func readfileNew(file string) {
	// 打开文件
	xlFile, err := xlsx.OpenFile(file)
	if err != nil {
		log.Println("打开文件失败！" + err.Error())
		return
	}

	ids := make([]string, 0, 10)
	if len(xlFile.Sheets) == 0 {
		log.Println("没有找到工作表")
	}
	lockMap := Map{hotelMap: map[string]domain.Hotel{}, roomTypeMap: map[string]domain.RoomType{}}
	for i := 0; i < 2; i++ {
		for k, row := range xlFile.Sheets[i].Rows {
			if k == 0 {
				if len(row.Cells) != 15 {
					log.Println("字段有变动！")
					return
				}
				continue
			}
			ids = append(ids, row.Cells[0].String())
			if len(ids) == 10 {
				roomType(strings.Join(ids, ","), &lockMap)
				ids = make([]string, 0, 10)
			}
			if err := fillNew(row, lockMap); err != nil {
				return
			}
			if len(lockMap.hotelMap)%1000 == 0 {
				log.Println("1000个酒店")
				hotelList := make([]domain.Hotel, 0)
				for _, v := range lockMap.hotelMap {
					hotelList = append(hotelList, v)
				}
				common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
				lockMap.hotelMap = map[string]domain.Hotel{}
			}
		}
	}

	hotelList := make([]domain.Hotel, 0)
	for _, v := range lockMap.hotelMap {
		hotelList = append(hotelList, v)
	}
	common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
	common2.UpdateRoomTypeMap(domain.SPL_HUIZHI_ID, lockMap.roomTypeMap)
	fmt.Println("\n\nimport success")
}

func fillNew(row *xlsx.Row, lockMap Map) (err error) {
	hotel_code := row.Cells[0].String()
	hotel_name := row.Cells[1].String()
	hotel_name_en := row.Cells[2].String()
	country := row.Cells[3].String()
	country_code := row.Cells[4].String()
	city := row.Cells[7].String()
	city_code := row.Cells[8].String()
	star := row.Cells[9].String()
	phone := row.Cells[10].String()
	longitude := row.Cells[11].String()
	latitude := row.Cells[12].String()
	address := row.Cells[13].String()
	h := domain.Hotel{
		SupplierId:     domain.SPL_HUIZHI_ID,
		HotelCode:      hotel_code,
		CountryNameCN:  country,
		SplCountryCode: country_code,
		CityCode:       city_code,
		HotelName:      hotel_name_en,
		HotelNameCN:    hotel_name,
		Longitude:      longitude,
		Latitude:       latitude,
		CountryCode:    countryCodeMap[country],
		Status:         domain.ACTIVE,
		AddressCN:      address,
		Address:        address,
		Phone:          phone,
		CityNameCN:     city,
	}
	//h.SupplierId = domain.SPL_HUIZHI_ID
	//h.HotelCode = hotel_code
	//h.CountryNameCN = country
	//h.HotelName = hotel_name_en
	//h.HotelNameCN = hotel_name
	//h.Longitude = longitude
	//h.Latitude = latitude
	//h.StarRating, _ = strconv.Atoi(star)
	//h.Status = domain.ACTIVE
	//h.AddressCN = address
	//h.Phone = phone
	//h.CityNameCN = city
	h.StarRating, err = strconv.Atoi(star)
	if err != nil {
		if star == "" {
			h.StarRating = 0
		} else {
			if sp := strings.Split(star, "."); len(sp) == 2 {
				h.StarRating, err = strconv.Atoi(sp[0])
				if err != nil {
					log.Println("酒店星级转换失败，酒店id：", hotel_code)
					return
				}
			} else {
				log.Println("酒店星级转换失败，酒店id：", hotel_code)
				return
			}
		}
	}
	h.HotelId, err = strconv.Atoi(hotel_code)
	if err != nil {
		log.Println("酒店id转换失败，酒店id：", hotel_code)
		return
	}
	//log.Printf("%+v", h)
	lockMap.setHotel(h.HotelCode, h)
	return
}

var countryCodeMap = map[string]string{
	"中国":   "CN",
	"韩国":   "KR",
	"泰国":   "TH",
	"日本":   "JP",
	"菲律宾":  "PH",
	"越南":   "VN",
	"马来西亚": "MY",
	"美国":   "US",
	"柬埔寨":  "KH",
}

func roomType(ids string, lockMap *Map) {
	res := getHotelData(static.HotelRequest{Hids: ids})
	for _, hotel := range res.Result.Hotels {
		for _, room := range hotel.Rooms {
			rt := domain.RoomType{
				RoomTypeCode:     strconv.Itoa(hotel.Hid) + "#" + strconv.Itoa(room.Rid),
				SplRoomTypeCode:  strconv.Itoa(room.Rid),
				SupplierId:       domain.SPL_HUIZHI_ID,
				HotelCode:        strconv.Itoa(hotel.Hid),
				RoomTypeName:     room.EnName,
				RoomTypeNameCN:   room.Name,
				SplBedTypeDescCN: room.BedType,
				MaxOccupancy:     room.MaxOccupancy,
				Status:           domain.ACTIVE,
			}

			lockMap.setRoomType(rt.RoomTypeCode, rt)

			if len(lockMap.roomTypeMap) > 1000 {
				log.Println("1000个房型")
				common2.UpdateRoomTypeMap(domain.SPL_HUIZHI_ID, lockMap.roomTypeMap)
				lockMap.roomTypeMap = map[string]domain.RoomType{}
			}
		}
	}
}

//*************************************************************  接口获取静态数据， 暂未使用  ***************************************************************
func getStatic() {
	start := time.Now().Unix()
	log.Printf("start")
	cityRes := getCityData()
	lockMap := Map{hotelMap: map[string]domain.Hotel{}}
	for _, country := range cityRes.Result.CountryList {
		for _, province := range country.ProvinceList {
			for _, city := range province.CityList {
				hotelListRes := getHotelListData(static.HotelListRequest{CountryCode: country.CountryCode, CityCode: city.CityCode})
				ids := ""
				for _, id := range hotelListRes.Result.Hotelids {
					ids += "," + strconv.Itoa(id.Hid)
					hos := getHotelData(static.HotelRequest{Hids: ids[1:]})
					if hos.Code == "0" {
						for _, h := range hos.Result.Hotels {
							fillData(&lockMap, country, city, h)
							if len(lockMap.hotelMap)%300 == 0 {
								log.Println("300个酒店")
								hotelList := make([]domain.Hotel, 0)
								for _, v := range lockMap.hotelMap {
									hotelList = append(hotelList, v)
								}
								//common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
								lockMap.hotelMap = map[string]domain.Hotel{}
							}
						}
					} else {
						log.Printf("抓取静态数据失败：酒店ids：%s", ids)
					}
				}
			}
		}
	}
	hotelList := make([]domain.Hotel, 0)
	for _, v := range lockMap.hotelMap {
		hotelList = append(hotelList, v)
	}
	log.Printf("end:%d", len(hotelList))
	//common2.SaveHotels(domain.SPL_HUIZHI_ID, hotelList)
	end := time.Now().Unix()
	log.Printf("%d家酒店更新完成,耗费%ds", len(hotelList), end-start)
}

func fillData(lockMap *Map, country static.Country, city static.City, hotel static.Hotel) {
	h := domain.Hotel{}
	h.SupplierId = domain.SPL_HUIZHI_ID
	h.HotelCode = strconv.Itoa(hotel.Hid)
	h.HotelName = hotel.EnName
	h.HotelNameCN = hotel.Name

	h.SplCountryCode = strconv.Itoa(country.CountryCode)
	h.CountryCode = strconv.Itoa(country.CountryCode)

	h.CityCode = strconv.Itoa(city.CityCode)
	h.Longitude = hotel.Longitude
	h.Latitude = hotel.Latitude
	h.StarRating, _ = strconv.Atoi(hotel.Star)
	h.Status = domain.ACTIVE

	h.Address = hotel.Address
	h.AddressCN = hotel.Address
	h.Phone = hotel.Tel
	h.HotelId = hotel.Hid
	h.CityName = city.CityEnName
	h.CityNameCN = city.CityName
	//log.Printf("hotelid:%s, city_name:%s, hotel_name:%s", h.SplCountryCode, h.CityNameCN, h.HotelNameCN)
	lockMap.setHotel(h.HotelCode, h)
}

func getCityData() *static.CityResponse {
	res := new(static.CityResponse)
	httpMessage := tools.SendHuiZhiData(common.CITY_URL, nil, res, false)
	if res.Code != "0" {
		log.Printf("get City failed")
		log.Println("http message", httpMessage.ResultMessage)
	}
	return res
}

func getHotelListData(hotelListReq static.HotelListRequest) *static.HotelListResponse {
	res := new(static.HotelListResponse)
	httpMessage := tools.SendHuiZhiData(common.HOTEL_List_URL, hotelListReq, res, false)
	if res.Code != "0" {
		log.Printf("get hotelIds failed, countryCode:%d, cityCode:%d", hotelListReq.CountryCode, hotelListReq.CityCode)
		log.Println("http message", httpMessage.ResultMessage)
	}
	return res
}

func getHotelData(hotelReq static.HotelRequest) *static.HotelResponse {
	res := new(static.HotelResponse)
	httpMessage := tools.SendHuiZhiData(common.HOTEL_URL, hotelReq, res, false)
	if res.Code != "0" {
		log.Printf("get hotelDetail failed")
		log.Println("http message", httpMessage.ResultMessage)
	}
	return res
}

type Map struct {
	hotelMap    map[string]domain.Hotel
	Lock        sync.RWMutex
	roomTypeMap map[string]domain.RoomType
}

func (m *Map) setHotel(hotelCode string, hotel domain.Hotel) {
	m.Lock.Lock()
	defer m.Lock.Unlock()
	m.hotelMap[hotelCode] = hotel
}
func (m *Map) setRoomType(roomTypeCode string, roomType domain.RoomType) {
	m.Lock.Lock()
	defer m.Lock.Unlock()
	m.roomTypeMap[roomTypeCode] = roomType
}









	//if res := pps.GetPpsHotelMappingServiceClient().GetCityVicinityRegionID(&request.RegionName); res.Success {
	if res := pps_fulltext_search.SearchSRegion(&pps_fulltext_search.SRegionSearchRequest{
		Keyword: request.RegionName,
	}); res.Success {
		result.Data = res.Docs
		result.Success = true
	} else {
		result.Message = res.Message
	}
