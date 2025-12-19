import { CartService } from '../../../service/CartService';
import { CartDialog } from './CartDialog';

/**
 * 购物车条
 */
@Component
export struct CartBar {
  @Prop isShopOpen: boolean;
  // 增加一个点击去结算的回调，通知父组件弹窗
  onCheckout: () => void = () => {};
  
  @StorageProp('CartUpdateSignal') @Watch('onUpdate') cartSignal: number = 0;
  @State totalCount: number = 0;
  @State totalPrice: number = 0;
  // ✨ 修正1：升级为 @State，使其能为子组件的 @ObjectLink 提供数据源
  @State cartService: CartService = CartService.getInstance();
  // 起送费可以作为常量或从配置中读取
  private minOrderPrice: number = 20;
  // 弹窗控制器
  private cartDialogController: CustomDialogController = new CustomDialogController({
    builder: CartDialog({
      cartService: this.cartService
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  aboutToAppear() {
    this.onUpdate();
  }

  onUpdate() {
    // 每次信号变了，重新从 Service 拉取最新数据
    this.totalCount = this.cartService.totalCount;
    this.totalPrice = this.cartService.totalPrice;
  }

  build() {
    // 外层 Stack 用于让图标悬浮在 Bar 之上
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.isShopOpen) {
        // --- 1. 购物车条主体 (黑色的背景条) ---
        Row() {
          // 左侧留白 (给大图标腾位置)
          Blank().width(110)

          // 中间：价格信息
          Column() {
            if ( this.totalCount > 0 ) {
              Text(`¥ ${ this.totalPrice.toFixed(2) }`)
                .fontSize(18).fontColor(Color.White).fontWeight(FontWeight.Bold)
              Text('预估配送费 ¥6').fontSize(10).fontColor('#999999')
            } else {
              Text('未选购商品').fontSize(14).fontColor('#999999')
            }
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)

          // 右侧：按钮
          Row() {
            if ( this.totalPrice >= this.minOrderPrice ) {
              Button('去结算')
                .type(ButtonType.Normal)
                .backgroundColor('#FFCC00')
                .fontColor('#333333')
                .borderRadius({ topRight: 25, bottomRight: 25 })
                .width(100)
                .height('100%')
                .onClick(() => {
                  console.info('喵！去付钱！');
                  if (this.onCheckout) {
                    this.onCheckout();
                  }
                  // ✨ 修正2：返回 true 来阻止事件冒泡
                  return true;
                })
            } else {
              Text(`¥${ this.minOrderPrice }起送`)
                .fontColor('#999999').fontSize(14).fontWeight(FontWeight.Bold).padding({ right: 20 })
            }
          }.height('100%')
        }
        .onClick(() => {
          if ( this.cartService.totalCount > 0 ) {
            this.cartDialogController.open();
          }
        })
        .width('94%')
        .height(50)
        .backgroundColor('#222222')
        .borderRadius(25)
        .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        .margin({ bottom: 10 }) // 距离屏幕底部一点距离

        // --- 2. 悬浮的大图标 (外卖小哥) ---
        Stack({ alignContent: Alignment.TopEnd }) {
          // 🛵 外卖小哥大图
          Image($r('app.media.cart_logo')) // 👈 记得确认文件名哦！
            .width(110) // 足够大，才能突出
            .height(110)
            .objectFit(ImageFit.Contain)

          // 🔴 数字徽章
          if ( this.cartService.totalCount > 0 ) {
            Text(this.cartService.totalCount.toString())
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#FF3B30')
              .borderRadius(10)
              .padding({ left: 5, right: 5 })
              .height(16)
              .textAlign(TextAlign.Center)
              // 微调徽章位置，挂在小哥头盔旁边
              .position({ x: 70, y: 20 })
          }
        }
        .width(110).height(110)
        .zIndex(2) // 层级最高，盖住 Bar
      } else {
        // --- 1. 购物车条主体 (打烊状态) ---
        Row() {
          Text('本店已打烊').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold)
        }
        .width('94%')
        .height(50)
        .backgroundColor('#AAAAAA') // 灰色背景
        .borderRadius(25)
        .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        .margin({ bottom: 10 })
        .justifyContent(FlexAlign.Center) // 文字居中

        // 悬浮图标 (可以隐藏或显示灰色版本)
        Image($r('app.media.cart_logo'))
          .width(110)
          .height(110)
          .objectFit(ImageFit.Contain)
          .grayscale(1) // 置灰
          .opacity(0.5) // 半透明
          .zIndex(2)
          .alignSelf(ItemAlign.Start) // 保持左下角对齐
          .offset({ x: 0, y: 0 }) // 调整位置
      }
    }
    .width('100%')
  }
}