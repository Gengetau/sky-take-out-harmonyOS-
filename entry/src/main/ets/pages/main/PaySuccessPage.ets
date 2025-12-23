
/**
 * 支付成功页面参数
 */
export interface PaySuccessPageParams {
  orderNumber: string; // ✨ 改为 string，防止精度丢失，且语义更准确
  amount: number;
}

@Component
export struct PaySuccessPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State orderNumber: string = ''; // ✨
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
            Text(this.orderNumber).fontSize(14).fontColor('#333') // 直接显示字符串
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
              // TODO: 跳转到订单详情或订单列表喵
              this.pageStack.clear();
              this.pageStack.pushPath({ name: 'MainTabs' });
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
        this.orderNumber = params.orderNumber; // 直接赋值
        this.amount = params.amount;
      }
    })
  }
}
