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
   * TODO: 暂时返回 Mock 数据，等后端接口 ready 了再对接 喵！
   */
  static async getDefaultAddress(): Promise<AddressBook> {
    // 模拟网络延迟
    await new Promise<void>(resolve => setTimeout(resolve, 500));

    return {
      id: 1,
      consignee: '妮娅Master',
      phone: '13800138000',
      sex: '1',
      provinceCode: '110000',
      provinceName: '北京市',
      cityCode: '110100',
      cityName: '北京市',
      districtCode: '110101',
      districtName: '东城区',
      detail: '喵喵大街1号院 天空之城 8-808',
      label: '家',
      isDefault: 1
    };
  }

  /**
   * 提交订单
   * @param submitDTO 订单提交信息
   */
  static async submitOrder(submitDTO: OrderSubmitDTO): Promise<OrderSubmitVO> {
    // TODO: 暂时 Mock 提交成功 喵！
    // 真实调用: return HttpUtil.post<OrderSubmitVO>('/client/order/submit', submitDTO);
    
    await new Promise<void>(resolve => setTimeout(resolve, 1000));

    return {
      id: 123456789,
      orderTime: new Date().toLocaleString(),
      orderAmount: submitDTO.amount,
      orderNumber: 'ORDER_' + Date.now()
    };
  }
}
