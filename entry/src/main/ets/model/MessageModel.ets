/**
 * 基础消息模型 (对应协议 3.1)
 */
export interface MessageDTO {
  msgId: string;
  type: number;        // 1:系统, 2:订单, 3:私聊
  content: string;
  orderId?: number;
  senderId: number;
  senderRole: number;  // 0:用户, 1:商家, 2:系统
  senderName: string;
  senderAvatar?: string;
  receiverId: number;
  receiverRole: number;
  timestamp: number;
}

/**
 * 会话模型 (用于列表展示)
 */
export class SessionModel {
  sessionId: string;
  title: string;
  avatar: string | Resource;
  lastMsg: string;
  lastTime: number;
  unreadCount: number;

  constructor(sessionId: string, title: string, avatar: string | Resource, lastMsg: string, lastTime: number, unreadCount: number) {
    this.sessionId = sessionId;
    this.title = title;
    this.avatar = avatar;
    this.lastMsg = lastMsg;
    this.lastTime = lastTime;
    this.unreadCount = unreadCount;
  }
}

/**
 * 消息类型常量
 */
export class MessageConstant {
  static readonly SYSTEM_NOTIFICATION = 1;
  static readonly ORDER_NOTIFICATION = 2;
  static readonly PRIVATE_MESSAGE = 3;
}