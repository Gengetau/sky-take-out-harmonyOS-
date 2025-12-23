import { AddressBook } from '../model/entity/AddressBook';
import { OrderSubmitDTO, OrderSubmitVO } from '../model/api/OrderModel';
import { HttpUtil } from '../common/utils/HttpUtil';

/**
 * 订单服务
 * 负责处理下单、支付、地址查询等逻辑 喵！
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
}
