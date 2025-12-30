package com.sky.controller.admin;

import cn.hutool.core.util.StrUtil;
import com.sky.result.Result;
import com.sky.service.ShopService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
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
@Api(tags = "管理端-店铺相关接口")
public class AdminShopController {
	@Autowired
	private StringRedisTemplate stringRedisTemplate;

	@Autowired
	private ShopService shopService;
	
	/**
	 * 获取店铺营业状态
	 *
	 * @return
	 */
	@GetMapping("/status")
	@ApiOperation("获取店铺营业状态")
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
	@ApiOperation("设置店铺营业状态")
	public Result<String> updateShopStatus(@PathVariable String status) {
		log.info("更改店铺营业状态,{}", status);
		stringRedisTemplate.opsForValue().set(SHOP_STATUS_KEY, status);
		return Result.success(status);
	}

	/**
	 * 预热店铺地理位置数据到 Redis
	 * @return
	 */
	@PostMapping("/preheat")
	@ApiOperation("预热店铺地理位置数据到 Redis喵")
	public Result<String> preheat() {
		log.info("管理端触发店铺数据预热喵！");
		shopService.loadShopGeoDataToRedis();
		return Result.success("预热指令执行成功喵！✨");
	}
}