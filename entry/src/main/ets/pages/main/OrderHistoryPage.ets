import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderVO, OrderCancelDTO } from '../../model/api/OrderModel';
import { OrderService } from '../../service/OrderService';
import { PaymentPageParams } from './PaymentPage'; // ✨ 引入 PaymentPageParams

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
  
  private statusMap: Record<number, string> = {
    1: '待付款',
    2: '待接单',
    3: '已接单',
    4: '派送中',
    5: '已完成',
    6: '已取消'
  };
  private statusColors: Record<number, string> = {
    1: '#FF3B30',
    2: '#FFCC00',
    3: '#007AFF',
    4: '#5856D6',
    5: '#4CD964',
    6: '#999999'
  };

  async aboutToAppear() {
    const params = this.pageStack.getParamByName("OrderHistoryPage") as number[];
    if ( params && params.length > 0 ) {
      const status = params[0];
      if ( typeof status === 'number' ) {
        this.selectedStatus = status;
      }
    }
    this.loadOrders(true);
  }

  async loadOrders(isRefresh: boolean = false) {
    if ( this.isLoading ) return;
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
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * ❌ 取消订单
   */
  async handleCancelOrder(orderId: number, status: number) {
    promptAction.showDialog({
      title: '确认取消订单吗？',
      message: status === 2 ? '订单已支付，取消后将原路退款喵。' : '取消后订单将失效喵。',
      buttons: [
        { text: '再想想', color: '#666666' },
        { text: '确认取消', color: '#FF3B30' }
      ]
    }).then(async (data) => {
      if (data.index === 1) {
        this.showReasonSheet(orderId);
      }
    });
  }

  showReasonSheet(orderId: number) {
    const reasons = [
      '不想要了/拍错单',
      '地址/电话信息填写错误',
      '忘记使用优惠券',
      '送达时间太长',
      '其他原因'
    ];

    promptAction.showActionMenu({
      title: '请选择取消原因',
      // ✨ 直接使用字面量数组
      buttons: [
        { text: reasons[0], color: '#333333' },
        { text: reasons[1], color: '#333333' },
        { text: reasons[2], color: '#333333' },
        { text: reasons[3], color: '#333333' },
        { text: reasons[4], color: '#333333' }
      ]
    }).then(async (data) => {
      const selectedReason = reasons[data.index];
      this.executeCancel(orderId, selectedReason);
    }).catch(() => {
      console.info('用户取消了原因选择');
    });
  }

  async executeCancel(orderId: number, reason: string) {
    try {
      const dto = new OrderCancelDTO(orderId, reason);
      await OrderService.cancelOrder(dto);
      promptAction.showToast({ message: '订单已取消喵' });
      this.loadOrders(true); // 刷新列表
    } catch (e) {
      console.error('取消订单失败:', e);
      promptAction.showToast({ message: '操作失败喵' });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          this.TabItem('全部', undefined)
          this.TabItem('待付款', 1)
          this.TabItem('派送中', 4)
          this.TabItem('已完成', 5)
          this.TabItem('已取消', 6)
        }
        .width('100%')
        .height(44)
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)

        if ( this.orders.length > 0 ) {
          List({ space: 12 }) {
            ForEach(this.orders, (order: OrderVO) => {
              ListItem() {
                this.OrderCard(order)
              }
            })
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
          .padding({ left: 16, right: 16, top: 12, bottom: 20 })
          .backgroundColor('#F7F8FA')
          .edgeEffect(EdgeEffect.Spring)
        } else if (!this.isLoading ) {
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
      Row() {
        Row() {
          Text(order.shopName || '苍穹外卖商家')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([ '#999' ])
            .margin({ left: 2, right: 10 })
        }
        .layoutWeight(1)
        .onClick(() => {
          if ( order.shopId ) {
            this.pageStack.pushPath({ name: 'ShopPage', param: order.shopId });
          }
        })
        Row() {
          Text(this.statusMap[order.status] || '未知状态')
            .fontSize(14)
            .fontColor(this.statusColors[order.status] || '#333')
            .fontWeight(FontWeight.Medium)
          if ( order.status === 4 ) {
            SymbolGlyph($r('sys.symbol.paperplane'))
              .fontSize(14)
              .fontColor([ this.statusColors[order.status] ])
              .margin({ left: 2 })
          }
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 4 })

      Text(`订单号: ${ order.number }`)
        .fontSize(12)
        .fontColor('#999')
        .margin({ bottom: 12 })

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

      Row() {
        Text(order.orderTime).fontSize(12).fontColor('#999').layoutWeight(1)
        Row() {
          Text('合计:').fontSize(12).fontColor('#666')
          Text(`￥${ order.amount ? order.amount.toFixed(2) : '0.00' }`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ left: 4 })
        }
      }
      .width('100%')

      // ✨ 操作按钮区域
      if (order.status === 1 || order.status === 2) {
        Row({ space: 10 }) {
          Blank()
          Button('取消订单')
            .height(28)
            .fontSize(12)
            .backgroundColor(Color.White)
            .fontColor('#666')
            .border({ width: 0.5, color: '#ccc' })
            .onClick((e) => {
              // 阻止事件冒泡到卡片点击
              this.handleCancelOrder(order.id, order.status);
            })
          
          if (order.status === 1) {
            Button('去支付')
              .height(28)
              .fontSize(12)
              .backgroundColor('#FFCC00')
              .fontColor('#333')
              .onClick(() => {
                const params: PaymentPageParams = {
                  orderId: order.id,
                  orderNumber: order.number,
                  payMethod: 2,
                  totalAmount: order.amount
                };
                this.pageStack.pushPath({ name: 'PaymentPage', param: params });
              })
          }
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      this.pageStack.pushPath({ name: 'OrderDetailPage', param: [ order ] });
    })
  }
}

@Builder
export function OrderHistoryPageBuilder() {
  OrderHistoryPage()
}