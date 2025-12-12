package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.DishDTO;
import com.sky.dto.DishPageQueryDTO;
import com.sky.entity.Dish;
import com.sky.result.Result;
import com.sky.vo.DishVO;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishService
 * @Description 菜品业务层接口
 * @dateTime 4/12/2025 上午11:02
 */
public interface DishService extends IService<Dish> {
	// ===============================================
	// =================== 用户端 =====================
	// ===============================================
	Result<List<DishVO>> queryDishList(Integer categoryId);
	
	// ===============================================
	// =================== 管理端 =====================
	// ===============================================
	Result<Page<DishVO>> getDishByPage(DishPageQueryDTO dto);
	
	Result<String> saveDish(DishDTO dishDTO);
	
	Result<List<DishVO>> getDishListByCategory(Long categoryId);
	
	Result<DishVO> getDishById(Long id);
	
	Result<String> updateDish(DishDTO dishDTO);
}
