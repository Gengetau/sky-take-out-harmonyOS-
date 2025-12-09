package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.ShopType;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopTypeMapper
 * @Description 店铺类型持久层接口
 * @dateTime 3/12/2025 下午5:16
 */
@Mapper
public interface ShopTypeMapper extends BaseMapper<ShopType> {
}
