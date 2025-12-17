package com.sky.service.impl;

import com.sky.dto.GoodsSalesDTO;
import com.sky.entity.Orders;
import com.sky.mapper.OrderDetailMapper;
import com.sky.service.ReportService;
import com.sky.vo.SalesTop10ReportVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ReportServiceImpl implements ReportService {
	
	@Autowired
	private OrderDetailMapper orderDetailMapper;
	
	/**
	 * 查询指定时间区间内的销量排名top10
	 *
	 * @param begin
	 * @param end
	 * @return
	 */
	@Override
	public SalesTop10ReportVO getSalesTop10(LocalDate begin, LocalDate end) {
		// 1. 定义起止时间
		LocalDateTime beginTime = LocalDateTime.of(begin, LocalTime.MIN);
		LocalDateTime endTime = LocalDateTime.of(end, LocalTime.MAX);
		// 2. 查询销量排名top10
		List<GoodsSalesDTO> goodsSalesDTOList = orderDetailMapper.getSalesTop10(beginTime, endTime, Orders.COMPLETED);
		// 3. 封装返回结果
		String nameList = goodsSalesDTOList.stream().map(GoodsSalesDTO::getName).collect(Collectors.joining(","));
		String numberList = goodsSalesDTOList.stream().map(goodsSalesDTO -> goodsSalesDTO.getNumber().toString()).collect(Collectors.joining(","));
		
		return new SalesTop10ReportVO(nameList, numberList);
	}
}

