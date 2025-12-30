package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.ShopService;
import com.sky.vo.ShopVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController("clientShopController")
@RequestMapping("/client/shop")
@Api(tags = "C端-店铺相关接口")
@Slf4j
public class ShopController {

    @Autowired
    private ShopService shopService;

    @GetMapping("/list/{typeId}")
    @ApiOperation("查询商家列表 (支持地理位置排序)")
    public Result<List<ShopVO>> list(
            @PathVariable Long typeId,
            Double longitude,
            Double latitude,
            @RequestParam(defaultValue = "1") Integer page) {
        log.info("C端查询店铺列表，类型ID：{}，坐标：({},{})，页码：{}", typeId, longitude, latitude, page);
        
        if (longitude != null && latitude != null) {
            // 如果提供了经纬度，走 GEO 查询
            return shopService.getNearbyShops(typeId, longitude, latitude, page);
        } else {
            // 否则走基础按类型查询
            return shopService.getShopsByType(typeId);
        }
    }

    @GetMapping("/{id}")
    @ApiOperation("根据ID查询店铺详情")
    public Result<ShopVO> getById(@PathVariable Long id) {
        log.info("C端查询店铺详情，ID：{}", id);
        return shopService.getShopById(id);
    }
}
