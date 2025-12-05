/**
 * 购物车
 */
@Component
export struct CartPage {
  build() {
    Column() {
      Text('消息中心').fontSize(30).fontWeight(FontWeight.Bold)
      Text('暂无新消息喵~').fontSize(16).fontColor(Color.Gray).margin({ top: 10 })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor('#F1F3F5')
  }
}