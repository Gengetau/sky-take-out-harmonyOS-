package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.entity.ShopType;
import com.sky.mapper.ShopTypeMapper;
import com.sky.result.Result;
import com.sky.service.ShopTypeService;
import com.sky.vo.ShopTypeVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

import static com.sky.constant.RedisConstants.SHOP_TYPE_KEY;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopTypeServiceImpl
 * @Description
 * @dateTime 3/12/2025 下午5:16
 */
@Service
@Slf4j
public class ShopTypeServiceImpl extends ServiceImpl<ShopTypeMapper, ShopType>
		implements ShopTypeService {
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@Override
	public Result<List<ShopTypeVO>> queryList() {
		// 1.查询redis是否有缓存
		List<String> list = stringRedisTemplate.opsForList().range(SHOP_TYPE_KEY, 0, -1);
		// 2.存在，返回结果
		if (!CollUtil.isEmpty(list)) {
			List<ShopTypeVO> types = JSONUtil.toList(list.toString(), ShopTypeVO.class);
			return Result.success(types);
		}
		// 3.不存在，查询数据库
		List<ShopType> types = list(new LambdaQueryWrapper<ShopType>().orderByAsc(ShopType::getSort));
		List<ShopTypeVO> shopTypeVOS = BeanUtil.copyToList(types, ShopTypeVO.class);
		// 4.数据库不存在，返回错误
		if (CollUtil.isEmpty(types)) {
			return Result.error("店铺类型不存在");
		}
		// 5.写入缓存
		List<String> typeJsons = types.stream().map(JSONUtil::toJsonStr)
				.collect(Collectors.toList());
		stringRedisTemplate.opsForList().rightPushAll(SHOP_TYPE_KEY, typeJsons);
		// 6.返回结果
		return Result.success(shopTypeVOS);
	}
}
