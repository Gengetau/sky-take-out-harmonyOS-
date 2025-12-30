package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.SetMealService;
import com.sky.vo.SetMealVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SetMealController
 * @Description 客户端套餐控制器 (客户端)
 */
@RestController
@RequestMapping("/client/setmeal")
@Api(tags = "C端-套餐接口")
@Slf4j
public class SetMealController {
	
	@Autowired
	private SetMealService setMealService;
	
	/**
	 * 根据分类id查询套餐
	 * @param categoryId
	 * @return
	 */
	@GetMapping("/{categoryId}")
	@ApiOperation("根据分类id查询套餐")
	public Result<List<SetMealVO>> getByCategoryId(@PathVariable Long categoryId) {
		// 套餐分类 ID 本身已具备唯一性并关联了 shopId
		return setMealService.getByCategoryId(categoryId);
	}
}