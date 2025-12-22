package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.entity.ShopType;
import com.sky.mapper.ShopTypeMapper;
import com.sky.result.Result;
import com.sky.service.ShopTypeService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.ShopTypeVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static com.sky.constant.RedisConstants.CACHE_TYPE_TTL;
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
	private OSS ossClient;
	@Autowired
	private OSSConfig ossConfig;
	
	@Override
	@Cacheable(cacheNames = "shopTypeCache", key = "'all'")
	public Result<List<ShopTypeVO>> queryList() {
		// 1.查询数据库
		List<ShopType> types = list(new LambdaQueryWrapper<ShopType>().orderByAsc(ShopType::getSort));
		
		// 2.数据库不存在，返回错误
		if (CollUtil.isEmpty(types)) {
			return Result.error("店铺类型不存在");
		}
		
		// 3.进行OSS图片签名并转换为VO
		List<ShopTypeVO> shopTypeVOS = types.stream().map(shopType -> {
			ShopTypeVO vo = new ShopTypeVO();
			BeanUtil.copyProperties(shopType, vo);
			// 对Icon进行签名
			if (shopType.getIcon() != null && !shopType.getIcon().isEmpty()) {
				String signedUrl = AliOssUtil.getSignedUrl(ossClient, shopType.getIcon(), ossConfig.getBucketName(), CACHE_TYPE_TTL, TimeUnit.HOURS);
				vo.setIcon(signedUrl);
			}
			return vo;
		}).collect(Collectors.toList());
		
		// 4.返回结果
		return Result.success(shopTypeVOS);
	}
}
