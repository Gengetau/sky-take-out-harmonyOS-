import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderVO } from '../../model/api/OrderModel';
import { OrderService } from '../../service/OrderService';

/**
 * 📜 订单历史页面
 */
@Component
export struct OrderHistoryPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State orders: OrderVO[] = [];
  @State currentPage: number = 1;
  @State pageSize: number = 10;
  @State total: number = 0;
  @State isLoading: boolean = false;
  @State selectedStatus: number | undefined = undefined; // 默认查全部
  // 状态映射喵
  private statusMap: Record<number, string> = {
    1: '待付款',
    2: '待接单',
    3: '已接单',
    4: '派送中',
    5: '已完成',
    6: '已取消'
  };
  private statusColors: Record<number, string> = {
    1: '#FF3B30', // 红色
    2: '#FFCC00', // 黄色
    3: '#007AFF', // 蓝色
    4: '#5856D6', // 紫色
    5: '#4CD964', // 绿色
    6: '#999999'  // 灰色
  };

  async aboutToAppear() {
    // 🔍 尝试获取路由传递过来的参数
    const params = this.pageStack.getParamByName("OrderHistoryPage") as number[];
    if ( params && params.length > 0 ) {
      // 这里的 params 实际上是一个数组，取第一个作为 status
      // ArkUI 路由参数传递有时候会包装在数组里，我们防御性取值喵
      const status = params[0];
      if ( typeof status === 'number' ) {
        this.selectedStatus = status;
      }
    }

    this.loadOrders(true);
  }

  /**
   * 加载订单数据喵
   * @param isRefresh 是否重置刷新
   */
  async loadOrders(isRefresh: boolean = false) {
    if ( this.isLoading ) {
      return;
    }
    this.isLoading = true;

    if ( isRefresh ) {
      this.currentPage = 1;
      this.orders = [];
    }

    try {
      const result = await OrderService.getHistoryOrders(this.currentPage, this.pageSize, this.selectedStatus);
      if ( result && result.records ) {
        this.orders = this.orders.concat(result.records);
        this.total = result.total;
      }
    } catch ( e ) {
      // Error handling
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶部状态筛选喵
        Row() {
          this.TabItem('全部', undefined)
          this.TabItem('待付款', 1)
          this.TabItem('派送中', 4)
          this.TabItem('已完成', 5)
          this.TabItem('已取消', 6) // 新增"已取消"标签方便查看退款/售后
        }
        .width('100%')
        .height(44)
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)

        // 2. 订单列表喵
        if ( this.orders.length > 0 ) {
          List({ space: 12 }) {
            ForEach(this.orders, (order: OrderVO) => {
              ListItem() {
                this.OrderCard(order)
              }
            })

            // 加载更多喵
            if ( this.orders.length < this.total ) {
              ListItem() {
                Row() {
                  LoadingProgress().width(20).height(20).margin({ right: 10 })
                  Text('正在加载更多美味...').fontSize(14).fontColor('#999')
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding(10)
              }
              .onAppear(() => {
                this.currentPage++;
                this.loadOrders();
              })
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 20
          })
          .backgroundColor('#F7F8FA')
          .edgeEffect(EdgeEffect.Spring)
        } else if (!this.isLoading ) {
          // 空状态喵
          Column({ space: 10 }) {
            SymbolGlyph($r('sys.symbol.doc_plaintext'))
              .fontSize(60)
              .fontColor([ '#DDD' ])
            Text('暂时还没有订单记录喵~')
              .fontSize(14)
              .fontColor('#999')
            Button('去逛逛美味')
              .margin({ top: 10 })
              .backgroundColor('#FFCC00')
              .fontColor('#333')
              .onClick(() => this.pageStack.pop())
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F7F8FA')
        } else {
          // 加载中喵
          Column() {
            LoadingProgress().width(50).height(50)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('我的订单')
    .hideTitleBar(false)
  }

  @Builder
  TabItem(label: string, status: number | undefined) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.selectedStatus === status ? '#333' : '#666')
        .fontWeight(this.selectedStatus === status ? FontWeight.Bold : FontWeight.Normal)

      if ( this.selectedStatus === status ) {
        Rect()
          .width(20)
          .height(3)
          .fill('#FFCC00')
          .margin({ top: 4 })
          .borderRadius(1.5)
      }
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectedStatus = status;
      this.loadOrders(true);
    })
  }

  @Builder
  OrderCard(order: OrderVO) {
    Column() {
      // 卡片头部：订单号与状态
      Row() {
        Text(`订单号: ${ order.number }`)
          .fontSize(12)
          .fontColor('#999')
          .layoutWeight(1)

        Text(this.statusMap[order.status] || '未知状态')
          .fontSize(12)
          .fontColor(this.statusColors[order.status] || '#333')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 卡片内容：商品预览
      Column({ space: 8 }) {
        ForEach(order.orderDetailList.slice(0, 3), (detail: OrderDetailVO) => {
          Row() {
            Text(detail.name).fontSize(15).fontColor('#333').layoutWeight(1)
            Text(`x${ detail.number }`).fontSize(14).fontColor('#666')
          }.width('100%')
        })

        if ( order.orderDetailList.length > 3 ) {
          Text(`查看全部 ${ order.orderDetailList.length } 件商品...`)
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 2 })
        }
      }
      .width('100%')

      Divider().margin({ top: 12, bottom: 12 }).color('#F2F2F2')

      // 卡片底部：时间与合计
      Row() {
        Text(order.orderTime).fontSize(12).fontColor('#999').layoutWeight(1)

        Row() {
          Text('合计:').fontSize(12).fontColor('#666')
          Text(`￥${ order.amount.toFixed(2) }`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ left: 4 })
        }
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      promptAction.showToast({ message: '详情页正在加班开发中喵~' });
    })
  }
}

@Builder
export function OrderHistoryPageBuilder() {
  OrderHistoryPage()
}
