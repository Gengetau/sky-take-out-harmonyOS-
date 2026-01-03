import { common } from '@kit.AbilityKit';
import { MessageEntity, MessageRdb } from '../common/MessageRdb';
import { SessionModel, MessageConstant } from '../model/MessageModel';
import { WebSocketMessage, WebSocketService } from '../service/WebSocketService';

/**
 * 消息管理器 (商家端)
 * 负责协调 WebSocket 接收消息、RDB 存储以及 UI 通知
 */
export class MessageManager {
  private static instance: MessageManager;
  private shopId: number = 0;
  
  // 🐾 当前正在聊天的会话ID (暂未实现聊天页，预留)
  private currentChatSessionId: string | null = null;

  private constructor() {}

  public static getInstance(): MessageManager {
    if (!MessageManager.instance) {
      MessageManager.instance = new MessageManager();
    }
    return MessageManager.instance;
  }

  /**
   * 初始化管理器
   * @param context 应用上下文 (用于 RDB 初始化)
   * @param shopId 当前店铺ID
   */
  public async init(context: common.UIAbilityContext, shopId: number) {
    this.shopId = shopId;

    // 1. 初始化数据库
    await MessageRdb.init(context);
    
    // 2. 注册 WebSocket 监听器
    const ws = WebSocketService.getInstance();
    
    // 先连接
    ws.connect(shopId);

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
    console.info(`喵！收到新消息: ${msg.content}`);

    // 1. 构建会话 ID
    let sessionId = "";
    let title = "";
    let avatar = "";

    // 商家端的逻辑：
    // 系统/订单通知 -> system_notify
    // 私聊 -> user_{senderId}
    if (msg.type === MessageConstant.SYSTEM_NOTIFICATION || msg.type === MessageConstant.ORDER_NOTIFICATION) {
      sessionId = "system_notify";
      title = "系统通知";
      // 如果没有头像，使用默认logo (UI层处理)
      avatar = msg.senderAvatar || ""; 
    } else if (msg.type === MessageConstant.PRIVATE_MESSAGE) {
      sessionId = `user_${msg.senderId}`; // 商家端收到的私聊是来自用户的
      title = msg.senderName || `用户 ${msg.senderId}`;
      avatar = msg.senderAvatar || "";
    }

    if (!sessionId) {
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
    const isChatting = (this.currentChatSessionId === sessionId);
    
    // 构造 SessionModel (注意：SessionModel 的构造函数参数顺序)
    // constructor(sessionId: string, title: string, avatar: string | Resource, lastMsg: string, lastTime: number, unreadCount: number)
    const sessionModel = new SessionModel(
      sessionId,
      title,
      avatar,
      msg.content,
      msg.timestamp,
      isChatting ? 0 : 1 // 新消息增加 1 个未读
    );
    await MessageRdb.saveSession(sessionModel);

    // 4. 通知 UI 更新消息列表
    AppStorage.setOrCreate('NewMessageSignal', Date.now());

    // 5. 特殊处理：订单通知 -> 触发全局弹窗
    if (msg.type === MessageConstant.ORDER_NOTIFICATION) {
        console.info('喵！检测到新订单消息，准备弹窗！');
        AppStorage.setOrCreate('NewOrderMessage', msg);
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
    const sessionId = `user_${receiverId}`; // 发给用户
    const now = Date.now();

    const messageEntity: MessageEntity = {
      sessionId: sessionId,
      msgId: `local_${now}`, 
      senderId: this.shopId, // 发送者是自己 (店铺ID)
      role: 0, // 0 表示我自己发的
      content: content,
      type: 3,
      createTime: now
    };
    await MessageRdb.saveMessage(messageEntity);

    // 4. 更新会话
    const sessionModel = new SessionModel(
      sessionId,
      receiverName || `用户 ${receiverId}`, 
      receiverAvatar || '', 
      content,
      now,
      0 // 自己发的不用未读数
    );
    await MessageRdb.saveSession(sessionModel);
    
    // 通知 UI
    AppStorage.setOrCreate('NewMessageSignal', now);
  }
  
  /**
   * 断开连接
   */
  public disconnect() {
    WebSocketService.getInstance().close();
  }
}
