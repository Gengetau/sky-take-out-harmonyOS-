import { promptAction } from '@kit.ArkUI';
import { OrderDetailVO, OrderVO } from '../../model/api/OrderModel';
import { OrderService } from '../../service/OrderService';
import { PaymentPageParams } from './PaymentPage';
import { ChatPageParam } from '../message/ChatPage'; // ✨ 引入 ChatPageParam

@Component
export struct OrderDetailPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State order: OrderVO | null = null;
  @State isLoading: boolean = true;
  private statusMap: Record<number, string> = {
    1: '待付款',
    2: '待接单',
    3: '已接单',
    4: '派送中',
    5: '已完成',
    6: '已取消'
  };

  async aboutToAppear() {

    const params = this.pageStack.getParamByName("OrderDetailPage") as Array<object>;

    console.info('喵！OrderDetailPage aboutToAppear, params:', JSON.stringify(params));


    let initialData: OrderVO | null = null;


    if ( params && params.length > 0 ) {

      const firstParam = params[0];

      // 检查是否是双重数组喵 [[{...}]]

      if ( Array.isArray(firstParam) && firstParam.length > 0 ) {

        initialData = (firstParam as Array<OrderVO>)[0];

      } else {

        initialData = firstParam as OrderVO;

      }

    }

    if ( initialData ) {
      console.info('喵！initialData:', JSON.stringify(initialData));
      this.order = initialData;
      // ✨ 既然有了 7.5 接口，我们就主动拉取一次完整详情（包含图片等）喵！
      console.info('喵！准备加载订单详情, id:', initialData.id);
      this.loadDetail(initialData.id);
    } else {
      console.warn('喵！OrderDetailPage params 解析失败或为空');
    }
  }

  async loadDetail(id: number) {
    this.isLoading = true;
    try {
      this.order = await OrderService.getOrderDetail(id);
    } catch ( e ) {
      console.error('喵！获取订单详情失败:', e);
      promptAction.showToast({ message: '加载详情失败喵' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      if ( this.order ) {
        Column() {
          // 1. 顶部状态栏
          this.StatusHeader()

          Scroll() {
            Column({ space: 12 }) {
              // 2. 商家与商品卡片
              this.GoodsSection()

              // 3. 订单信息卡片
              this.OrderInfoSection()

              Blank().height(80)
            }
            .padding(12)
            .width('100%')
          }
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')

          // 4. 底部操作栏
          this.BottomBar()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
      } else if ( this.isLoading ) {
        Column() {
          LoadingProgress().width(50).height(50).color('#FFCC00')
          Text('正在努力加载详情喵...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        // 异常情况
        Column() {
          Text('订单数据丢失喵😿').fontColor('#999')
          Button('返回').margin({ top: 10 }).onClick(() => this.pageStack.pop())
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
    }
    .title('订单详情')
    .hideTitleBar(false)
  }

  @Builder
  StatusHeader() {
    Row() {
      Text(this.statusMap[this.order!.status] || '未知状态')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')

      Blank()

      if ( this.order!.status === 4 ) {
        SymbolGlyph($r('sys.symbol.paperplane'))
          .fontSize(40)
          .fontColor([ '#333' ])
      } else if ( this.order!.status === 5 ) {
        SymbolGlyph($r('sys.symbol.checkmark_circle'))
          .fontSize(40)
          .fontColor([ '#333' ])
      }
    }
    .width('100%')
    .padding({
      left: 24,
      right: 24,
      top: 10,
      bottom: 20
    })
    .backgroundColor(Color.White)
  }

  @Builder
  GoodsSection() {
    Column() {
      // 店铺名称栏
      Row() {
        Text(this.order!.shopName || '商家')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        // ✨ 联系商家按钮
        Row() {
          SymbolGlyph($r('sys.symbol.message'))
            .fontSize(16)
            .fontColor(['#007DFF'])
            .margin({ right: 4 })
          Text('联系').fontSize(12).fontColor('#007DFF')
        }
        .margin({ right: 16 })
        .onClick(() => {
          if (this.order!.shopId) {
            const sessionId = `shop_${this.order!.shopId}`;
            const title = this.order!.shopName || '商家';
            // 订单详情里没有头像，传空字符串，ChatPage会处理默认头像
            this.pageStack.pushPath({ name: 'ChatPage', param: new ChatPageParam(sessionId, title, '') });
          }
        })

        Row() {
          Text('进店').fontSize(12).fontColor('#666')
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor([ '#999' ])
        }
        .onClick(() => {
          if ( this.order!.shopId ) {
            this.pageStack.pushPath({ name: 'ShopPage', param: this.order!.shopId });
          }
        })
      }
      .width('100%')
      .padding({ bottom: 12 })
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      // 商品列表
      ForEach(this.order!.orderDetailList, (detail: OrderDetailVO) => {
        Row() {
          // ✨ 现在可以使用接口返回的真实图片了喵！
          Image(detail.image || $r('app.media.appstore'))
            .width(50)
            .height(50)
            .borderRadius(4)
            .backgroundColor('#f0f0f0')
            .margin({ right: 10 })
            .objectFit(ImageFit.Cover)

          Column() {
            Text(detail.name)
              .fontSize(14)
              .fontColor('#333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(`x${ detail.number }`)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(`¥${ detail.amount ? detail.amount.toFixed(2) : '0.00' }`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      })

      Divider().color('#F0F0F0')

      // 合计
      Row() {
        Text('实付').fontSize(14).fontColor('#333')
        Blank()
        Text(`¥${ this.order!.amount ? this.order!.amount.toFixed(2) : '0.00' }`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3B30')
      }
      .width('100%')
      .padding({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  OrderInfoSection() {
    Column({ space: 12 }) {
      Text('订单信息').fontSize(14).fontWeight(FontWeight.Bold)

      Row() {
        Text('订单号码').fontSize(12).fontColor('#999').width(70)
        Text(this.order!.number).fontSize(12).fontColor('#333').layoutWeight(1)
        Text('复制')
          .fontSize(10)
          .fontColor('#007AFF')
          .padding({
            left: 8,
            right: 8,
            top: 2,
            bottom: 2
          })
          .border({ width: 0.5, color: '#007AFF', radius: 4 })
          .onClick(() => {
            promptAction.showToast({ message: '复制成功喵' });
            // TODO: 实现剪贴板复制
          })
      }.width('100%')

      Row() {
        Text('下单时间').fontSize(12).fontColor('#999').width(70)
        Text(this.order!.orderTime).fontSize(12).fontColor('#333')
      }.width('100%')

      Row() {
        Text('支付方式').fontSize(12).fontColor('#999').width(70)
        Text('在线支付').fontSize(12).fontColor('#333')
      }.width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BottomBar() {
    Row() {
      Blank()
      if ( this.order!.status === 1 ) { // 待付款
        Button('去支付')
          .height(36)
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .fontSize(14)
          .onClick(() => {
            // 跳转支付
            const params: PaymentPageParams = {
              orderId: this.order!.id,
              orderNumber: this.order!.number,
              payMethod: 2, // 默认
              totalAmount: this.order!.amount
            };
            this.pageStack.pushPath({ name: 'PaymentPage', param: params });
          })
      } else {
        Button('再来一单')
          .height(36)
          .backgroundColor(Color.White)
          .fontColor('#333')
          .fontSize(14)
          .border({ width: 0.5, color: '#ccc' })
          .onClick(() => {
            if ( this.order!.shopId ) {
              this.pageStack.pushPath({ name: 'ShopPage', param: this.order!.shopId });
            }
          })
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: '#1a000000', offsetY: -2 })
  }
}