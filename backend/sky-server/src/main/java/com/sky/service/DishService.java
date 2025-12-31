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
	
	Result<String> deleteBatch(List<Long> ids);
	
	Result<String> startOrStop(Integer status, Long id);

	// ===============================================
	// =================== Meow App 商家端 ============
	// ===============================================

	/**
	 * 商家端根据分类查询菜品列表 (强制 shopId 隔离)
	 */
	Result<List<DishVO>> getShopDishListByCategory(Long categoryId, Long shopId);

	/**
	 * 商家端查询菜品详情 (强制 shopId 隔离)
	 */
	Result<DishVO> getShopDishById(Long id, Long shopId);

	/**
	 * 商家端起售/停售菜品 (强制 shopId 隔离)
	 */
	Result<String> shopStartOrStop(Integer status, Long id, Long shopId);

	/**
	 * 商家端新增菜品 (带店铺归属)
	 */
	Result<String> addShopDish(DishDTO dishDTO, Long shopId);

	/**
	 * 商家端修改菜品 (带越权检查)
	 */
	Result<String> updateShopDish(DishDTO dishDTO, Long shopId);

	/**
	 * 商家端批量删除菜品 (带越权检查)
	 */
	Result<String> deleteShopDishes(List<Long> ids, Long shopId);
}
