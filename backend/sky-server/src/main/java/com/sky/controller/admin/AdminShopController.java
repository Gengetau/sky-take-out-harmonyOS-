package com.sky.controller.admin;

import cn.hutool.core.util.StrUtil;
import com.sky.result.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.*;

import static com.sky.constant.MessageConstant.BUSINESS_STATUS_IS_NOT_SET;
import static com.sky.constant.RedisConstants.SHOP_STATUS_KEY;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminShopController
 * @Description 管理端商店控制器
 * @dateTime 11/12/2025 上午11:19
 */
@Slf4j
@RestController
@RequestMapping("/admin/shop")
public class AdminShopController {
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	/**
	 * 获取店铺营业状态
	 *
	 * @return
	 */
	@GetMapping("/status")
	public Result<Integer> getShopStatus() {
		String status = stringRedisTemplate.opsForValue().get(SHOP_STATUS_KEY);
		log.info("获取店铺营业状态,{}", status);
		if (StrUtil.isNotBlank(status)) {
			return Result.success(Integer.valueOf(status));
		}
		return Result.error(BUSINESS_STATUS_IS_NOT_SET);
	}
	
	/**
	 * 设置店铺营业状态
	 *
	 * @param status
	 * @return
	 */
	@PutMapping("/{status}")
	public Result<String> updateShopStatus(@PathVariable String status) {
		log.info("更改店铺营业状态,{}", status);
		stringRedisTemplate.opsForValue().set(SHOP_STATUS_KEY, status);
		return Result.success(status);
	}
}
