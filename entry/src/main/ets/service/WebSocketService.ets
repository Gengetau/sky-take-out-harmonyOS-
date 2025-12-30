import { webSocket } from '@kit.NetworkKit';

/**
 * WebSocket 消息协议结构 (对应文档中的 MessageDTO)
 */
export interface WebSocketMessage {
  type: number;         // 消息类型 (1:系统通知, 2:订单状态, 3:私聊消息)
  msgId: string;        // 消息唯一ID
  senderId: number;     // 发送者ID
  senderRole: number;   // 发送者身份 (0:用户, 1:商家, 2:系统)
  receiverId: number;   // 接收者ID
  receiverRole: number; // 接收者身份 (0:用户, 1:商家)
  senderName: string;   // 发送者显示名称
  senderAvatar: string; // 发送者头像 (带签名URL)
  content: string;      // 消息正文
  timestamp: number;    // 发送时间戳
  orderId?: number;     // 关联的订单ID (可选)
}

/**
 * WebSocket 服务
 * 负责与后端保持长连接，接收实时消息（如支付成功通知、私聊等）喵！
 */
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private isConnected: boolean = false;
  private userId: number = 0;
  // 简单的事件监听器：type -> callback
  private listeners: Map<number, (msg: WebSocketMessage) => void> = new Map();

  private constructor() {
  }

  public static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  /**
   * 注册消息监听器
   * @param type 消息类型
   * @param callback 回调函数
   */
  public onMessage(type: number, callback: (msg: WebSocketMessage) => void) {
    this.listeners.set(type, callback);
  }

  /**
   * 初始化并连接 WebSocket
   * @param userId 当前用户ID
   * @param host 后端地址 (如: 192.168.1.5:8080)
   */
  public connect(userId: number, host: string) {
    if (this.isConnected && this.userId === userId) {
      console.info('喵！WebSocket 已经连接了，不用重复连喵。');
      return;
    }
    // 如果已经有连接但 userId 变了，先断开
    if (this.ws) {
      this.close();
    }

    this.userId = userId;
    this.ws = webSocket.createWebSocket();
    
    // 构造连接地址：ws://{host}/ws/{userId}
    const url = `ws://${host}/ws/${userId}`;
    console.info(`喵！准备连接 WebSocket: ${url}`);
    
    this.ws.connect(url, (err, value) => {
      if (!err) {
        console.info(`喵！WebSocket 连接成功 🎉: ${url}`);
        this.isConnected = true;
        this.setupListeners();
      } else {
        console.error(`喵！！！WebSocket 连接失败 😭: ${JSON.stringify(err)}`);
        this.isConnected = false;
      }
    });
  }

  private setupListeners() {
    if (!this.ws) return;

    this.ws.on('open', (err, value) => {
      console.info('喵！WebSocket onOpen 事件触发喵');
    });

    this.ws.on('message', (err, value) => {
      if (!err) {
        // value 可能是 string 或 ArrayBuffer
        const messageStr = value as string;
        console.info(`喵！收到 WS 原始消息 📩: ${messageStr}`);
        try {
          const msgObj = JSON.parse(messageStr) as WebSocketMessage;
          console.info(`喵！解析成功: [${msgObj.senderName}] -> ${msgObj.content} (Type: ${msgObj.type})`);
          
          // 执行注册的监听器
          if (msgObj && msgObj.type) {
             const callback = this.listeners.get(msgObj.type);
             if (callback) {
               callback(msgObj);
             }
             
             // 支付成功逻辑兼容 (Type 1 通常包含支付通知)
             // 按照业务约定，支付成功会通过 Type 1 或 Type 2 发送，并且包含 orderId
             if ((msgObj.type === 1 || msgObj.type === 2) && msgObj.orderId && msgObj.content.includes('支付成功')) { 
                console.info(`喵！检测到支付成功信号，广播 PaySuccessSignal: ${msgObj.orderId}`);
                AppStorage.setOrCreate('PaySuccessSignal', msgObj.orderId);
             }

             // 还可以将最新消息存入 AppStorage 供 UI 响应
             AppStorage.setOrCreate('LatestWSMessage', msgObj);
          }
        } catch (e) {
          console.error('喵！WS 消息解析失败:', e);
        }
      } else {
        console.error('喵！WS 接收消息错误:', err);
      }
    });

    this.ws.on('close', (err, value) => {
      console.warn(`喵！WebSocket 连接断开 🔌, code: ${value.code}, reason: ${value.reason}`);
      this.isConnected = false;
      this.ws = null;
    });

    this.ws.on('error', (err) => {
      console.error('喵！WebSocket 发生错误 ❌:', JSON.stringify(err));
      this.isConnected = false;
    });
  }

  /**
   * 发送消息 (主要用于私聊)
   * @param msg 消息对象
   */
  public send(msg: Partial<WebSocketMessage>) {
    if (this.ws && this.isConnected) {
      const msgStr = JSON.stringify(msg);
      this.ws.send(msgStr, (err, value) => {
        if (!err) {
          console.info('喵！消息发送成功');
        } else {
          console.error('喵！消息发送失败:', err);
        }
      });
    } else {
      console.error('喵！WS 未连接，无法发送消息');
    }
  }

  public close() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
      this.isConnected = false;
      console.info('喵！WebSocket 主动关闭喵');
    }
  }
}