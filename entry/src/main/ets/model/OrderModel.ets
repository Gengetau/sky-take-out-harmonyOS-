/**
 * 订单详情明细
 */
export interface OrderDetailVO {
  id: number;
  name: string;
  image?: string;
  orderId: number;
  dishId?: number;
  setmealId?: number;
  dishFlavor?: string; // 口味
  number: number;
  amount: number;
}

/**
 * 商家端订单 VO
 * 状态定义: 1:待付款, 2:待接单, 3:已接单, 4:派送中, 5:已完成, 6:已取消
 */
export interface OrderVO {
  id: number;
  number: string;
  status: number;
  amount: number; // 总金额
  orderTime: string;
  checkoutTime?: string;
  payMethod: number; // 支付方式 1微信,2支付宝
  payStatus: number; // 支付状态 0未支付 1已支付 2退款
  
  // 用户信息
  userId: number;
  userName?: string; 
  phone?: string; 
  address?: string; 
  consignee?: string; // 收货人
  sex?: string; // 用户性别
  
  // 费用相关
  packAmount?: number; // 打包费
  tablewareNumber?: number; // 餐具数量
  tablewareStatus?: number; // 餐具状态
  
  remark?: string; // 备注
  cancelReason?: string;
  rejectionReason?: string;
  deliveryTime?: string; // 预计送达时间
  
  orderDetailList: OrderDetailVO[];
  
  // 店铺信息（可选）
  shopId?: number;
  shopName?: string;
}

/**
 * 分页查询结果
 */
export interface PageResult<T> {
  total: number;
  records: T[];
}

/**
 * 拒单/取消订单 DTO
 */
export class OrderRejectionDTO {
  id: number;
  rejectionReason?: string; // 拒单原因
  cancelReason?: string;    // 取消原因 (复用此类)

  constructor(id: number, reason: string) {
    this.id = id;
    this.rejectionReason = reason;
    this.cancelReason = reason;
  }
}

/**
 * 接单 DTO
 */
export class OrderConfirmDTO {
  id: number;

  constructor(id: number) {
    this.id = id;
  }
}
