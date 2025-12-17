package com.sky.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.sky.constant.StatusConstant;
import com.sky.entity.Dish;
import com.sky.entity.SetMeal;
import com.sky.mapper.DishMapper;
import com.sky.mapper.OrderMapper;
import com.sky.mapper.SetMealMapper;
import com.sky.mapper.UserMapper;
import com.sky.result.Result;
import com.sky.service.WorkSpaceService;
import com.sky.vo.BusinessDataVO;
import com.sky.vo.DishOverViewVO;
import com.sky.vo.SetmealOverViewVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Map;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName WorkSpaceServiceImpl
 * @Description
 * @dateTime 9/12/2025 下午12:51
 */
@Service
@Slf4j
public class
WorkSpaceServiceImpl implements WorkSpaceService {
	@Autowired
	private UserMapper userMapper;
	@Autowired
	private OrderMapper orderMapper;
	@Autowired
	private SetMealMapper setMealMapper;
	@Autowired
	private DishMapper dishMapper;
	
	@Override
	public Result<BusinessDataVO> getBusinessData() {
		log.info("查询今日运营数据");
		// 1. 定义今天的起止时间
		LocalDateTime beginTime = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
		LocalDateTime endTime = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);
		
		// 2.查询所有订单相关数据
		Map<String, Object> orderData = orderMapper
				.getOrderDataByTimeRange(beginTime, endTime);
		
		// 3.查询用户相关数据
		Long newUserCount = userMapper.getNewUserCountByTimeRange(beginTime, endTime);
		
		// 4. 从聚合结果中获取数据
		// 如果当天没有订单，turnover可能是null，需要处理一下
		Double turnover = (Double) orderData.getOrDefault("turnover", 0.0);
		Long validOrderCount = (Long) orderData.getOrDefault("validOrderCount", 0L);
		Long totalOrderCount = (Long) orderData.getOrDefault("totalOrderCount", 0L);
		
		// 5. 计算订单完成率和平均客单价
		Double orderCompletionRate = (totalOrderCount == 0) ? 0.0 : (double) validOrderCount / totalOrderCount;
		Double unitPrice = (validOrderCount == 0) ? 0.0 : turnover / validOrderCount;
		
		// 6. 组装VO对象
		BusinessDataVO businessDataVO = BusinessDataVO.builder()
				.turnover(turnover)
				.validOrderCount(validOrderCount.intValue())
				.orderCompletionRate(orderCompletionRate)
				.unitPrice(unitPrice)
				.newUsers(newUserCount.intValue())
				.build();
		return Result.success(businessDataVO);
	}
	
	@Override
	public SetmealOverViewVO getSetmealOverView() {
		LambdaQueryWrapper<SetMeal> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(SetMeal::getStatus, StatusConstant.ENABLE);
		Integer sold = Math.toIntExact(setMealMapper.selectCount(queryWrapper));
		queryWrapper.clear();
		queryWrapper.eq(SetMeal::getStatus, StatusConstant.DISABLE);
		Integer discontinued = Math.toIntExact(setMealMapper.selectCount(queryWrapper));
		return new SetmealOverViewVO(sold, discontinued);
	}
	
	@Override
	public DishOverViewVO getDishOverView() {
		LambdaQueryWrapper<Dish> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Dish::getStatus, StatusConstant.ENABLE);
		Integer sold = Math.toIntExact(dishMapper.selectCount(queryWrapper));
		queryWrapper.clear();
		queryWrapper.eq(Dish::getStatus, StatusConstant.DISABLE);
		Integer discontinued = Math.toIntExact(dishMapper.selectCount(queryWrapper));
		return new DishOverViewVO(sold, discontinued);
	}
}
