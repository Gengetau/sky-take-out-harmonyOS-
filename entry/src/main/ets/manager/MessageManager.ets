import { common } from '@kit.AbilityKit';
import { MessageEntity, MessageRdb, SessionModel } from '../common/utils/MessageRdb';
import { WebSocketMessage, WebSocketService } from '../service/WebSocketService';
import { NotificationUtil } from '../common/utils/NotificationUtil';

/**
 * 消息管理器
 * 负责协调 WebSocket 接收消息、RDB 存储以及 UI 通知
 */
export class MessageManager {
  private static instance: MessageManager;
  private userId: number = 0;
  
  // 🐾 当前正在聊天的会话ID (如果在聊天页，就不弹通知了)
  private currentChatSessionId: string | null = null;

  private constructor() {
  }

  public static getInstance(): MessageManager {
    if (!MessageManager.instance ) {
      MessageManager.instance = new MessageManager();
    }
    return MessageManager.instance;
  }

  /**
   * 初始化管理器
   * @param context 应用上下文 (用于 RDB 初始化)
   * @param userId 当前用户ID
   */
  public async init(context: common.UIAbilityContext, userId: number) {
    this.userId = userId;

    // 1. 初始化数据库
    await MessageRdb.init(context);
    
    // 2. 申请通知权限
    await NotificationUtil.requestNotificationPermission(context);

    // 3. 注册 WebSocket 监听器
    const ws = WebSocketService.getInstance();

    // 监听系统通知 (Type 1)
    ws.onMessage(1, (msg): Promise<void> => this.handleIncomingMessage(msg));

    // 监听订单状态 (Type 2)
    ws.onMessage(2, (msg): Promise<void> => this.handleIncomingMessage(msg));

    // 监听私聊消息 (Type 3)
    ws.onMessage(3, (msg): Promise<void> => this.handleIncomingMessage(msg));

    console.info('喵！MessageManager 初始化完成，开始监听消息 📡');
  }

  /**
   * 进入聊天会话 (禁止弹该会话的通知)
   */
  public enterChat(sessionId: string) {
    this.currentChatSessionId = sessionId;
  }

  /**
   * 离开聊天会话 (恢复弹通知)
   */
  public leaveChat() {
    this.currentChatSessionId = null;
  }

  /**
   * 处理收到的 WebSocket 消息
   */
  private async handleIncomingMessage(msg: WebSocketMessage) {
    console.info(`喵！收到新消息: ${ msg.content }`);

    // 1. 构建会话 ID
    let sessionId = "";
    let title = "";
    let avatar = "";

    if (msg.type === 1 || msg.type === 2) {
      sessionId = "system_notify";
      title = "Meow外卖";
      avatar = msg.senderAvatar || "app.media.logo"; 
    } else if (msg.type === 3) {
      sessionId = `shop_${ msg.senderId }`;
      title = msg.senderName || `商家 ${ msg.senderId }`;
      avatar = msg.senderAvatar;
    }

    if (!sessionId ) {
      return;
    }

    // 2. 保存消息明细到 RDB
    const messageEntity: MessageEntity = {
      sessionId: sessionId,
      msgId: msg.msgId,
      senderId: msg.senderId,
      role: 1, // 1 表示对方发的 (接收)
      content: msg.content,
      type: msg.type,
      createTime: msg.timestamp,
      orderId: msg.orderId
    };
    await MessageRdb.saveMessage(messageEntity);

    // 3. 更新会话列表到 RDB
    // 如果当前正处于该会话中，未读数不增加
    const isChatting = (this.currentChatSessionId === sessionId);
    
    const sessionModel: SessionModel = {
      sessionId: sessionId,
      title: title,
      avatar: avatar,
      lastMsg: msg.content,
      lastTime: msg.timestamp,
      unreadCount: isChatting ? 0 : 1 // 新消息增加 1 个未读
    };
    await MessageRdb.saveSession(sessionModel);

    // 4. 通知 UI 更新
    AppStorage.setOrCreate('NewMessageSignal', Date.now());

    // 5. 🔔 发送系统通知 (如果不在当前会话中)
    if (!isChatting) {
      // 简单处理：使用时间戳后4位作为通知ID，避免覆盖
      const notificationId = Math.floor(Date.now() % 10000);
      await NotificationUtil.publishBasicNotification(title, msg.content, notificationId);
    }
  }

  /**
   * 发送消息 (上行)
   */
  public async sendMessage(content: string, receiverId: number, receiverRole: number, receiverName?: string, receiverAvatar?: string): Promise<void> {
    const ws = WebSocketService.getInstance();
    
    // 1. 构造 WS 消息体
    const msg: Partial<WebSocketMessage> = {
      type: 3, // 私聊
      content: content,
      receiverId: receiverId,
      receiverRole: receiverRole
    };
    
    // 2. 发送
    ws.send(msg);

    // 3. 本地存储 (自己发的消息也要存)
    const sessionId = `shop_${receiverId}`; 
    const now = Date.now();

    const messageEntity: MessageEntity = {
      sessionId: sessionId,
      msgId: `local_${now}`, 
      senderId: this.userId,
      role: 0, // 0 表示我自己发的
      content: content,
      type: 3,
      createTime: now
    };
    await MessageRdb.saveMessage(messageEntity);

    // 4. 更新会话 (自己发的消息不增加未读数)
    const sessionModel: SessionModel = {
      sessionId: sessionId,
      title: receiverName || `商家 ${receiverId}`, 
      avatar: receiverAvatar || '', 
      lastMsg: content,
      lastTime: now,
      unreadCount: 0 
    };
    await MessageRdb.saveSession(sessionModel);
    
    // 通知 UI
    AppStorage.setOrCreate('NewMessageSignal', now);
  }
}