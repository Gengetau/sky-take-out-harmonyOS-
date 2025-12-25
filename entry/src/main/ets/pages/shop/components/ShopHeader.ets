import { promptAction } from '@kit.ArkUI';
import { ShopVO } from '../../../model/entity/ShopModel';

/**
 * 商店头部重构版 - 展现真实商户风采喵 ✨
 */
@Component
export struct ShopHeader {
  @Prop isShopOpen: boolean;
  @Prop shopInfo: ShopVO | null;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {

      // 1. 背景大图 (带模糊效果)
      Image(this.shopInfo?.avatar || $r('app.media.shop_header'))
        .width('100%')
        .height(100)
        .objectFit(ImageFit.Cover)
        .blur(15)

      // 2. 内容卡片 (白色悬浮卡片)
      Row() {
        // (1) 左侧 Logo
        Image(this.shopInfo?.avatar || $r('app.media.shop_logo'))
          .width(60)
          .height(60)
          .borderRadius(4)
          .margin({ right: 10 })
          .shadow({ radius: 5, color: '#33000000', offsetY: 2 })
          .objectFit(ImageFit.Cover)

        // (2) 中间信息
        Column({ space: 5 }) {
          // 店名 + 标签
          Row() {
            Text(this.shopInfo?.name || '商家加载中...')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 根据状态显示
            if ( this.isShopOpen ) {
              Text('营业中')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor('#4CD964')
                .padding({
                  left: 4,
                  right: 4,
                  top: 2,
                  bottom: 2
                })
                .borderRadius(2)
                .margin({ left: 8 })
            } else {
              Text('休息中')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor('#AAAAAA')
                .padding({
                  left: 4,
                  right: 4,
                  top: 2,
                  bottom: 2
                })
                .borderRadius(2)
                .margin({ left: 8 })
            }
          }.width('100%')

          // 配送信息 Row
          Row() {
            // 📍 距离 (如果有的话)
            if ( this.shopInfo?.distance ) {
              SymbolGlyph($r('sys.symbol.local'))
                .fontSize(12)
                .fontColor([ '#0D9FFB' ])
                .margin({ right: 2 })
              Text(this.shopInfo.distance).fontSize(10).fontColor('#0D9FFB')
              Text(' | ').fontSize(10).fontColor('#DDDDDD').margin({ left: 5, right: 5 })
            }

            // 💰 配送费
            Text(`配送 ￥${ this.shopInfo?.shippingFee ?? 0 }`).fontSize(10).fontColor('#666666')

            // 分割线
            Text(' | ').fontSize(10).fontColor('#DDDDDD').margin({ left: 5, right: 5 })

            // 🕒 时间
            Text(`约 ${ this.shopInfo?.averageDeliveryTime ?? 0 } min`).fontSize(10).fontColor('#666666')
          }

          // 公告 (单行省略)
          Text(this.shopInfo?.description || '欢迎光临本小店喵~')
            .fontSize(10)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // (3) 右侧收藏/电话按钮
        Column() {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(20)
            .fontColor([ '#333333' ])
            .margin({ bottom: 4 })
          Text('关注').fontSize(10).fontColor('#333')
        }
        .justifyContent(FlexAlign.Center)
        .width(40)
        .onClick(() => promptAction.showToast({ message: '关注成功喵！💖' }))

      }
      .width('94%')
      .height(80)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding(10)
      .margin({ bottom: 10 })
      .shadow({ radius: 10, color: '#10000000', offsetY: 5 })

    }
    .width('100%')
    .height(120)
    .backgroundColor('#F5F5F5')
  }
}
