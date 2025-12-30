package com.sky.constant;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName WebSocketConstant
 * @Description websocket常量类
 * @dateTime 29/12/2025 下午1:26
 */
public class WebSocketConstant {
	// 消息类型
	/**
	 * 系统通知 | 支付成功、退款通知、活动推送
	 */
	public static final Integer SYSTEM_NOTIFICATION = 1;
	/**
	 * 订单状态 | 商家接单、骑手接单、订单送达
	 */
	public static final Integer ORDER_NOTIFICATION = 2;
	/**
	 * 私聊消息 | 用户与商家沟通、用户与骑手沟通
	 */
	public static final Integer PRIVATE_MESSAGE = 3;
	
	/**
	 * senderId(系统)
	 */
	public static final Integer SYSTEM_SID = 0;
	/**
	 * senderName(系统)
	 */
	public static final String SYSTEM_NAME = "Meow外卖";
	/**
	 * senderAvatar(系统)
	 */
	public static final String SYSTEM_AVATAR = "698f7f2074f04165b60ad43a3fb67802.png";
	
	
	// 系统推送信息
		/**
		 * 订单支付成功
		 */
		public static final String ORDER_PAY_SUCCESS = "订单支付成功";
		/**
		 * 商家已接单
		 */
		public static final String ORDER_CONFIRMED = "商家已接单，正在准备中喵";
		/**
		 * 商家已拒单
		 */
		public static final String ORDER_REJECTION = "商家已拒单";
		/**
		 * 订单派送中
		 */
		public static final String ORDER_DELIVERY = "您的订单正在派送中喵";
		/**
		 * 订单已送达
		 */
		public static final String ORDER_COMPLETED = "订单已送达，祝您用餐愉快喵";
		
		
		// 身份类型
	/**
	 * 身份：用户
	 */
	public static final Integer ROLE_USER = 0;
	/**
	 * 身份：商家
	 */
	public static final Integer ROLE_SHOP = 1;
	/**
	 * 身份：系统
	 */
	public static final Integer ROLE_SYSTEM = 2;
	
}
