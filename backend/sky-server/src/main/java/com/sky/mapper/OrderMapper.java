package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.Orders;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;
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

	/**
	 * 根据时间范围和状态统计营业额
	 * @param begin
	 * @param end
	 * @param status
	 * @return
	 */
	List<Map> getTurnoverByDateRange(
			@Param("begin") LocalDateTime begin,
			@Param("end") LocalDateTime end,
			@Param("status") Integer status);
}
