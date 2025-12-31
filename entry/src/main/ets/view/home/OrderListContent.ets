import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderVO } from '../../model/OrderModel';
import { OrderService } from '../../service/OrderService';

@Component
export struct OrderListContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @Prop @Watch('onStatusChange') status: number; // 过滤状态
  @State orders: OrderVO[] = [];
  @State isRefreshing: boolean = false;
  @State page: number = 1;
  @State pageSize: number = 10;
  @State hasMore: boolean = true;
  @State isLoadingInitial: boolean = true; // 首次加载状态

  onStatusChange() {
    this.page = 1;
    this.loadOrders();
  }

  aboutToAppear() {
    this.loadOrders();
  }

  async loadOrders() {
    this.isRefreshing = true;
    try {
      const res = await OrderService.conditionSearch(this.page, this.pageSize, this.status);
      if ( this.page === 1 ) {
        this.orders = res.records || [];
      } else {
        this.orders = this.orders.concat(res.records || []);
      }
      this.hasMore = this.orders.length < res.total;
    } catch ( err ) {
      // 错误已由 HttpUtil 处理
    } finally {
      this.isRefreshing = false;
      this.isLoadingInitial = false;
    }
  }

  // 接单逻辑
  async handleConfirm(id: number) {
    try {
      await OrderService.confirm(id);
      promptAction.showToast({ message: '接单成功喵！' });
      this.page = 1;
      this.loadOrders();
    } catch ( e ) {
    }
  }

  // 派送逻辑
  async handleDelivery(id: number) {
    try {
      await OrderService.delivery(id);
      promptAction.showToast({ message: '派送开始喵！' });
      this.page = 1;
      this.loadOrders();
    } catch ( e ) {
    }
  }

  build() {
    Stack() {
      if ( this.orders.length === 0 && !this.isLoadingInitial && !this.isRefreshing ) {
        this.EmptyState()
      } else {
        Column() {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List({ space: 10 }) {
              ForEach(this.orders, (item: OrderVO) => {
                ListItem() {
                  this.OrderCard(item)
                }
                .onClick(() => {
                  this.pageStack.pushPath({ name: 'OrderDetailPage', param: item.id });
                })
              }, (item: OrderVO) => item.id.toString())

              if ( this.hasMore && this.orders.length > 0 ) {
                ListItem() {
                  Row() {
                    Text('努力加载中...')
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding(10)
                }
                .onAppear(() => {
                  this.page++;
                  this.loadOrders();
                })
              }
            }
            .width('100%')
            .height('100%')
            .padding(12)
            .edgeEffect(EdgeEffect.Spring)
          }
          .onRefreshing(() => {
            this.page = 1;
            this.loadOrders();
          })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  EmptyState() {
    Column({ space: 15 }) {
      Image($r('app.media.app_logo')) // 暂时用图标做占位
        .width(100)
        .height(100)
        .opacity(0.3)
        .objectFit(ImageFit.Contain)
      Text('还没有相关订单喵~')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
      Button('刷新一下喵')
        .backgroundColor($r('app.color.theme_color'))
        .fontColor(Color.Black)
        .height(36)
        .width(120)
        .onClick(() => {
          this.page = 1;
          this.loadOrders();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  OrderCard(order: OrderVO) {
    Column() {
      Row() {
        Text(`订单号: ${ order.number }`)
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
          Row() {
            Text(detail.name).fontSize(16).fontColor($r('app.color.text_main'))
            Blank()
            Text(`x${ detail.number }`).fontSize(14).fontColor($r('app.color.text_secondary'))
          }.width('100%')
        }, (detail: OrderDetailVO, index: number) => index.toString() + detail.name)
      }
      .margin({ top: 10, bottom: 10 })

      Row() {
        Text(`下单时间: ${ order.orderTime }`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`合计: ￥${ order.amount }`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 操作按钮
      Row({ space: 10 }) {
        if ( order.status === 2 ) {
          // 接单
          Button('接单')
            .type(ButtonType.Normal)
            .borderRadius(4)
            .backgroundColor($r('app.color.theme_color'))
            .fontColor(Color.Black)
            .height(32)
            .width(80)
            .onClick(() => this.handleConfirm(order.id))
        } else if ( order.status === 3 ) {
          // 派送
          Button('派送')
            .type(ButtonType.Normal)
            .borderRadius(4)
            .backgroundColor($r('app.color.theme_color'))
            .fontColor(Color.Black)
            .height(32)
            .width(100)
            .onClick(() => this.handleDelivery(order.id))
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
    if ( status === 1 ) {
      return '待付款';
    }
    if ( status === 2 ) {
      return '待接单';
    }
    if ( status === 3 ) {
      return '已接单';
    }
    if ( status === 4 ) {
      return '派送中';
    }
    if ( status === 5 ) {
      return '已完成';
    }
    if ( status === 6 ) {
      return '已取消';
    }
    return '未知';
  }
}