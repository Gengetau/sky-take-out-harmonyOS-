package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishController
 * @Description 菜品控制器 (客户端)
 */
@Api(tags = "C端-菜品接口")
@RestController
@RequestMapping("/client/dish")
public class DishController {
	@Autowired
	private DishService dishService;
	
	// 查询指定分类下的菜品
	@GetMapping("/{categoryId}")
	@ApiOperation("根据分类id查询菜品")
	public Result<List<DishVO>> queryDishList(@PathVariable Integer categoryId) {
		// 分类 ID 本身已具备唯一性并关联了 shopId，故此处直接查询即可
		return dishService.queryDishList(categoryId);
	}
}