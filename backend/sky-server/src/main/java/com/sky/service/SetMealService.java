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
	
}
