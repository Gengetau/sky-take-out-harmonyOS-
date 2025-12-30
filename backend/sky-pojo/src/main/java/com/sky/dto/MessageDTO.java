package com.sky.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName MessageDTO
 * @Description websocket消息传递对象
 * @dateTime 29/12/2025 下午1:18
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MessageDTO {
	/**
	 * 消息类型
	 */
	private Integer type;
	
	/**
	 * 消息id,UUID
	 */
	private String msgId;
	
	/**
	 * 发送者ID（O=系统，其他=用户ID/商家ID）
	 */
	private Long senderId;
	
	/**
	 * 接收者ID（O=系统，其他=用户ID/商家ID）
	 */
	private Long receiverId;
	
	/**
	 * 发送者身份 (0:用户, 1:商家, 2:系统)
	 */
	private Integer senderRole;

	/**
	 * 接收者身份 (0:用户, 1:商家, 2:系统)
	 */
	private Integer receiverRole;
	
	/**
	 * 发送者显示名称
	 */
	private String senderName;
	
	/**
	 * 发送者头像url(需要签名)
	 */
	private String senderAvatar;
	
	/**
	 * 消息正文
	 */
	private String content;
	
	/**
	 * 发送时间戳
	 */
	private Long timestamp;
	
	/**
	 * 关联订单id（可选）
	 */
	private Long orderId;
}
