package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
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
import org.springframework.transaction.annotation.Transactional;

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
	
	@Autowired
	private ShopMapper shopMapper;
	
	@Override
	public Result<List<ShopVO>> getShopsByType(Long typeId) {
		log.info("根据类型 {} 查询店铺列表喵", typeId);
		LambdaQueryWrapper<Shop> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Shop::getShopTypeId, typeId)
				.eq(Shop::getStatus, 1);
		
		List<Shop> list = shopMapper.selectList(queryWrapper);
		return Result.success(convertToVOList(list));
	}
	
	@Override
	public Result<ShopVO> getShopById(Long id) {
		log.info("查询店铺 {} 的详情喵", id);
		Shop shop = shopMapper.selectById(id);
		if (shop == null) {
			return Result.error("店铺不存在喵！");
		}
		return Result.success(convertToVO(shop));
	}
	
	@Override
	public Result<List<ShopVO>> getNearbyShops(Long typeId, Double longitude, Double latitude, Integer page) {
		if (longitude == null || latitude == null) {
			return getShopsByType(typeId);
		}
		int pageSize = 10;
		int from = (page - 1) * pageSize;
		int end = page * pageSize;
		
		String key = RedisConstants.SHOP_GEO_KEY + typeId;
		// 搜索半径 10 公里喵
		GeoResults<RedisGeoCommands.GeoLocation<String>> results = stringRedisTemplate.opsForGeo()
				.search(
						key,
						GeoReference.fromCoordinate(longitude, latitude),
						new Distance(10000),
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
		
		List<Long> ids = new ArrayList<>();
		Map<String, Distance> distanceMap = new HashMap<>();
		list.stream().skip(from).forEach(result -> {
			String shopIdStr = result.getContent().getName();
			ids.add(Long.valueOf(shopIdStr));
			distanceMap.put(shopIdStr, result.getDistance());
		});
		
		// 妮娅修复：在数据库查询时强制排除打烊店铺，增加双重保险喵！✨
		String idStr = CollUtil.join(ids, ",");
		List<Shop> shops = query().in("id", ids)
				.eq("status", 1) // 必须是营业中喵！
				.last("ORDER BY FIELD(id," + idStr + ")")
				.list();
		
		if (CollUtil.isEmpty(shops)) {
			return Result.success(Collections.emptyList());
		}
		
		List<ShopVO> voList = shops.stream().map(shop -> {
			ShopVO vo = convertToVO(shop);
			Distance distance = distanceMap.get(shop.getId().toString());
			if (distance != null) {
				double value = distance.getValue();
				if (value < 1000) {
					vo.setDistance((int) value + "m");
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
		if (shopMapper == null) {
			log.error("shopMapper 注入失败喵！");
			return;
		}
		
		LambdaQueryWrapper<Shop> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Shop::getStatus, 1); // 预热时只选营业中的喵
		List<Shop> shops = shopMapper.selectList(queryWrapper);
		
		if (CollUtil.isEmpty(shops)) {
			log.warn("数据库中没有营业中的店铺喵。");
			return;
			
		}
		
		Map<Long, List<Shop>> group = shops.stream()
				.filter(s -> s.getShopTypeId() != null
						&& s.getLongitude() != null
						&& s.getLatitude() != null)
				.collect(Collectors.groupingBy(Shop::getShopTypeId));
		
		if (group.isEmpty()) {
			log.warn("没有符合坐标预热要求的店铺数据喵！");
			return;
		}
		
		group.forEach((typeId, shopList) -> {
			String key = RedisConstants.SHOP_GEO_KEY + typeId;
			stringRedisTemplate.delete(key);
			
			List<RedisGeoCommands.GeoLocation<String>> locations = new ArrayList<>();
			for (Shop shop : shopList) {
				locations.add(new RedisGeoCommands.GeoLocation<>(
						shop.getId().toString(),
						new Point(shop.getLongitude().doubleValue(), shop.getLatitude().doubleValue())
				));
			}
			stringRedisTemplate.opsForGeo().add(key, locations);
			log.info("类型 {} 预热了 {} 家店铺喵", typeId, shopList.size());
		});
		log.info("店铺数据预热任务执行完毕喵！✨");
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public void updateStatus(Long shopId, Integer status) {
		log.info("更新店铺 {} 的状态为 {} 喵", shopId, status);
		
		// 1. 查询店铺原本信息（为了获取 typeId 来操作 Redis GEO）
		Shop shop = getById(shopId);
		if (shop == null) {
			return;
		}
		
		// 2. 更新数据库
		shop.setStatus(status);
		shopMapper.updateById(shop);
		
		// 3. 更新状态 Redis Key (针对多商家)
		String statusKey = RedisConstants.SHOP_STATUS_KEY + ":" + shopId;
		stringRedisTemplate.opsForValue().set(statusKey, status.toString());
		
		// 4. 维护 GEO 地理位置缓存喵！✨
		String geoKey = RedisConstants.SHOP_GEO_KEY + shop.getShopTypeId();
		if (status == 1) {
			// 开业：加入 GEO 缓存
			if (shop.getLongitude() != null && shop.getLatitude() != null) {
				stringRedisTemplate.opsForGeo().add(geoKey, new Point(shop.getLongitude().doubleValue(), shop.getLatitude().doubleValue()), shopId.toString());
				log.info("店铺 {} 已重新加入 GEO 地理位置缓存喵！✨", shopId);
			}
		} else {
			// 打烊：从 GEO 缓存中移除，防止用户搜到打烊店喵！✨
			stringRedisTemplate.opsForZSet().remove(geoKey, shopId.toString());
			log.info("店铺 {} 已从 GEO 地理位置缓存中移除喵！🌙", shopId);
		}
	}
	
	private ShopVO convertToVO(Shop shop) {
		ShopVO vo = new ShopVO();
		BeanUtil.copyProperties(shop, vo);
		if (vo.getAvatar() != null && !vo.getAvatar().isEmpty()) {
			try {
				String signedUrl = AliOssUtil.getSignedUrl(ossClient, vo.getAvatar(), ossConfig.getBucketName());
				vo.setAvatar(signedUrl);
			} catch (Exception e) {
				log.error("获取店铺头像签名失败喵", e);
			}
		}
		return vo;
	}
	
	private List<ShopVO> convertToVOList(List<Shop> list) {
		if (CollUtil.isEmpty(list)) {
			return Collections.emptyList();
		}
		return list.stream().map(this::convertToVO).collect(Collectors.toList());
	}
}
