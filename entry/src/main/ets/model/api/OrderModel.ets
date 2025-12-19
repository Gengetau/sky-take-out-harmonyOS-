
/**
 * 订单提交参数 DTO
 * 喵！告诉后端我们要点什么好吃的！
 */
export interface OrderSubmitDTO {
  addressBookId: number;
  payMethod: number; // 1微信 2支付宝
  remark: string;
  estimatedDeliveryTime: string; // 预计送达时间 00:00:00
  deliveryStatus: number; // 1立即送出
  packAmount: number; // 打包费
  tablewareNumber: number; // 餐具数量
  tablewareStatus: number; // 1按餐量提供
  amount: number; // 总金额
}

/**
 * 订单返回结果 VO
 * 喵！下单成功后后端给我们的回执！
 */
export interface OrderSubmitVO {
  id: number;
  orderTime: string;
  orderAmount: number;
  orderNumber: string; // 订单号
}

/**
 * 支付返回结果 VO
 */
export interface OrderPaymentVO {
  nonceStr: string;
  paySign: string;
  timeStamp: string;
  signType: string;
  packageStr: string;
}
