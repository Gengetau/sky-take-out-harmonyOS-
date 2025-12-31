/**
 * 订单详情明细
 */
export interface OrderDetailVO {
  name: string;
  image?: string;
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
  amount: number;
  orderTime: string;
  userName?: string; // 下单用户
  address?: string; // 送餐地址
  phone?: string; // 用户手机号
  remark?: string; // 备注
  orderDetailList: OrderDetailVO[];
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
  rejectionReason: string;

  constructor(id: number, reason: string) {
    this.id = id;
    this.rejectionReason = reason;
  }
}

/**
 * 接单 DTO
 */
export interface OrderConfirmDTO {
  id: number;
  status: number;
}
