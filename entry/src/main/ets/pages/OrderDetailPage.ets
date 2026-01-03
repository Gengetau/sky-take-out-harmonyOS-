import { router } from '@kit.ArkUI';
import { OrderVO, OrderDetailVO } from '../model/OrderModel';
import { OrderService } from '../service/OrderService';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct OrderDetailPage {
  @State orderId: number = 0;
  @State order: OrderVO | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>;
    if (params && params['id']) {
      this.orderId = params['id'];
      this.loadDetail();
    }
  }

  async loadDetail() {
    this.isLoading = true;
    try {
      this.order = await OrderService.getDetails(this.orderId);
    } catch (e) {
      promptAction.showToast({ message: '获取详情失败喵' });
    } finally {
      this.isLoading = false;
    }
  }

  // 接单逻辑
  async handleConfirm() {
    if (!this.order) return;
    try {
      await OrderService.confirm(this.order.id);
      promptAction.showToast({ message: '接单成功喵！' });
      this.loadDetail(); // 刷新详情
    } catch (e) {}
  }

  // 派送逻辑
  async handleDelivery() {
    if (!this.order) return;
    try {
      await OrderService.delivery(this.order.id);
      promptAction.showToast({ message: '派送开始喵！' });
      this.loadDetail();
    } catch (e) {}
  }

  // 完成订单逻辑
  async handleComplete() {
    if (!this.order) return;
    try {
      await OrderService.complete(this.order.id);
      promptAction.showToast({ message: '订单已完成喵！' });
      this.loadDetail();
    } catch (e) {}
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.app_logo')) // 使用返回图标，这里暂用 startIcon 代替
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('订单详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })
      .backgroundColor(Color.White)

      if (this.isLoading || !this.order) {
        // 加载中
        Column() {
          Text('加载中喵...').fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            // 1. 状态卡片
            this.StatusCard()

            // 2. 地址信息
            this.AddressCard()

            // 3. 商品列表
            this.GoodsCard()

            // 4. 订单信息
            this.InfoCard()

            // 占位，防止底部按钮遮挡
            Blank().height(80)
          }
          .padding(12)
        }
        .layoutWeight(1)

        // 底部操作栏
        this.BottomBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  StatusCard() {
    Column() {
      Text(this.getStatusText(this.order?.status))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.theme_color'))
      Text(this.getStatusDesc(this.order?.status))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AddressCard() {
    Column({ space: 8 }) {
      Text('配送信息').fontSize(16).fontWeight(FontWeight.Bold)
      Divider()
      Row() {
        Text('收货人：').width(80).fontColor($r('app.color.text_secondary'))
        Text(`${this.order?.consignee}  ${this.order?.sex === '1' ? '先生' : '女士'}`)
      }
      Row() {
        Text('电话：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.phone)
      }
      Row() {
        Text('地址：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.address).layoutWeight(1)
      }
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  GoodsCard() {
    Column({ space: 10 }) {
      Text('商品明细').fontSize(16).fontWeight(FontWeight.Bold)
      Divider()
      ForEach(this.order?.orderDetailList || [], (item: OrderDetailVO) => {
        Row() {
          Image(item.image)
            .width(50)
            .height(50)
            .borderRadius(4)
            .backgroundColor('#f0f0f0')
          Column() {
            Text(item.name).fontSize(16)
            Text(item.dishFlavor ? `(${item.dishFlavor})` : '')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })

          Column() {
            Text(`x${item.number}`).fontSize(14)
            Text(`￥${item.amount}`).fontSize(14).fontWeight(FontWeight.Bold)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
      })

      Divider()

      Row() {
        Text('打包费').fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`￥${this.order?.packAmount || 0}`)
      }.width('100%')

      Row() {
        Text('配送费').fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`￥${6}`) // 假设配送费，实际应从字段取
      }.width('100%')

      Row() {
        Text('合计').fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text(`￥${this.order?.amount}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
      }.width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InfoCard() {
    Column({ space: 8 }) {
      Text('订单信息').fontSize(16).fontWeight(FontWeight.Bold)
      Divider()
      Row() {
        Text('订单号：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.number)
      }
      Row() {
        Text('下单时间：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.orderTime)
      }
      Row() {
        Text('支付方式：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.payMethod === 1 ? '微信支付' : '支付宝')
      }
      Row() {
        Text('备注：').width(80).fontColor($r('app.color.text_secondary'))
        Text(this.order?.remark || '无')
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BottomBar() {
    Row() {
      if (this.order?.status === 2) { // 待接单
        Button('拒单')
          .backgroundColor(Color.White)
          .fontColor(Color.Black)
          .borderWidth(1)
          .borderColor($r('app.color.line_color'))
          .layoutWeight(1)
          .margin({ right: 10 })
        Button('接单')
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .layoutWeight(1)
          .onClick(() => this.handleConfirm())
      } else if (this.order?.status === 3) { // 已接单
        Button('取消订单')
          .backgroundColor(Color.White)
          .fontColor(Color.Black)
          .borderWidth(1)
          .borderColor($r('app.color.line_color'))
          .layoutWeight(1)
          .margin({ right: 10 })
        Button('派送')
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .layoutWeight(1)
          .onClick(() => this.handleDelivery())
      } else if (this.order?.status === 4) { // 派送中
        Button('完成订单')
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .layoutWeight(1)
          .onClick(() => this.handleComplete())
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .position({ x: 0, y: '100%' })
    .translate({ y: -60 }) // 简单上移，实际应用 Stack 或 Flex 布局更好控制
    .shadow({ radius: 10, color: '#20000000', offsetY: -2 })
  }

  getStatusText(status: number | undefined): string {
    if (status === 1) return '待付款';
    if (status === 2) return '待接单';
    if (status === 3) return '已接单';
    if (status === 4) return '派送中';
    if (status === 5) return '已完成';
    if (status === 6) return '已取消';
    return '未知状态';
  }

  getStatusDesc(status: number | undefined): string {
    if (status === 2) return '请及时接单喵~';
    if (status === 3) return '请尽快出餐并派送喵~';
    if (status === 4) return '骑手正在火速奔赴喵~';
    if (status === 5) return '感谢您的服务，订单已完成喵！';
    return '';
  }
}
