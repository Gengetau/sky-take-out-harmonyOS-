package com.sky.service;

import com.sky.result.Result;
import com.sky.vo.BusinessDataVO;
import com.sky.vo.DishOverViewVO;
import com.sky.vo.OrderOverViewVO;
import com.sky.vo.SetmealOverViewVO;

public interface WorkSpaceService {
	/**
	 * 查询套餐总览
	 *
	 * @return
	 */
	SetmealOverViewVO getSetmealOverView();
	
	DishOverViewVO getDishOverView();
	
	OrderOverViewVO getOrderOverView();
	
	Result<BusinessDataVO> getBusinessData();
}