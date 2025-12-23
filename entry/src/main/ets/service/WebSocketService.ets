import { webSocket } from '@kit.NetworkKit';

/**
 * WebSocket 消息接口定义
 */
interface WebSocketMessage {
  type: number;
  orderId?: number;
  content: string;
}

/**
 * WebSocket 服务
 * 负责与后端保持长连接，接收实时消息（如支付成功通知）喵！
 */
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private isConnected: boolean = false;
  private userId: number = 0;
  // 简单的事件监听器：type -> callback
  private listeners: Map<number, (content: string) => void> = new Map();

  private constructor() {
  }

  public static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  /**
   * 初始化并连接 WebSocket
   * @param userId 当前用户ID
   * @param host 后端地址 (如: 192.168.1.5:8080)
   */
  public connect(userId: number, host: string) {
    if (this.isConnected && this.userId === userId) {
      console.info('喵！WebSocket 已经连接了，不用重复连。');
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
      console.info('喵！WebSocket onOpen 事件触发');
    });

    this.ws.on('message', (err, value) => {
      if (!err) {
        // value 可能是 string 或 ArrayBuffer
        const messageStr = value as string;
        console.info(`喵！收到 WS 原始消息 📩: ${messageStr}`);
        try {
          const msgObj = JSON.parse(messageStr) as WebSocketMessage;
          console.info(`喵！消息解析成功: type=${msgObj.type}, orderId=${msgObj.orderId}, content=${msgObj.content}`);
          
          // 消息格式: { type: 1, orderId: 1001, content: "..." }
          if (msgObj && msgObj.type) {
             const callback = this.listeners.get(msgObj.type);
             if (callback) {
               callback(msgObj.content);
             }
             // 广播支付成功信号
             if (msgObj.type === 1 && msgObj.orderId) { 
                console.info(`喵！广播 PaySuccessSignal: ${msgObj.orderId}`);
                AppStorage.setOrCreate('PaySuccessSignal', msgObj.orderId);
             }
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
      // TODO: 这里可以加自动重连
    });

    this.ws.on('error', (err) => {
      console.error('喵！WebSocket 发生错误 ❌:', JSON.stringify(err));
      this.isConnected = false;
    });
  }

  public close() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
      this.isConnected = false;
      console.info('喵！WebSocket 主动关闭');
    }
  }
}
