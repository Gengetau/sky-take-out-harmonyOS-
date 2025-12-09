package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
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
	Result<List<DishVO>> queryDishList(Integer categoryId);
	
}
