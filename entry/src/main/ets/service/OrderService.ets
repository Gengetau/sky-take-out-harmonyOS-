import { HttpUtil } from '../common/HttpUtil';
import { OrderVO, PageResult, OrderRejectionDTO, OrderConfirmDTO } from '../model/OrderModel';

export class OrderService {
  /**
   * 订单搜索/列表
   * @param page 页码
   * @param pageSize 每页条数
   * @param status 订单状态 (可选)
   */
  static async conditionSearch(page: number, pageSize: number, status?: number): Promise<PageResult<OrderVO>> {
    let url = `/admin/order/conditionSearch?page=${page}&pageSize=${pageSize}`;
    if (status !== undefined && status !== 0) {
      url += `&status=${status}`;
    }
    return HttpUtil.get<PageResult<OrderVO>>(url);
  }

  /**
   * 接单
   */
  static async confirm(dto: OrderConfirmDTO): Promise<void> {
    return HttpUtil.put<void>('/admin/order/confirm', dto);
  }

  /**
   * 拒单
   */
  static async rejection(dto: OrderRejectionDTO): Promise<void> {
    return HttpUtil.put<void>('/admin/order/rejection', dto);
  }

  /**
   * 取消订单 (商家版)
   */
  static async cancel(dto: OrderRejectionDTO): Promise<void> {
    return HttpUtil.put<void>('/admin/order/cancel', dto);
  }

  /**
   * 派送订单
   * @param id 订单ID
   */
  static async delivery(id: number): Promise<void> {
    return HttpUtil.put<void>(`/admin/order/delivery/${id}`);
  }

  /**
   * 完成订单
   * @param id 订单ID
   */
  static async complete(id: number): Promise<void> {
    return HttpUtil.put<void>(`/admin/order/complete/${id}`);
  }

  /**
   * 获取订单详情
   * @param id 订单ID
   */
  static async getDetails(id: number): Promise<OrderVO> {
    return HttpUtil.get<OrderVO>(`/admin/order/details/${id}`);
  }
}
