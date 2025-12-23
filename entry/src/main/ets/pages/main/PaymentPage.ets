import { OrderPaymentDTO } from '../../model/api/OrderModel';
import { OrderService } from '../../service/OrderService';
import { promptAction } from '@kit.ArkUI';

/**
 * 支付页面参数
 */
export interface PaymentPageParams {
  orderNumber: string;
  payMethod: number; // 1微信 2支付宝
  totalAmount: number;
}

@Component
export struct PaymentPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State qrCodeContent: string = ''; // 二维码内容
  @State orderNumber: string = '';
  @State payMethod: number = 1;
  @State totalAmount: number = 0;
  @State isLoading: boolean = true;
  @State timeLeft: number = 15 * 60; // 倒计时 15分钟
  private timer: number = -1;

  // 监听支付成功信号
  @StorageProp('PaySuccessSignal') @Watch('onPaySuccess') paySuccessOrderId: number = 0;

  build() {
    NavDestination() {
      Column() {
        // 标题
        Text('订单支付')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 倒计时
        Text(`支付剩余时间 ${this.formatTime(this.timeLeft)}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 30 })

        // 金额
        Row() {
          Text('¥').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 4 })
          Text(this.totalAmount.toFixed(2)).fontSize(36).fontWeight(FontWeight.Bold)
        }.margin({ bottom: 40 })

        // 二维码区域
        if (this.isLoading) {
          LoadingProgress().width(50).height(50).color('#FFCC00')
          Text('正在生成二维码...').fontSize(12).fontColor('#999').margin({ top: 10 })
        } else if (this.qrCodeContent) {
          Column() {
            QRCode(this.qrCodeContent)
              .width(200)
              .height(200)
              .color(Color.Black)
              .backgroundColor(Color.White)
            
            Text(this.payMethod === 1 ? '请使用微信扫码' : '请使用支付宝扫码')
              .fontSize(14)
              .fontColor('#666')
              .margin({ top: 15 })
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#1a000000', offsetY: 5 })
        } else {
          Text('二维码生成失败喵😿').fontSize(14).fontColor(Color.Red)
          Button('重试').margin({ top: 10 }).onClick(() => this.loadQrCode())
        }

        Blank()

        // 底部按钮（兜底用，防止 WS 没收到）
        Button('我已完成支付')
          .width('90%')
          .height(45)
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .margin({ bottom: 30 })
          .onClick(() => {
             // 这里可以去轮询查单，或者直接跳回首页（暂时简单处理）
             this.onPaySuccess();
          })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9F9F9')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack;
      const params = context.pathInfo.param as PaymentPageParams;
      if (params) {
        this.orderNumber = params.orderNumber;
        this.payMethod = params.payMethod;
        this.totalAmount = params.totalAmount;
        this.loadQrCode();
        this.startTimer();
      }
    })
    .onDisAppear(() => {
      clearInterval(this.timer);
    })
  }

  async loadQrCode() {
    this.isLoading = true;
    try {
      const dto: OrderPaymentDTO = {
        orderNumber: this.orderNumber,
        payMethod: this.payMethod
      };
      const result = await OrderService.payment(dto);
      this.qrCodeContent = result.qrCode;
    } catch (e) {
      console.error('喵！获取支付二维码失败:', e);
      promptAction.showToast({ message: '获取二维码失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  startTimer() {
    this.timer = setInterval(() => {
      if (this.timeLeft > 0) {
        this.timeLeft--;
      } else {
        clearInterval(this.timer);
        // 倒计时结束逻辑...
      }
    }, 1000);
  }

  formatTime(seconds: number): string {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  onPaySuccess() {
    if (this.paySuccessOrderId > 0 || this.orderNumber) { // 简单判断，有信号就当成本单成功
      promptAction.showToast({ message: '支付成功喵！🎉' });
      // 清空路由栈，回到 MainTabs
      this.pageStack.clear(); 
      this.pageStack.pushPath({ name: 'MainTabs' });
    }
  }
}
