package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.Orders;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OrderMapper
 * @Description 订单表持久层接口
 * @dateTime 9/12/2025 下午12:55
 */
@Mapper
public interface OrderMapper extends BaseMapper<Orders> {
	Map<String, Object> getOrderDataByTimeRange(
			@Param("begin") LocalDateTime begin,
			@Param("end") LocalDateTime end);
}
