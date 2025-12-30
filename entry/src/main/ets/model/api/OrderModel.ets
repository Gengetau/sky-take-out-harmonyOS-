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
 * 喵！现在支持多商店了，必须带上 shopId 哦！
 */
export interface OrderSubmitDTO {
  shopId: number; // 🏢 所属商家ID (新增)
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

/**
 * 📜 订单详情 VO
 */
export interface OrderDetailVO {
  name: string;
  image?: string; // ✨ 商品图片 (新增)
  number: number;
  amount: number;
}

/**
 * 📦 历史订单 VO (API 7.3)
 */
export interface OrderVO {
  id: number;
  number: string; // 订单号
  shopId: number; // 🏢 店铺ID (新增，用于跳转)
  shopName?: string; // 🏢 店铺名称
  status: number; // 1:待付款, 2:待接单, 3:已接单, 4:派送中, 5:已完成, 6:已取消
  amount: number; // 订单金额
  orderTime: string; // 下单时间
  orderDetailList: OrderDetailVO[]; // 订单详情明细
}

/**
 * 📄 分页查询结果包装类
 */
export interface PageResult<T> {
  total: number;
  records: T[];
}

/**
 * ❌ 取消订单 DTO (API 7.6)
 */
export class OrderCancelDTO {
  id: number;
  cancelReason?: string;

  constructor(id: number, cancelReason?: string) {
    this.id = id;
    this.cancelReason = cancelReason;
  }
}