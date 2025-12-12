package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.dto.DishPageQueryDTO;
import com.sky.entity.Dish;
import com.sky.entity.DishFlavor;
import com.sky.mapper.DishFlavorMapper;
import com.sky.mapper.DishMapper;
import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishServiceImpl
 * @Description
 * @dateTime 4/12/2025 上午11:02
 */
@Service
@Slf4j
public class DishServiceImpl extends ServiceImpl<DishMapper, Dish> implements DishService {
	@Autowired
	private DishFlavorMapper dishFlavorMapper;
	
	@Override
	public Result<List<DishVO>> queryDishList(Integer categoryId) {
		// 1.获取菜品
		List<Dish> list = list(new LambdaQueryWrapper<Dish>()
				.eq(Dish::getCategoryId, categoryId)
				.eq(Dish::getStatus, 1));
		if (!CollUtil.isNotEmpty(list)) {
			return Result.error("获取菜品失败");
		}
		// 2.复制属性
		List<DishVO> dishVOS = BeanUtil.copyToList(list, DishVO.class);
		// 3.设置菜品口味
		dishVOS.forEach(vo -> {
			List<DishFlavor> dishFlavors = dishFlavorMapper
					.selectList(new LambdaQueryWrapper<DishFlavor>()
							.eq(DishFlavor::getDishId, vo.getId()));
			vo.setFlavors(dishFlavors);
		});
		// 4.返回数据
		return Result.success(dishVOS);
	}
	
	@Override
	public Result<Page<DishVO>> getDishByPage(DishPageQueryDTO dto) {
		// 0.获取数据
		int currentPage = dto.getPage();
		int pageSize = dto.getPageSize();
		// 1.创建分页模型
		Page<Dish> page = new Page<>(currentPage, pageSize);
		// 2.查询
		Page<Dish> dishPage = page(page);
		// 3.复制属性
		List<DishVO> dishVOS = BeanUtil.copyToList(dishPage.getRecords(), DishVO.class);
		// 4.创建新的分页模型
		Page<DishVO> voPage = new Page<>(currentPage, pageSize);
		voPage.setRecords(dishVOS);
		voPage.setTotal(dishPage.getTotal());
		// 5.返回
		return Result.success(voPage);
	}
}
