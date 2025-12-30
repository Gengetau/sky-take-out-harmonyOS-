package com.sky.service;

import com.sky.result.Result;
import com.sky.vo.BusinessDataVO;
import com.sky.vo.DishOverViewVO;
import com.sky.vo.OrderOverViewVO;
import com.sky.vo.SetmealOverViewVO;

import java.time.LocalDateTime;

public interface WorkSpaceService {
	/**
	 * 查询套餐总览
	 *
	 * @return
	 */
	SetmealOverViewVO getSetmealOverView();
	
	/**
	 * 查询菜品总览
	 *
	 * @return
	 */
	DishOverViewVO getDishOverView();
	
	/**
	 * 查询订单管理数据
	 *
	 * @return
	 */
	OrderOverViewVO getOrderOverView();
	
	/**
	 * 查询今日运营数据
	 *
	 * @return
	 */
	Result<BusinessDataVO> getBusinessData();
	
	/**
	 * 查询指定时间区间内的运营数据
	 *
	 * @param begin
	 * @param end
	 * @return
	 */
	Result<BusinessDataVO> getBusinessData(LocalDateTime begin, LocalDateTime end);
}
	