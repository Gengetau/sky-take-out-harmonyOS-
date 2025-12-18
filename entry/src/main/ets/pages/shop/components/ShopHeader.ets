/**
 * 头部
 */
@Component
export struct ShopHeader {
  @Prop isShopOpen: boolean;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {

      // 1. 背景大图 (带模糊效果)
      Image($r('app.media.shop_header')) // 找张好看的店面图或者纹理图
        .width('100%')
        .height(100) // 头部总高度
        .objectFit(ImageFit.Cover)
        .blur(10) // ✨ 模糊处理，让文字更清晰
      // .opacity(0.8)

      // 2. 内容卡片 (白色悬浮卡片)
      Row() {

        // (1) 左侧 Logo
        Image($r('app.media.shop_logo')) // 那个黄色的 Logo
          .width(60)
          .height(60)
          .borderRadius(4)
          .margin({ right: 10 })
          .shadow({ radius: 5, color: '#33000000', offsetY: 2 })

        // (2) 中间信息
        Column({ space: 5 }) {
          // 店名 + 标签
          Row() {
            Text('喵其林三星')
              .fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#333333')

            // 根据状态显示
            if (this.isShopOpen) {
              Text('营业中')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor('#4CD964') // 绿色
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .borderRadius(2)
                .margin({ left: 8 })
            } else {
              Text('休息中')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor('#AAAAAA') // 灰色
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .borderRadius(2)
                .margin({ left: 8 })
            }
          }.width('100%')

          // 配送信息 Row
          Row() {
            // 📍 距离
            SymbolGlyph($r('sys.symbol.local'))
              .fontSize(12)
              .fontColor([ '#666666' ])
              .margin({ right: 2 })
            Text('1.5km').fontSize(10).fontColor('#666666')

            // 分割线
            Text(' | ').fontSize(10).fontColor('#DDDDDD').margin({ left: 5, right: 5 })

            // 💰 配送费
            SymbolGlyph($r('sys.symbol.yuan_clipboard_fill'))
              .fontSize(12)
              .fontColor([ '#666666' ])
              .margin({ right: 2 })
            Text('配送费6元').fontSize(10).fontColor('#666666')

            // 分割线
            Text(' | ').fontSize(10).fontColor('#DDDDDD').margin({ left: 5, right: 5 })

            // 🕒 时间
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(12)
              .fontColor([ '#666666' ])
              .margin({ right: 2 })
            Text('预计12min').fontSize(10).fontColor('#666666')
          }

          // 公告 (单行省略)
          Text('连猫都想私藏的星级盛宴。')
            .fontSize(10)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1) // 占满剩余宽度
        .alignItems(HorizontalAlign.Start)

        // (3) 右侧电话按钮
        Column() {
          // 分割线
          Line().width(1).height(20).backgroundColor('#EEEEEE').margin({ bottom: 5 })

          Image($r('sys.symbol.phone')) // 系统电话图标
            .width(20).height(20).fillColor('#333333')
            .onClick(() => {
              // 拨打电话逻辑
            })
        }
        .justifyContent(FlexAlign.Center)
        .width(40)

      }
      .width('94%') // 比屏幕窄一点，更有悬浮感
      .height(80) // 卡片高度
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding(10)
      .margin({ bottom: 10 }) // 稍微露出一点背景
      .shadow({ radius: 10, color: '#10000000', offsetY: 5 })

    }
    .width('100%')
    .height(120) // 容器总高度 (背景图 + 下面的空隙)
    .backgroundColor('#F5F5F5')
  }
}