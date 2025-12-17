package com.sky.service;

import com.sky.vo.SalesTop10ReportVO;
import com.sky.vo.TurnoverReportVO;
import com.sky.vo.UserReportVO;

import java.time.LocalDate;

public interface ReportService {
	
	/**
	 * 查询指定时间区间内的销量排名top10
	 *
	 * @param begin
	 * @param end
	 * @return
	 */
	SalesTop10ReportVO getSalesTop10(LocalDate begin, LocalDate end);
	
	/**
	 * 用户统计
	 *
	 * @param begin
	 * @param end
	 * @return
	 */
	UserReportVO getUserStatistics(LocalDate begin, LocalDate end);
	
	/**
	 * 营业额统计
	 *
	 * @param begin
	 * @param end
	 * @return
	 */
	TurnoverReportVO getTurnoverStatistics(LocalDate begin, LocalDate end);
}
