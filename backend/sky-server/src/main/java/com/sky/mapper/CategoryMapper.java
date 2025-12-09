package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.Category;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryMapper
 * @Description 菜品分类持久层接口
 * @dateTime 4/12/2025 上午10:59
 */
@Mapper
public interface CategoryMapper extends BaseMapper<Category> {
}
