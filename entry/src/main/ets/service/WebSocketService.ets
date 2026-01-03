import { webSocket } from '@kit.NetworkKit';

/**
 * WebSocket 消息协议结构 (对应文档中的 MessageDTO)
 */
export interface WebSocketMessage {
  type: number; // 消息类型 (1:系统通知, 2:订单状态, 3:私聊消息)
  msgId: string; // 消息唯一ID
  senderId: number; // 发送者ID
  senderRole: number; // 发送者身份 (0:用户, 1:商家, 2:系统)
  receiverId: number; // 接收者ID
  receiverRole: number; // 接收者身份 (0:用户, 1:商家)
  senderName: string; // 发送者显示名称
  senderAvatar: string; // 发送者头像 (带签名URL)
  content: string; // 消息正文
  timestamp: number; // 发送时间戳
  orderId?: number; // 关联的订单ID (可选)
}

export interface PingMessage {
  type: number,
  content: string
}

/**
 * WebSocket 服务 (商家版)
 * 负责与后端保持长连接喵！
 */
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private isConnected: boolean = false;
  private shopId: number = 0;
  private listeners: Map<number, (msg: WebSocketMessage) => void> = new Map();
  private heartbeatTimer: number = -1;

  private constructor() {
  }

  public static getInstance(): WebSocketService {
    if (!WebSocketService.instance ) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  /**
   * 注册消息监听器
   */
  public onMessage(type: number, callback: (msg: WebSocketMessage) => void) {
    this.listeners.set(type, callback);
  }

  /**
   * 初始化并连接 WebSocket
   * @param shopId 店铺ID
   */
  public connect(shopId: number) {
    if ( this.isConnected && this.shopId === shopId ) {
      console.info('喵！WebSocket 已经连接了，不用重复连喵。');
      return;
    }
    if ( this.ws ) {
      this.close();
    }

    this.shopId = shopId;
    this.ws = webSocket.createWebSocket();

    // 商家端特有前缀 S_
    const url = `ws://192.168.0.210:8080/ws/S_${ shopId }`;
    console.info(`喵！准备连接 WebSocket: ${ url }`);

    this.ws.connect(url, (err, value) => {
      if (!err ) {
        console.info(`喵！WebSocket 连接成功 🎉`);
        this.isConnected = true;
        this.setupListeners();
        this.startHeartbeat();
      } else {
        console.error(`喵！！！WebSocket 连接失败 😭: ${ JSON.stringify(err) }`);
        this.isConnected = false;
      }
    });
  }

  private setupListeners() {
    if (!this.ws ) {
      return;
    }

    this.ws.on('open', (err, value) => {
      console.info('喵！WebSocket onOpen 事件触发喵');
    });

    this.ws.on('message', (err, value) => {
      if (!err ) {
        const messageStr = value as string;
        // console.info(`喵！收到 WS 原始消息: ${messageStr}`);

        // 忽略 PONG
        if ( messageStr === 'PONG' ) {
          return;
        }

        try {
          const msgObj = JSON.parse(messageStr) as WebSocketMessage;
          // console.info(`喵！解析成功: [${msgObj.senderName}] -> ${msgObj.content}`);

          if ( msgObj && msgObj.type ) {
            const callback = this.listeners.get(msgObj.type);
            if ( callback ) {
              callback(msgObj);
            }
          }
        } catch ( e ) {
          console.error('喵！WS 消息解析失败:', e);
        }
      }
    });

    this.ws.on('close', (err, value) => {
      console.warn(`喵！WebSocket 连接断开 🔌`);
      this.isConnected = false;
      this.ws = null;
      this.stopHeartbeat();
    });

    this.ws.on('error', (err) => {
      console.error('喵！WebSocket 发生错误 ❌:', JSON.stringify(err));
      this.isConnected = false;
    });
  }

  public send(msg: Partial<WebSocketMessage>) {
    if ( this.ws && this.isConnected ) {
      const msgStr = JSON.stringify(msg);
      this.ws.send(msgStr);
    }
  }

  private startHeartbeat() {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      if ( this.isConnected && this.ws ) {
        // 修改为 JSON 格式的心跳包，以兼容后端 MessageDispatcher
        const heartbeatMsg: PingMessage = {
          type: 0,
          content: 'PING'
        };
        this.ws.send(JSON.stringify(heartbeatMsg));
      }
    }, 30000);
  }

  private stopHeartbeat() {
    if ( this.heartbeatTimer !== -1 ) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  public close() {
    if ( this.ws ) {
      this.ws.close();
      this.ws = null;
      this.isConnected = false;
      this.stopHeartbeat();
    }
  }
}
