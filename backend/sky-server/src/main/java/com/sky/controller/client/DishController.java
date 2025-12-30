package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishController
 * @Description 菜品控制器
 * @dateTime 4/12/2025 上午10:58
 */
@RestController
@RequestMapping("/client/dish")
public class DishController {
	@Autowired
	private DishService dishService;
	
	// 查询店铺菜品,按分类
	@GetMapping("/{categoryId}")
	public Result<List<DishVO>> queryDishList(@PathVariable Integer categoryId) {
		return dishService.queryDishList(categoryId);
	}
}
