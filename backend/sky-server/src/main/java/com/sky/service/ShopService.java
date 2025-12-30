package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.entity.Shop;
import com.sky.result.Result;
import com.sky.vo.ShopVO;
import java.util.List;

public interface ShopService extends IService<Shop> {
    /**
     * 根据店铺类型查询店铺列表
     * @param typeId 类型ID
     * @return
     */
    Result<List<ShopVO>> getShopsByType(Long typeId);

    /**
     * 根据店铺ID获取店铺详情
     * @param id 店铺ID
     * @return
     */
    Result<ShopVO> getShopById(Long id);

    /**
     * 分页查询附近的商家 (Redis GEO 实现)
     * @param typeId 类型ID
     * @param longitude 经度
     * @param latitude 纬度
     * @param page 页码
     * @return
     */
    Result<List<ShopVO>> getNearbyShops(Long typeId, Double longitude, Double latitude, Integer page);

    /**
     * 将数据库中的店铺地理位置数据预热到 Redis 喵
     */
    void loadShopGeoDataToRedis();
}
