import { common } from '@kit.AbilityKit';
import { MessageEntity, MessageRdb } from '../common/MessageRdb';
import { SessionModel, MessageConstant } from '../model/MessageModel';
import { WebSocketMessage, WebSocketService } from '../service/WebSocketService';

/**
 * 消息管理器 (商家端 - 隔离版)
 */
export class MessageManager {
  private static instance: MessageManager;
  private shopId: number = 0;
  private currentChatSessionId: string | null = null;

  private constructor() {}

  public static getInstance(): MessageManager {
    if (!MessageManager.instance) {
      MessageManager.instance = new MessageManager();
    }
    return MessageManager.instance;
  }

  public async init(context: common.UIAbilityContext, shopId: number) {
    this.shopId = shopId;
    await MessageRdb.init(context);
    const ws = WebSocketService.getInstance();
    ws.connect(shopId);

    ws.onMessage(1, (msg): Promise<void> => this.handleIncomingMessage(msg));
    ws.onMessage(2, (msg): Promise<void> => this.handleIncomingMessage(msg));
    ws.onMessage(3, (msg): Promise<void> => this.handleIncomingMessage(msg));

    console.info('喵！MessageManager 初始化完成 (ShopId: ' + shopId + ')');
  }

  public enterChat(sessionId: string) {
    this.currentChatSessionId = sessionId;
  }

  public leaveChat() {
    this.currentChatSessionId = null;
  }

  private async handleIncomingMessage(msg: WebSocketMessage) {
    let sessionId = "";
    let title = "";
    let avatar = "";

    if (msg.type === MessageConstant.SYSTEM_NOTIFICATION || msg.type === MessageConstant.ORDER_NOTIFICATION) {
      sessionId = "system_notify";
      title = "系统通知";
      avatar = msg.senderAvatar || ""; 
    } else if (msg.type === MessageConstant.PRIVATE_MESSAGE) {
      sessionId = `user_${msg.senderId}`;
      title = msg.senderName || `用户 ${msg.senderId}`;
      avatar = msg.senderAvatar || "";
    }

    if (!sessionId) return;

    // 🐾 存储带上 shopId
    const messageEntity: MessageEntity = {
      shopId: this.shopId,
      sessionId: sessionId,
      msgId: msg.msgId,
      senderId: msg.senderId,
      role: 1,
      content: msg.content,
      type: msg.type,
      createTime: msg.timestamp,
      orderId: msg.orderId
    };
    await MessageRdb.saveMessage(messageEntity);

    const isChatting = (this.currentChatSessionId === sessionId);
    const sessionModel = new SessionModel(
      sessionId,
      title,
      avatar,
      msg.content,
      msg.timestamp,
      isChatting ? 0 : 1
    );
    await MessageRdb.saveSession(this.shopId, sessionModel);

    AppStorage.setOrCreate('NewMessageSignal', Date.now());

    if (msg.type === MessageConstant.ORDER_NOTIFICATION) {
        AppStorage.setOrCreate('NewOrderMessage', msg);
    }
  }

  public async sendMessage(content: string, receiverId: number, receiverRole: number, receiverName?: string, receiverAvatar?: string): Promise<void> {
    const ws = WebSocketService.getInstance();
    const msg: Partial<WebSocketMessage> = {
      type: 3,
      content: content,
      receiverId: receiverId,
      receiverRole: receiverRole
    };
    ws.send(msg);

    const sessionId = `user_${receiverId}`;
    const now = Date.now();

    // 🐾 存储带上 shopId
    const messageEntity: MessageEntity = {
      shopId: this.shopId,
      sessionId: sessionId,
      msgId: `local_${now}`, 
      senderId: this.shopId,
      role: 0,
      content: content,
      type: 3,
      createTime: now
    };
    await MessageRdb.saveMessage(messageEntity);

    const sessionModel = new SessionModel(
      sessionId,
      receiverName || `用户 ${receiverId}`, 
      receiverAvatar || '', 
      content,
      now,
      0
    );
    await MessageRdb.saveSession(this.shopId, sessionModel);
    
    AppStorage.setOrCreate('NewMessageSignal', now);
  }
  
  public disconnect() {
    WebSocketService.getInstance().close();
  }
}