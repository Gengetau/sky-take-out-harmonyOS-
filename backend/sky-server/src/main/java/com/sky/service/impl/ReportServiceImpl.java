package com.sky.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.sky.dto.GoodsSalesDTO;
import com.sky.entity.Orders;
import com.sky.entity.User;
import com.sky.mapper.OrderDetailMapper;
import com.sky.mapper.UserMapper;
import com.sky.service.ReportService;
import com.sky.vo.SalesTop10ReportVO;
import com.sky.vo.TurnoverReportVO;
import com.sky.vo.UserReportVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ReportServiceImpl implements ReportService {
	
	@Autowired
	private OrderDetailMapper orderDetailMapper;
	@Autowired
	private UserMapper userMapper;
	
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
	
	    @Override
	        public UserReportVO getUserStatistics(LocalDate begin, LocalDate end) {
	            // 1. 生成日期列表
	            List<LocalDate> dateList = new ArrayList<>();
	            LocalDate current = begin;
	            while (!current.isAfter(end)) {
	                dateList.add(current);
	                current = current.plusDays(1);
	            }
	    
	            // 2. 查询每日新增用户数
	            List<Map> userCountList = userMapper.getUserCount(LocalDateTime.of(begin, LocalTime.MIN), LocalDateTime.of(end, LocalTime.MAX));
	            Map<LocalDate, Integer> newUserMap = userCountList.stream().collect(Collectors.toMap(
	                    map -> LocalDate.parse(map.get("date").toString()),
	                    map -> ((Long) map.get("count")).intValue()
	            ));
	    
	            // 3. 查询初始总用户数
	            LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
	            queryWrapper.lt(User::getCreateTime, LocalDateTime.of(begin, LocalTime.MIN));
	            Integer totalUserCount = userMapper.selectCount(queryWrapper).intValue();
	    
	            // 4. 封装每日用户数据
	            List<Integer> newUserList = new ArrayList<>();
	            List<Integer> totalUserList = new ArrayList<>();
	            for (LocalDate date : dateList) {
	                Integer newCount = newUserMap.getOrDefault(date, 0);
	                newUserList.add(newCount);
	                totalUserCount += newCount;
	                totalUserList.add(totalUserCount);
	            }
	    
	            // 5. 封装返回结果
	            return new UserReportVO(
	                    dateList.stream().map(LocalDate::toString).collect(Collectors.joining(",")),
	                    String.join(",", totalUserList.stream().map(String::valueOf).collect(Collectors.toList())),
	                    String.join(",", newUserList.stream().map(String::valueOf).collect(Collectors.toList()))
	            );
	        }
	    
	        @Override
	        public TurnoverReportVO getTurnoverStatistics(LocalDate begin, LocalDate end) {
	            // 1. 生成日期列表
	            List<LocalDate> dateList = new ArrayList<>();
	            LocalDate current = begin;
	            while (!current.isAfter(end)) {
	                dateList.add(current);
	                current = current.plusDays(1);
	            }
	            // 2. 查询每日营业额
	            List<Map> turnoverListMap = orderMapper.getTurnoverByDateRange(LocalDateTime.of(begin, LocalTime.MIN), LocalDateTime.of(end, LocalTime.MAX), Orders.COMPLETED);
	            Map<LocalDate, Double> turnoverMap = turnoverListMap.stream().collect(Collectors.toMap(
	                    map -> LocalDate.parse(map.get("date").toString()),
	                    map -> (Double) map.get("turnover")
	            ));
	            // 3. 封装每日营业额数据
	            List<Double> turnoverList = new ArrayList<>();
	            for (LocalDate date : dateList) {
	                turnoverList.add(turnoverMap.getOrDefault(date, 0.0));
	            }
	            // 4. 封装返回结果
	            return new TurnoverReportVO(
	                    dateList.stream().map(LocalDate::toString).collect(Collectors.joining(",")),
	                    String.join(",", turnoverList.stream().map(String::valueOf).collect(Collectors.toList()))
	            );
	        }
	    }

