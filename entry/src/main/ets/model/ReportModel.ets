/**
 * 今日运营数据 VO
 */
export interface BusinessDataVO {
  turnover: number;           // 营业额
  validOrderCount: number;    // 有效订单数
  orderCompletionRate: number;// 订单完成率
  unitPrice: number;          // 平均客单价
  newUsers: number;           // 新增用户数
}

/**
 * 营业额统计 VO
 */
export interface TurnoverReportVO {
  dateList: string;      // 日期列表，逗号分隔 "2023-10-01,2023-10-02"
  turnoverList: string;  // 营业额列表，逗号分隔 "100.0,200.0"
}

/**
 * 订单统计 VO
 */
export interface OrderReportVO {
  dateList: string;
  orderCountList: string;      // 订单总数列表
  validOrderCountList: string; // 有效订单数列表
  totalOrderCount: number;
  validOrderCount: number;
  orderCompletionRate: number;
}
