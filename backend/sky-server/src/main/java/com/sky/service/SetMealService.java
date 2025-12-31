package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.SetmealDTO;
import com.sky.dto.SetmealPageQueryDTO;
import com.sky.entity.SetMeal;
import com.sky.result.Result;
import com.sky.vo.SetMealVO;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SetMealService
 * @Description 套餐业务层接口
 * @dateTime 11/12/2025 上午10:54
 */
public interface SetMealService extends IService<SetMeal> {
	Result<Page<SetMealVO>> getSetMealByPage(SetmealPageQueryDTO dto);
	
	Result<String> setMealStatus(Integer status, Long setmealId);
	
	Result<String> saveSetMeal(SetmealDTO dto);
	
	Result<SetMealVO> getSetMealById(Long id);
	
	Result<String> updateSetMeal(SetmealDTO dto);
	
	Result<String> deleteBatch(List<Long> ids);
	
	/**
	 * 根据分类id查询套餐
	 *
	 * @param categoryId
	 * @return
	 */
	Result<List<SetMealVO>> getByCategoryId(Long categoryId);

	// ===============================================
	// =================== Meow App 商家端 ============
	// ===============================================

	/**
	 * 商家端根据分类查询套餐列表 (强制 shopId 隔离)
	 */
	Result<List<SetMealVO>> getShopSetMealListByCategory(Long categoryId, Long shopId);

	/**
	 * 商家端查询套餐详情 (强制 shopId 隔离)
	 */
	Result<SetMealVO> getShopSetMealById(Long id, Long shopId);

	/**
	 * 商家端起售/停售套餐 (强制 shopId 隔离)
	 */
	Result<String> shopSetMealStatus(Integer status, Long id, Long shopId);

	/**
	 * 商家端新增套餐 (带店铺归属)
	 */
	Result<String> addShopSetMeal(SetmealDTO dto, Long shopId);

	/**
	 * 商家端修改套餐 (带越权检查)
	 */
	Result<String> updateShopSetMeal(SetmealDTO dto, Long shopId);

	/**
	 * 商家端批量删除套餐 (带越权检查)
	 */
	Result<String> deleteShopSetMeals(List<Long> ids, Long shopId);
}
