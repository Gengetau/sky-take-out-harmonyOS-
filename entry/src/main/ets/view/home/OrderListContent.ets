import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderVO } from '../../model/OrderModel';
import { OrderService } from '../../service/OrderService';

/**
 * 订单卡片组件
 * 提取为 Component 以确保状态更新能正确渲染
 */
@Component
struct OrderCardComponent {
  @Prop order: OrderVO;
  // 回调函数，用于触发父组件的操作
  onConfirm: (id: number) => void = () => {
  };
  onDelivery: (id: number) => void = () => {
  };

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

  build() {
    Column() {
      Row() {
        Text(`订单号: ${ this.order.number }`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(this.getStatusText(this.order.status))
          .fontSize(14)
          .fontColor($r('app.color.theme_color'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 10 })

      Divider().color($r('app.color.line_color'))

      Column({ space: 8 }) {
        if ( this.order.orderDetailList ) {
          ForEach(this.order.orderDetailList, (detail: OrderDetailVO) => {
            Row() {
              Text(detail.name).fontSize(16).fontColor($r('app.color.text_main'))
              Blank()
              Text(`x${ detail.number }`).fontSize(14).fontColor($r('app.color.text_secondary'))
            }.width('100%')
          }, (detail: OrderDetailVO, index: number) => index + detail.name)
        }
      }
      .margin({ top: 10, bottom: 10 })

      Row() {
        Text(`下单时间: ${ this.order.orderTime }`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`合计: ￥${ this.order.amount }`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 操作按钮
      // 这里必须阻止冒泡，否则点击按钮也会触发进入详情页
      Row({ space: 10 }) {
        if ( this.order.status === 2 ) {
          // 接单
          Button('接单')
            .type(ButtonType.Normal)
            .borderRadius(4)
            .backgroundColor($r('app.color.theme_color'))
            .fontColor(Color.Black)
            .height(32)
            .width(80)
            .onClick((event) => {
              this.onConfirm(this.order.id);
            })
        } else if ( this.order.status === 3 ) {
          // 派送
          Button('派送')
            .type(ButtonType.Normal)
            .borderRadius(4)
            .backgroundColor($r('app.color.theme_color'))
            .fontColor(Color.Black)
            .height(32)
            .width(100)
            .onClick((event) => {
              this.onDelivery(this.order.id);
            })
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
}

@Component
export struct OrderListContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @Prop @Watch('onStatusChange') status: number; // 过滤状态
  @State orders: OrderVO[] = [];
  @State isRefreshing: boolean = false;
  @State page: number = 1;
  @State pageSize: number = 10;
  @State hasMore: boolean = true;
  @State isLoadingInitial: boolean = true;

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
        // 使用新数组拼接
        this.orders = [ ...this.orders, ...( res.records || [] ) ];
      }
      this.hasMore = this.orders.length < res.total;
    } catch ( err ) {
      console.error('加载订单列表失败', err);
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
      // 成功后刷新列表
      this.page = 1;
      this.loadOrders();
    } catch ( e ) {
      console.error('接单失败', e);
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
      console.error('派送失败', e);
    }
  }

  @Builder
  EmptyState() {
    Column({ space: 15 }) {
      Image($r('app.media.app_logo'))
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
                  // 使用提取出来的 Component 喵
                  OrderCardComponent({
                    order: item,
                    onConfirm: (id): Promise<void> => this.handleConfirm(id),
                    onDelivery: (id): Promise<void> => this.handleDelivery(id)
                  })
                }
                                .onClick(() => {
                                  this.pageStack.pushPath({ name: 'OrderDetailPage', param: item.id });
                                })
                              }, (item: OrderVO) => `${item.id}_${item.status}`) // 喵！把状态加入键值，强迫 ArkUI 刷新！
                
                              if (this.hasMore && this.orders.length > 0) {
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
                  if (!this.isRefreshing ) {
                    this.page++;
                    this.loadOrders();
                  }
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
}
