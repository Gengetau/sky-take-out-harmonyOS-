package com.sky.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class OrdersSubmitDTO implements Serializable {
	// 店铺ID
	private Long shopId;
	// 地址簿id
	private Long addressBookId;
	// 付款方式
	private int payMethod;
	// 备注
	private String remark;
	// 预计送达时间
	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
	private LocalDateTime estimatedDeliveryTime;
	// 配送状态  1立即送出  0选择具体时间
	private Integer deliveryStatus;
	// 餐具数量
	private Integer tablewareNumber;
	// 餐具数量状态  1按餐量提供  0选择具体数量
	private Integer tablewareStatus;
	// 打包费
	private Integer packAmount;
	// 总金额
	private BigDecimal amount;
	
	// 购物车明细列表
	private List<CartItem> cartItems;
	
	@Data
	public static class CartItem implements Serializable {
		private Long dishId;
		private Long setmealId;
		private String dishFlavor;
		private Integer number;
		private BigDecimal amount; // 单价或总价，后端校验时可重新计算
		private String name;
		private String image;
	}
}
