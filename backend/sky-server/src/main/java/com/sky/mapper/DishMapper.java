package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.Dish;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishMapper
 * @Description 菜品持久层接口
 * @dateTime 4/12/2025 上午10:58
 */
@Mapper
public interface DishMapper extends BaseMapper<Dish> {
}
