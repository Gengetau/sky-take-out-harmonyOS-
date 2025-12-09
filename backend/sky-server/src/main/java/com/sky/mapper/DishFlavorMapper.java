package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.DishFlavor;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishFlavorMapper
 * @Description 菜品口味持久层接口
 * @dateTime 4/12/2025 上午11:00
 */
@Mapper
public interface DishFlavorMapper extends BaseMapper<DishFlavor> {
}
