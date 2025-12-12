package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.DishPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminDishController
 * @Description 后台菜品管理控制器
 * @dateTime 12/12/2025 上午9:06
 */
@RestController
@RequestMapping("/admin/dish")
public class AdminDishController {
	@Autowired
	private DishService dishService;
	
	@GetMapping("/page")
	public Result<Page<DishVO>> getDishByPage(DishPageQueryDTO dto) {
		return dishService.getDishByPage(dto);
	}
}
