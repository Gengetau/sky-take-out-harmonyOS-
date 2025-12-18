package com.sky.controller.client;

import com.sky.result.Result;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.sky.constant.RedisConstants.SHOP_STATUS_KEY;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopController
 * @Description 客户端店铺控制器
 * @dateTime 18/12/2025 下午5:00
 */
@Slf4j
@Api(tags = "客户端店铺控制器")
@RestController
@RequestMapping("/client/shop")
public class ShopController {
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@GetMapping("/status")
	@ApiOperation("获取店铺营业状态")
	public Result<Integer> getShopStatus() {
		String status = stringRedisTemplate.opsForValue().get(SHOP_STATUS_KEY);
		log.info("获取店铺营业状态,{}", status);
		if (status != null && !status.isEmpty()) {
			return Result.success(Integer.valueOf(status));
		}
		// 如果未设置，为了安全默认返回 0（打烊）
		return Result.success(0);
	}
}
