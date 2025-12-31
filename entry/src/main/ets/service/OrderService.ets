import { HttpUtil } from '../common/HttpUtil';
import { OrderVO, PageResult, OrderRejectionDTO, OrderConfirmDTO } from '../model/OrderModel';

/**
 * 商家端订单服务
 * 接口前缀继承自 HttpUtil 的 /admin/app
 */
export class OrderService {
  /**
   * 订单搜索/列表
   * @param page 页码
   * @param pageSize 每页条数
   * @param status 订单状态 (可选)
   */
  static async conditionSearch(page: number, pageSize: number, status?: number): Promise<PageResult<OrderVO>> {
    let url = `/order/conditionSearch?page=${page}&pageSize=${pageSize}`;
    if (status !== undefined && status !== 0) {
      url += `&status=${status}`;
    }
    return HttpUtil.get<PageResult<OrderVO>>(url);
  }

  /**
   * 订单统计 (待接单、待派送、派送中数量)
   */
  static async getStatistics(): Promise<Record<string, number>> {
    return HttpUtil.get<Record<string, number>>('/order/statistics');
  }

  /**
   * 接单
   */
  static async confirm(id: number): Promise<void> {
    return HttpUtil.put<void>('/order/confirm', new OrderConfirmDTO(id));
  }

  /**
   * 拒单
   */
  static async rejection(dto: OrderRejectionDTO): Promise<void> {
    return HttpUtil.put<void>('/order/rejection', dto);
  }

  /**
   * 取消订单
   */
  static async cancel(dto: OrderRejectionDTO): Promise<void> {
    return HttpUtil.put<void>('/order/cancel', dto);
  }

  /**
   * 派送订单
   * @param id 订单ID
   */
  static async delivery(id: number): Promise<void> {
    return HttpUtil.put<void>(`/order/delivery/${id}`);
  }

  /**
   * 完成订单
   * @param id 订单ID
   */
  static async complete(id: number): Promise<void> {
    return HttpUtil.put<void>(`/order/complete/${id}`);
  }

  /**
   * 获取订单详情
   * @param id 订单ID
   */
  static async getDetails(id: number): Promise<OrderVO> {
    return HttpUtil.get<OrderVO>(`/order/details/${id}`);
  }
}