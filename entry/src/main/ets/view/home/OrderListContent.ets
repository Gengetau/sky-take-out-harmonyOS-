import { OrderVO, OrderDetailVO } from '../../model/OrderModel';

@Component
export struct OrderListContent {
  @Prop status: number; // 过滤状态
  @State orders: OrderVO[] = [];
  @State isRefreshing: boolean = false;

  // 模拟数据
  aboutToAppear() {
    this.loadOrders();
  }

  loadOrders() {
    // TODO: 调用 Service 获取真实数据
    // 模拟一下
    setTimeout(() => {
      this.orders = [
        {
          id: 1,
          number: '202512310001',
          status: this.status,
          amount: 58.5,
          orderTime: '2025-12-31 11:30:00',
          userName: '猫娘妮娅',
          address: '萌宠街道喵喵大厦 8 楼',
          orderDetailList: [
            { name: '至尊芝士披萨', number: 1, amount: 45 },
            { name: '可口可乐', number: 2, amount: 13.5 }
          ]
        }
      ];
      this.isRefreshing = false;
    }, 500);
  }

  build() {
    Column() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ space: 10 }) {
          ForEach(this.orders, (item: OrderVO) => {
            ListItem() {
              this.OrderCard(item)
            }
          }, (item: OrderVO) => item.id.toString())
        }
        .width('100%')
        .height('100%')
        .padding(12)
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(() => {
        this.loadOrders();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  OrderCard(order: OrderVO) {
    Column() {
      Row() {
        Text(`订单号: ${order.number}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(this.getStatusText(order.status))
          .fontSize(14)
          .fontColor($r('app.color.theme_color'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 10 })

      Divider().color($r('app.color.line_color'))

      Column({ space: 8 }) {
        ForEach(order.orderDetailList, (detail: OrderDetailVO) => {
           // 简单展示菜品
           Row() {
             Text(detail.name).fontSize(16).fontColor($r('app.color.text_main'))
             Blank()
             Text(`x${detail.number}`).fontSize(14).fontColor($r('app.color.text_secondary'))
           }.width('100%')
        }, (detail: OrderDetailVO, index: number) => index.toString() + detail.name)
      }
      .margin({ top: 10, bottom: 10 })

      Row() {
        Text(`下单时间: ${order.orderTime}`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`合计: ￥${order.amount}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 操作按钮
      Row({ space: 10 }) {
        if (order.status === 2) {
          Button('拒单').type(ButtonType.Normal).borderRadius(4).backgroundColor(Color.White).fontColor(Color.Black).borderWidth(1).borderColor($r('app.color.line_color')).height(32).width(80)
          Button('接单').type(ButtonType.Normal).borderRadius(4).backgroundColor($r('app.color.theme_color')).fontColor(Color.Black).height(32).width(80)
        } else if (order.status === 3) {
          Button('派送').type(ButtonType.Normal).borderRadius(4).backgroundColor($r('app.color.theme_color')).fontColor(Color.Black).height(32).width(100)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

    }
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width('100%')
  }

  getStatusText(status: number): string {
    if (status === 1) return '待付款';
    if (status === 2) return '待接单';
    if (status === 3) return '已接单';
    if (status === 4) return '派送中';
    if (status === 5) return '已完成';
    if (status === 6) return '已取消';
    return '未知';
  }
}