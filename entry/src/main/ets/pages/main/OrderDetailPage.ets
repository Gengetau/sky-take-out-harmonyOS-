import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderRejectionDTO, OrderVO } from '../../model/OrderModel';
import { OrderService } from '../../service/OrderService';

@Component
export struct OrderDetailPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State orderId: number = 0;
  @State order: OrderVO | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    // 获取路由参数
    const params = this.pageStack.getParamByName('OrderDetailPage') as number[];
    // 注意：NavPathStack.getParamByName 返回的是数组，取最后一个
    if ( params && params.length > 0 ) {
      this.orderId = params[params.length - 1];
      this.loadDetail();
    }
  }

  async loadDetail() {
    this.isLoading = true;
    try {
      this.order = await OrderService.getDetails(this.orderId);
    } catch ( e ) {
      // HttpUtil 已处理 Toast
    } finally {
      this.isLoading = false;
    }
  }

  // 统一的操作处理
  async handleAction(action: string) {
    if (!this.order ) {
      return;
    }
    try {
      if ( action === 'confirm' ) {
        await OrderService.confirm(this.order.id);
        promptAction.showToast({ message: '已接单喵！' });
      } else if ( action === 'delivery' ) {
        await OrderService.delivery(this.order.id);
        promptAction.showToast({ message: '开始派送喵！' });
      } else if ( action === 'complete' ) {
        await OrderService.complete(this.order.id);
        promptAction.showToast({ message: '订单完成喵！' });
      } else if ( action === 'rejection' ) {
        const dto: OrderRejectionDTO = new OrderRejectionDTO(this.order.id, '商家忙碌');
        await OrderService.rejection(dto);
        promptAction.showToast({ message: '已拒单喵...' });
      } else if ( action === 'cancel' ) {
        const dto: OrderRejectionDTO = new OrderRejectionDTO(this.order.id, '商家取消');
        await OrderService.cancel(dto);
        promptAction.showToast({ message: '订单已取消' });
      }
      // 刷新详情
      this.loadDetail();
    } catch ( e ) {
    }
  }

  build() {
    NavDestination() {
      if ( this.isLoading ) {
        Column() {
          LoadingProgress().width(50).height(50).color($r('app.color.theme_color'))
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if ( this.order ) {
        Column() {
          List() {
            // 1. 状态头
            ListItem() {
              Column() {
                Text(this.getStatusText(this.order.status))
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .margin({ bottom: 5 })
                Text('感谢您对Meow外卖的信任')
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(20)
              .backgroundColor(Color.White)
            }

            // 2. 配送信息
            ListItem() {
              Column() {
                Text('配送信息')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })
                  .width('100%')

                this.InfoRow('收货地址', this.order.address || '无')
                this.InfoRow('联系人', this.order.userName || '未知')
                this.InfoRow('电话', this.order.phone || '无')
                this.InfoRow('备注', this.order.remark || '无备注')
              }
              .padding(15)
              .backgroundColor(Color.White)
              .margin({ top: 10 })
            }

            // 3. 菜品信息
            ListItem() {
              Column() {
                Text('商品信息')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })
                  .width('100%')

                ForEach(this.order.orderDetailList, (item: OrderDetailVO) => {
                  Row() {
                    Image(item.image)
                      .width(50)
                      .height(50)
                      .borderRadius(4)
                      .backgroundColor('#f5f5f5')
                      .margin({ right: 10 })

                    Column() {
                      Text(item.name).fontSize(16).fontColor('#333333')
                      Text(`x${ item.number }`).fontSize(14).fontColor('#999999').margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Text(`￥${ item.amount }`)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Bold)
                  }
                  .width('100%')
                  .margin({ bottom: 15 })
                }, (item: OrderDetailVO, index: number) => index + item.name)

                Divider().color('#E3E3E3')

                Row() {
                  Text('实付金额').fontColor('#333333')
                  Blank()
                  Text(`￥${ this.order.amount }`)
                    .fontColor(Color.Red)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .margin({ top: 15 })
              }
              .padding(15)
              .backgroundColor(Color.White)
              .margin({ top: 10 })
            }

            // 4. 订单信息
            ListItem() {
              Column() {
                Text('订单信息')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })
                  .width('100%')

                this.InfoRow('订单号', this.order.number)
                this.InfoRow('下单时间', this.order.orderTime)
              }
              .padding(15)
              .backgroundColor(Color.White)
              .margin({ top: 10, bottom: 80 }) // 底部留白给按钮
            }
          }
          .width('100%')
          .height('100%')

          // 底部操作栏
          this.BottomBar(this.order)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.page_background'))
      }
    }
    .title('订单详情')
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).width(80).fontColor('#666666').fontSize(14)
      Text(value).layoutWeight(1).fontColor('#333333').fontSize(14)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 10 })
  }

  @Builder
  BottomBar(order: OrderVO) {
    Row() {
      if ( order.status === 2 ) { // 待接单
        Button('拒单')
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .margin({ right: 10 })
          .onClick(() => this.handleAction('rejection'))
        Button('接单').backgroundColor($r('app.color.theme_color')).fontColor('#333333').layoutWeight(1)
          .onClick(() => this.handleAction('confirm'))
      } else if ( order.status === 3 ) { // 已接单
        Button('取消')
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .layoutWeight(1)
          .margin({ right: 10 })
          .onClick(() => this.handleAction('cancel'))
        Button('派送').backgroundColor($r('app.color.theme_color')).fontColor('#333333').layoutWeight(1)
          .onClick(() => this.handleAction('delivery'))
      } else if ( order.status === 4 ) { // 派送中
        Button('完成订单').backgroundColor($r('app.color.theme_color')).fontColor('#333333').width('100%')
          .onClick(() => this.handleAction('complete'))
      }
    }
    .width('100%')
    .height(60)
    .position({ x: 0, y: '100%' })
    .translate({ y: -60 })
    .backgroundColor(Color.White)
    .padding({ left: 15, right: 15 })
    .shadow({ radius: 10, color: '#1a000000', offsetY: -2 })
    .alignItems(VerticalAlign.Center)
  }

  getStatusText(status: number): string {
    const statusMap: Record<number, string> = {
      1: '待付款',
      2: '待接单',
      3: '已接单',
      4: '派送中',
      5: '已完成',
      6: '已取消'
    };
    return statusMap[status] || '未知状态';
  }
}
