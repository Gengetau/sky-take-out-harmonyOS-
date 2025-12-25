package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.constant.RedisConstants;
import com.sky.entity.Shop;
import com.sky.mapper.ShopMapper;
import com.sky.result.Result;
import com.sky.service.ShopService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.ShopVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisGeoCommands;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.domain.geo.GeoReference;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class ShopServiceImpl extends ServiceImpl<ShopMapper, Shop> implements ShopService {

    @Autowired
    private OSS ossClient;

    @Autowired
    private OSSConfig ossConfig;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public Result<List<ShopVO>> getShopsByType(Long typeId) {
        log.info("根据类型 {} 查询店铺列表喵", typeId);
        LambdaQueryWrapper<Shop> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Shop::getShopTypeId, typeId)
                    .eq(Shop::getStatus, 1);
        
        List<Shop> list = list(queryWrapper);
        return Result.success(convertToVOList(list));
    }

    @Override
    public Result<ShopVO> getShopById(Long id) {
        log.info("查询店铺 {} 的详情喵", id);
        Shop shop = getById(id);
        if (shop == null) {
            return Result.error("店铺不存在喵！");
        }
        return Result.success(convertToVO(shop));
    }

    @Override
    public Result<List<ShopVO>> getNearbyShops(Long typeId, Double longitude, Double latitude, Integer page) {
        // 1. 基础校验与分页参数
        if (longitude == null || latitude == null) {
            return getShopsByType(typeId);
        }
        int pageSize = 10;
        int from = (page - 1) * pageSize;
        int end = page * pageSize;

        // 2. 查询 Redis GEO
        String key = RedisConstants.SHOP_GEO_KEY + typeId;
        GeoResults<RedisGeoCommands.GeoLocation<String>> results = stringRedisTemplate.opsForGeo()
                .search(
                        key,
                        GeoReference.fromCoordinate(longitude, latitude),
                        new Distance(5000), // 5km 范围内
                        RedisGeoCommands.GeoSearchCommandArgs.newGeoSearchArgs()
                                .includeDistance()
                                .sortAscending()
                                .limit(end)
                );

        if (results == null) {
            return Result.success(Collections.emptyList());
        }

        List<GeoResult<RedisGeoCommands.GeoLocation<String>>> list = results.getContent();
        if (list.size() <= from) {
            return Result.success(Collections.emptyList());
        }

        // 3. 收集 ID 和 距离
        List<Long> ids = new ArrayList<>();
        Map<String, Distance> distanceMap = new HashMap<>();
        list.stream().skip(from).forEach(result -> {
            String shopIdStr = result.getContent().getName();
            ids.add(Long.valueOf(shopIdStr));
            distanceMap.put(shopIdStr, result.getDistance());
        });

        // 4. 查询数据库详情
        String idStr = CollUtil.join(ids, ",");
        List<Shop> shops = query().in("id", ids).last("ORDER BY FIELD(id," + idStr + ")").list();

        // 5. 封装 VO
        List<ShopVO> voList = shops.stream().map(shop -> {
            ShopVO vo = convertToVO(shop);
            Distance distance = distanceMap.get(shop.getId().toString());
            if (distance != null) {
                double value = distance.getValue(); // 默认是米
                if (value < 1000) {
                    vo.setDistance((int)value + "m");
                } else {
                    vo.setDistance(String.format("%.1f", value / 1000) + "km");
                }
            }
            return vo;
        }).collect(Collectors.toList());

        return Result.success(voList);
    }

    @Override
    public void loadShopGeoDataToRedis() {
        log.info("开始将店铺地理位置数据预热到 Redis 喵！");
        // 1. 查询所有营业中的店铺
        List<Shop> shops = list(new LambdaQueryWrapper<Shop>().eq(Shop::getStatus, 1));
        if (CollUtil.isEmpty(shops)) return;

        // 2. 按类型分组，方便批量写入 Redis
        Map<Long, List<Shop>> group = shops.stream()
                .filter(s -> s.getLongitude() != null && s.getLatitude() != null)
                .collect(Collectors.groupingBy(Shop::getShopTypeId));

        // 3. 写入 Redis
        group.forEach((typeId, shopList) -> {
            String key = RedisConstants.SHOP_GEO_KEY + typeId;
            // 清理旧数据（可选，根据需求定）
            stringRedisTemplate.delete(key);
            
            List<RedisGeoCommands.GeoLocation<String>> locations = new ArrayList<>();
            for (Shop shop : shopList) {
                locations.add(new RedisGeoCommands.GeoLocation<>(
                        shop.getId().toString(),
                        new Point(shop.getLongitude().doubleValue(), shop.getLatitude().doubleValue())
                ));
            }
            stringRedisTemplate.opsForGeo().add(key, locations);
        });
        log.info("预热完成喵！✨");
    }

    private ShopVO convertToVO(Shop shop) {
        ShopVO vo = new ShopVO();
        BeanUtil.copyProperties(shop, vo);
        if (vo.getAvatar() != null && !vo.getAvatar().isEmpty()) {
            String signedUrl = AliOssUtil.getSignedUrl(ossClient, vo.getAvatar(), ossConfig.getBucketName());
            vo.setAvatar(signedUrl);
        }
        return vo;
    }

    private List<ShopVO> convertToVOList(List<Shop> list) {
        if (CollUtil.isEmpty(list)) return Collections.emptyList();
        return list.stream().map(this::convertToVO).collect(Collectors.toList());
    }
}