package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.OrderDetail;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OrderDetailMapper
 * @Description 订单详请持久层接口
 * @dateTime 15/12/2025 上午11:25
 */
@Mapper
public interface OrderDetailMapper extends BaseMapper<OrderDetail> {
}
