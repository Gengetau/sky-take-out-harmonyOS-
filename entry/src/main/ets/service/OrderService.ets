import { AddressBook } from '../model/entity/AddressBook';
import { OrderSubmitDTO, OrderSubmitVO, OrderPaymentDTO, OrderPaymentVO, OrderVO, PageResult, OrderCancelDTO } from '../model/api/OrderModel';
import { HttpUtil } from '../common/utils/HttpUtil';

/**
 * 订单服务
 * 负责处理下单、支付、地址查询以及历史订单查询逻辑 喵！
 */
export class OrderService {
  
  /**
   * 获取默认收货地址
   */
  static async getDefaultAddress(): Promise<AddressBook | null> {
    try {
      return await HttpUtil.get<AddressBook>('/client/addressBook/default');
    } catch (e) {
      console.warn('喵！获取默认地址失败或无默认地址:', e);
      return null;
    }
  }

  /**
   * 获取当前用户的所有地址
   */
  static async getAddressList(): Promise<AddressBook[]> {
    return HttpUtil.get<AddressBook[]>('/client/addressBook/list');
  }

  /**
   * 新增地址
   * @param address 地址信息
   */
  static async addAddress(address: AddressBook): Promise<string> {
    return HttpUtil.post<string>('/client/addressBook', address);
  }

  /**
   * 设置默认地址
   * @param id 地址ID
   */
  static async setDefaultAddress(id: number): Promise<string> {
    return HttpUtil.put<string>(`/client/addressBook/default/${id}`);
  }

  /**
   * 删除地址
   * @param id 地址ID
   */
  static async deleteAddress(id: number): Promise<string> {
    return HttpUtil.delete<string>(`/client/addressBook?id=${id}`);
  }

  /**
   * 根据ID查询地址
   * @param id 地址ID
   */
  static async getAddressById(id: number): Promise<AddressBook> {
    return HttpUtil.get<AddressBook>(`/client/addressBook/${id}`);
  }

  /**
   * 修改地址
   * @param address 地址信息
   */
  static async updateAddress(address: AddressBook): Promise<string> {
    return HttpUtil.put<string>('/client/addressBook', address);
  }

  /**
   * 提交订单
   * @param submitDTO 订单提交信息
   */
  static async submitOrder(submitDTO: OrderSubmitDTO): Promise<OrderSubmitVO> {
    return HttpUtil.post<OrderSubmitVO>('/client/order/submit', submitDTO);
  }

  /**
   * 订单支付 (获取二维码)
   * @param paymentDTO 支付信息
   */
  static async payment(paymentDTO: OrderPaymentDTO): Promise<OrderPaymentVO> {
    return HttpUtil.put<OrderPaymentVO>('/client/order/payment', paymentDTO);
  }

  /**
   * 🔍 主动查询支付状态 (API 7.4)
   * @param orderNumber 订单号
   */
  static async checkPayStatus(orderNumber: string): Promise<string> {
    return HttpUtil.get<string>(`/client/order/checkPayStatus/${orderNumber}`);
  }

  /**
   * 📦 查询订单详情 (API 7.5)
   * @param id 订单ID
   */
  static async getOrderDetail(id: number): Promise<OrderVO> {
    return HttpUtil.get<OrderVO>(`/client/order/orderDetail/${id}`);
  }

  /**
   * ❌ 取消订单 (API 7.6)
   * @param cancelDTO 取消信息
   */
  static async cancelOrder(cancelDTO: OrderCancelDTO): Promise<string> {
    return HttpUtil.put<string>('/client/order/cancel', cancelDTO);
  }

  /**
   * 📜 分页查询历史订单 (API 7.3)
   * @param page 页码
   * @param pageSize 每页记录数
   * @param status 订单状态 (可选)
   */
  static async getHistoryOrders(page: number, pageSize: number, status?: number): Promise<PageResult<OrderVO>> {
    let url = `/client/order/historyOrders?page=${page}&pageSize=${pageSize}`;
    if (status !== undefined) {
      url += `&status=${status}`;
    }
    return HttpUtil.get<PageResult<OrderVO>>(url);
  }
}