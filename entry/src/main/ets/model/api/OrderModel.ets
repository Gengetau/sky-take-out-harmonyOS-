
/**
 * 购物车明细 DTO
 */
export interface CartItemDTO {
  dishId?: number; // 菜品ID (可选)
  setmealId?: number; // 套餐ID (可选)
  dishFlavor?: string; // 口味
  number: number; // 数量
  amount: number; // 单价
  name?: string; // 名称 (可选)
  image?: string; // 图片 (可选)
}

/**
 * 订单提交参数 DTO
 * 喵！告诉后端我们要点什么好吃的！
 */
export interface OrderSubmitDTO {
  addressBookId: number;
  payMethod: number; // 1微信 2支付宝
  remark: string;
  estimatedDeliveryTime: string; // 预计送达时间 格式: yyyy-MM-dd HH:mm:ss
  deliveryStatus: number; // 1立即送出, 0选择具体时间
  packAmount: number; // 打包费
  tablewareNumber: number; // 餐具数量
  tablewareStatus: number; // 1按餐量提供, 0选择具体数量
  amount: number; // 总金额
  cartItems: CartItemDTO[]; // 购物车明细
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
 * 支付提交 DTO
 */
export interface OrderPaymentDTO {
  orderNumber: string;
  payMethod: number;
}

/**
 * 支付返回结果 VO
 */
export interface OrderPaymentVO {
  qrCode: string; // 支付宝支付二维码链接
}
