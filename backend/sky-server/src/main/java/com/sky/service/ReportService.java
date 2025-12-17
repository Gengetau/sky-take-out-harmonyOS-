package com.sky.service;

import com.sky.vo.SalesTop10ReportVO;
import java.time.LocalDate;

public interface ReportService {

    /**
     * 查询指定时间区间内的销量排名top10
     * @param begin
     * @param end
     * @return
     */
    SalesTop10ReportVO getSalesTop10(LocalDate begin, LocalDate end);
}
