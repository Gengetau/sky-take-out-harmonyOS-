import { HttpUtil } from '../common/HttpUtil';
import { BusinessDataVO, OrderReportVO, TurnoverReportVO } from '../model/ReportModel';

export class ReportService {
  /**
   * 获取今日运营数据
   */
  static async getBusinessData(): Promise<BusinessDataVO> {
    const data = await HttpUtil.get<BusinessDataVO>('/report/businessData');
    console.info('喵！[ReportService] getBusinessData 响应数据:', JSON.stringify(data));
    return data;
  }

  /**
   * 获取营业额统计
   * @param begin 开始日期 yyyy-MM-dd
   * @param end 结束日期 yyyy-MM-dd
   */
  static async getTurnoverStatistics(begin: string, end: string): Promise<TurnoverReportVO> {
    const data = await HttpUtil.get<TurnoverReportVO>(`/report/turnoverStatistics?begin=${begin}&end=${end}`);
    console.info('喵！[ReportService] getTurnoverStatistics 响应数据:', JSON.stringify(data));
    return data;
  }

  /**
   * 获取订单统计
   * @param begin 开始日期 yyyy-MM-dd
   * @param end 结束日期 yyyy-MM-dd
   */
  static async getOrderStatistics(begin: string, end: string): Promise<OrderReportVO> {
    const data = await HttpUtil.get<OrderReportVO>(`/report/ordersStatistics?begin=${begin}&end=${end}`);
    console.info('喵！[ReportService] getOrderStatistics 响应数据:', JSON.stringify(data));
    return data;
  }
}