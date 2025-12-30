import { OrderVO } from '../../model/api/OrderModel';

/**
 * 支付成功页面参数
 */
export interface PaySuccessPageParams {
  orderId: number;     // ✨ 新增 orderId，用于精准查询详情
  orderNumber: string; // 订单号 (显示用)
  amount: number;
}

@Component
export struct PaySuccessPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State orderId: number = 0;
  @State orderNumber: string = '';
  @State amount: number = 0;

  build() {
    NavDestination() {
      Column() {
        // 顶部空白
        Blank().height(80)

        // 成功图标
        Column() {
          SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
            .fontSize(100)
            .fontColor([Color.Green])
          
          Text('支付成功')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
          
          Text('美食正在全速奔向您喵！🚀')
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 10 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 详情卡片
        Column() {
          Row() {
            Text('实付金额').fontSize(14).fontColor('#999')
            Blank()
            Text(`¥${this.amount.toFixed(2)}`).fontSize(16).fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })

          Divider().color('#F5F5F5')

          Row() {
            Text('订单编号').fontSize(14).fontColor('#999')
            Blank()
            Text(this.orderNumber).fontSize(14).fontColor('#333') 
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })
        }
        .margin({ top: 50, left: 20, right: 20 })
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)

        Blank()

        // 按钮组
        Column({ space: 15 }) {
          Button('返回首页')
            .width('90%')
            .height(45)
            .type(ButtonType.Capsule)
            .backgroundColor('#FFCC00')
            .fontColor('#333')
            .onClick(() => {
              this.pageStack.clear();
              this.pageStack.pushPath({ name: 'MainTabs' });
            })

          Button('查看订单')
            .width('90%')
            .height(45)
            .type(ButtonType.Capsule)
            .backgroundColor(Color.Transparent)
            .fontColor('#666')
            .border({ width: 1, color: '#DDD' })
            .onClick(() => {
              // ✨ 跳转到订单详情页
              if (this.orderId > 0) {
                // 构造一个包含 ID 的简易 OrderVO 对象，详情页会自动通过接口刷新完整数据喵！
                const orderData: OrderVO = {
                  id: this.orderId,
                  number: this.orderNumber,
                  amount: this.amount,
                  status: 2, // 已支付一般状态为待接单
                  orderTime: '',
                  orderDetailList: [],
                  shopId: 0 // 后端详情接口会补齐
                };
                // 使用 replacePath 以免点击返回又回到支付成功页喵
                this.pageStack.replacePath({ name: 'OrderDetailPage', param: [orderData] });
              } else {
                // 兜底方案：回列表
                this.pageStack.replacePath({ name: 'OrderHistoryPage' });
              }
            })
        }
        .margin({ bottom: 50 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9F9F9')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack;
      const params = context.pathInfo.param as PaySuccessPageParams;
      if (params) {
        this.orderId = params.orderId;
        this.orderNumber = params.orderNumber;
        this.amount = params.amount;
      }
    })
  }
}