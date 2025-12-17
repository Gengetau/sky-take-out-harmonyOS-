package com.sky.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.sky.dto.GoodsSalesDTO;
import com.sky.entity.Orders;
import com.sky.entity.User;
import com.sky.mapper.OrderDetailMapper;
import com.sky.mapper.OrderMapper;
import com.sky.mapper.UserMapper;
import com.sky.service.ReportService;
import com.sky.service.WorkSpaceService;
import com.sky.vo.*;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
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
	private WorkSpaceService workSpaceService;
	@Autowired
	private OrderMapper orderMapper;
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
				map -> ((BigDecimal) map.get("turnover")).doubleValue()
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
	
	@Override
	public OrderReportVO getOrderStatistics(LocalDate begin, LocalDate end) {
		// 1. 生成日期列表
		List<LocalDate> dateList = new ArrayList<>();
		LocalDate current = begin;
		while (!current.isAfter(end)) {
			dateList.add(current);
			current = current.plusDays(1);
		}
		// 2. 查询每日订单数和有效订单数
		List<Map> orderStatisticsListMap = orderMapper.getOrderStatisticsByDateRange(LocalDateTime.of(begin, LocalTime.MIN), LocalDateTime.of(end, LocalTime.MAX));
		Map<LocalDate, Integer> orderCountMap = orderStatisticsListMap.stream().collect(Collectors.toMap(
				map -> LocalDate.parse(map.get("date").toString()),
				map -> ((Long) map.get("totalOrderCount")).intValue()
		));
		Map<LocalDate, Integer> validOrderCountMap = orderStatisticsListMap.stream().collect(Collectors.toMap(
				map -> LocalDate.parse(map.get("date").toString()),
				map -> ((Long) map.get("validOrderCount")).intValue()
		));
		// 3. 封装每日订单数据
		List<Integer> orderCountList = new ArrayList<>();
		List<Integer> validOrderCountList = new ArrayList<>();
		for (LocalDate date : dateList) {
			orderCountList.add(orderCountMap.getOrDefault(date, 0));
			validOrderCountList.add(validOrderCountMap.getOrDefault(date, 0));
		}
		// 4. 计算总订单数和总有效订单数
		Integer totalOrderCount = orderCountList.stream().reduce(0, Integer::sum);
		Integer validOrderCount = validOrderCountList.stream().reduce(0, Integer::sum);
		// 5. 计算订单完成率
		Double orderCompletionRate = totalOrderCount == 0 ? 0.0 : validOrderCount.doubleValue() / totalOrderCount;
		// 6. 封装返回结果
		return new OrderReportVO(
				String.join(",", dateList.stream().map(LocalDate::toString).collect(Collectors.toList())),
				String.join(",", orderCountList.stream().map(String::valueOf).collect(Collectors.toList())),
				String.join(",", validOrderCountList.stream().map(String::valueOf).collect(Collectors.toList())),
				totalOrderCount,
				validOrderCount,
				orderCompletionRate
		);
	}
	
	@Override
	public void exportBusinessData(HttpServletResponse response) {
		// 1. 定义时间范围
		LocalDate begin = LocalDate.now().minusDays(30);
		LocalDate end = LocalDate.now().minusDays(1);
		// 2. 查询概览数据
		BusinessDataVO businessData = workSpaceService.getBusinessData(LocalDateTime.of(begin, LocalTime.MIN), LocalDateTime.of(end, LocalTime.MAX)).getData();
		// 3. 创建工作簿
		try (XSSFWorkbook workbook = new XSSFWorkbook()) {
			// 4. 创建工作表
			XSSFSheet sheet = workbook.createSheet("运营数据");
			// 5. 填充数据
			XSSFRow row = sheet.createRow(0);
			row.createCell(0).setCellValue("时间：" + begin + "至" + end);
			row = sheet.createRow(2);
			row.createCell(0).setCellValue("营业额");
			row.createCell(1).setCellValue(businessData.getTurnover());
			row.createCell(3).setCellValue("订单完成率");
			row.createCell(4).setCellValue(businessData.getOrderCompletionRate());
			row.createCell(6).setCellValue("新增用户");
			row.createCell(7).setCellValue(businessData.getNewUsers());
			row = sheet.createRow(3);
			row.createCell(0).setCellValue("有效订单");
			row.createCell(1).setCellValue(businessData.getValidOrderCount());
			row.createCell(3).setCellValue("平均客单价");
			row.createCell(4).setCellValue(businessData.getUnitPrice());
			// 6. 下载文件
			response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
			response.setHeader("Content-Disposition", "attachment;filename=运营数据报表.xlsx");
			workbook.write(response.getOutputStream());
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}
}
