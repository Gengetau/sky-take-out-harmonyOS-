import { common } from '@kit.AbilityKit';
import { MessageEntity, MessageRdb, SessionModel } from '../common/utils/MessageRdb';
import { WebSocketMessage, WebSocketService } from '../service/WebSocketService';

/**
 * 消息管理器
 * 负责协调 WebSocket 接收消息、RDB 存储以及 UI 通知
 */
export class MessageManager {
  private static instance: MessageManager;
  private userId: number = 0;

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

    // 2. 注册 WebSocket 监听器
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
   * 处理收到的 WebSocket 消息
   */
  private async handleIncomingMessage(msg: WebSocketMessage) {
    console.info(`喵！收到新消息: ${ msg.content }`);

    // 1. 构建会话 ID
    // 规则：
    // - 系统消息: "system_notify"
    // - 私聊消息: "user_{otherId}" (如果是商家发给用户，otherId就是商家ID)
    let sessionId = "";
    let title = "";
    let avatar = "";

        if (msg.type === 1 || msg.type === 2) {

          sessionId = "system_notify";

          title = "Meow外卖"; // ✨ 改为 Meow外卖

          // 使用默认系统头像或从消息中获取

          avatar = msg.senderAvatar || "app.media.logo"; // 这里暂时用本地资源占位，实际需处理网络图片

        } else if (msg.type === 3) {
      // 假设当前是用户端，收到的肯定是商家或骑手发的
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
      orderId: msg.orderId // ✨ 存入 orderId
    };
    await MessageRdb.saveMessage(messageEntity);

    // 3. 更新会话列表到 RDB
    const sessionModel: SessionModel = {
      sessionId: sessionId,
      title: title,
      avatar: avatar,
      lastMsg: msg.content,
      lastTime: msg.timestamp,
      unreadCount: 1 // 新消息增加 1 个未读
    };
    await MessageRdb.saveSession(sessionModel);

    // 4. 通知 UI 更新
    // 使用 AppStorage 发布事件，MessagePage 可以监听这个变量的变化来刷新列表
    AppStorage.setOrCreate('NewMessageSignal', Date.now());

    // 全局未读数通知 (可选)
    // AppStorage.setOrCreate('GlobalUnreadCount', ...);
  }

    /**

     * 发送消息 (上行)

     * @param content 内容

     * @param receiverId 接收者ID

     * @param receiverRole 接收者角色

     * @param receiverName 接收者名称 (用于本地会话显示)

     * @param receiverAvatar 接收者头像 (用于本地会话显示)

     */

    public async sendMessage(content: string, receiverId: number, receiverRole: number, receiverName?: string, receiverAvatar?: string): Promise<void> {

      const ws = WebSocketService.getInstance();

      

      // 1. 构造 WS 消息体

      const msg: Partial<WebSocketMessage> = {

        type: 3, // 私聊

        content: content,

        receiverId: receiverId,

        receiverRole: receiverRole

        // 其他字段由后端填充

      };

      

      // 2. 发送

      ws.send(msg);

  

      // 3. 本地存储 (自己发的消息也要存)

      const sessionId = `shop_${receiverId}`; // 假设是发给商家

      const now = Date.now();

  

      const messageEntity: MessageEntity = {

        sessionId: sessionId,

        msgId: `local_${now}`, // 本地临时ID

        senderId: this.userId,

        role: 0, // 0 表示我自己发的

        content: content,

        type: 3,

        createTime: now

      };

      await MessageRdb.saveMessage(messageEntity);

  

      // 4. 更新会话 (自己发的消息不增加未读数)

      // ✨ 使用传入的名称和头像，如果没传则回退到默认

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
