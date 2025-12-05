import { getLocalImage } from '../../../common/utils/ResourceMap';
import { CartItem } from '../../../model/entity/ShopModel';
import { CartService } from '../../../service/CartService';

/**
 * 购物车详情弹窗
 */
/*// 暂时补救方法
@Builder
export function CartDialogBuilder(controller: CustomDialogController, cartService: CartService) {
  CartDialog({
    controller: controller,
    cartService: cartService
  })
}*/


@Component
struct CartItemView {
  @ObjectLink item: CartItem;
  // 这里的 Service 不需要响应式，只用来调方法
  private cartService: CartService = CartService.getInstance();

  build() {
    Row() {
      Image(getLocalImage(this.item.image))
        .width(40)
        .height(40)
        .margin({ right: 10 })
      // 商品名和规格
      Column() {
        Text(this.item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        if ( this.item.flavors ) {
          Text(this.item.flavors)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 价格
      Row({ space: 2 }) {
        Text('¥').fontSize(12).baselineOffset(-2)
        // ✨ BUG修正：价格应该是单价 x 数量
        Text((this.item.price * this.item.count).toFixed(2))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor('#E94E20')
      }
      .margin({ right: 20 })


      // 加减控制器
      Row({ space: 8 }) {
        Button() {
          Image($r('app.media.ic_decrease'))
            .width(20).height(20)
        }
        .width(28)
        .height(28)
        .type(ButtonType.Circle)
        .backgroundColor('#F0F0F0')
        .onClick(() => {
          this.cartService.decreaseItem(this.item);
        })

        Text(this.item.count.toString())
          .fontSize(16).fontWeight(FontWeight.Medium)

        Button() {
          Image($r('app.media.ic_increase'))
            .width(20).height(20)
        }
        .width(28)
        .height(28)
        .type(ButtonType.Circle)
        .backgroundColor('#FFCC00')
        .onClick(() => {
          this.cartService.increaseItem(this.item);
        })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
  }
}


// 弹窗错误：Error message:class constructor cannot called without 'new'
@CustomDialog
export struct CartDialog {
  // ✨ 监听“购物车更新信号”，强制刷新本组件
  @StorageProp('CartUpdateSignal') cartSignal: number = 0;
  // 从 CartBar 传递过来的 CartService 实例
  @ObjectLink cartService: CartService;
  controller: CustomDialogController; // @CustomDialog 会自动注入 this.controller

  @Builder
  TitleBar() {
    Row() {
      Text('购物车')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Blank() // 占位

      Row({ space: 5 }) {
        Image($r('app.media.ic_delete'))
          .width(16).height(16).fillColor('#666666')
        Text('清空购物车')
          .fontSize(12)
          .fontColor('#666666')
          .onClick(() => {
            this.cartService.clearCart();
            // 购物车空了，自动关闭
            this.controller.close();
          })
      }
      .padding(8)
      .borderRadius(16)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)

    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
  }

  build() {
    Column() {
      // 1. 标题栏
      this.TitleBar()

      // 2. 商品列表
      List({ space: 10 }) {
        ForEach(this.cartService.cartItems, (item: CartItem) => {
          ListItem() {
            CartItemView({ item: item })
          }
        }, (item: CartItem) => item.uniqueKey)
      }
      .height('auto')
      .layoutWeight(1)
      .width('100%')
      .edgeEffect(EdgeEffect.None)

      // 3. 关闭按钮 (为了美观，这里做一个和弹窗主体分离的关闭区域)
      Column()
        .width('100%')
        .height(50)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          this.controller.close();
        })
    }
    .width('100%')
    .height('35%') // 弹窗高度占屏幕60%
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
