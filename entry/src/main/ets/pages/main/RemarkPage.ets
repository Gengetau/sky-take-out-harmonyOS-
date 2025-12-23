/**
 * 订单备注页面
 */
@Component
export struct RemarkPage {
  @State remarkText: string = '';
  // 回调函数
  onSave: (remark: string) => void = () => {
  };
  onClose: () => void = () => {
  };
  // 快捷标签数据
  private tags: string[] = [ '不吃辣', '少放葱', '多放辣', '不吃香菜', '少饭', '去冰', '无接触配送' ];

  build() {
    Column() {
      // 标题栏（模仿 Navigation 标题）
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([ '#333' ])
          .onClick(() => {
            if ( this.onClose ) {
              this.onClose();
            }
          })
        Text('订单备注')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 }) // 平衡左边图标的占位
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 输入区域
      TextArea({ text: this.remarkText, placeholder: '请输入备注信息，如口味偏好、特殊要求等' })
        .height(150)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin(16)
        .padding(12)
        .maxLength(100)
        .onChange((value) => {
          this.remarkText = value;
        })

      // 快捷标签区域
      Text('快捷标签')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, bottom: 10 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.tags, (tag: string) => {
          Text(tag)
            .fontSize(12)
            .fontColor('#666')
            .padding({
              left: 12,
              right: 12,
              top: 6,
              bottom: 6
            })
            .backgroundColor('#F5F5F5')
            .borderRadius(14)
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              // 点击标签追加到备注后，自动加空格
              if ( this.remarkText.length > 0 && !this.remarkText.endsWith(' ') ) {
                this.remarkText += ` ${ tag }`;
              } else {
                this.remarkText += tag;
              }
            })
        })
      }
      .padding({ left: 16, right: 16 })

      Blank()

      // 底部按钮
      Button('完成')
        .width('90%')
        .height(45)
        .backgroundColor('#FFCC00')
        .fontColor('#333')
        .margin({ bottom: 20 })
        .onClick(() => {
          if ( this.onSave ) {
            this.onSave(this.remarkText);
          }
          if ( this.onClose ) {
            this.onClose();
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}