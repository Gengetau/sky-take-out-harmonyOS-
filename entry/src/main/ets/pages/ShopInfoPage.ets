import { promptAction } from '@kit.ArkUI';
import { ShopInfoVO } from '../model/ShopModel';
import { ShopService } from '../service/ShopService';

@Component
export struct ShopInfoPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State shopInfo: ShopInfoVO | null = null;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.loadShopInfo();
  }

  async loadShopInfo() {
    try {
      this.isLoading = true;
      const res = await ShopService.getShopInfo();
      this.shopInfo = res;
      // 同步更新 AppStorage 里的信息喵
      AppStorage.setOrCreate('shopInfo', res);
    } catch ( e ) {
      // 错误已处理
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 切换营业状态喵
   */
  async toggleStatus(isOn: boolean) {
    if (!this.shopInfo ) {
      return;
    }
    const newStatus = isOn ? 1 : 0;
    try {
      await ShopService.setStatus(newStatus);
      this.shopInfo.status = newStatus;
      promptAction.showToast({ message: isOn ? '开门大吉喵！☀️' : '辛苦了，休息时间喵🌙' });
      // 更新全局状态
      AppStorage.setOrCreate('shopInfo', this.shopInfo);
    } catch ( e ) {
      // 失败了要弹回来喵
      this.loadShopInfo();
    }
  }

  build() {
    NavDestination() {
      Column() {
        if ( this.isLoading ) {
          LoadingProgress().width(50).height(50).color($r('app.color.theme_color'))
        } else if ( this.shopInfo ) {
          List() {
            // 1. 店铺 Logo
            ListItem() {
              Row() {
                Text('店铺 Logo').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                Image(this.shopInfo.avatar || $r('app.media.startIcon'))
                  .width(60)
                  .height(60)
                  .borderRadius(30)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#F0F0F0')
                Image($r('app.media.startIcon')) // 箭头
                  .width(16).height(16).opacity(0.3).margin({ left: 10 })
              }
              .width('100%')
              .height(80)
              .padding({ left: 15, right: 15 })
              .backgroundColor(Color.White)
              .onClick(() => {
                promptAction.showToast({ message: '修改头像功能建设中喵~' });
              })
            }.margin({ bottom: 1 })

            // 2. 店铺状态
            ListItem() {
              Row() {
                Text('营业状态').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                Text(this.shopInfo.status === 1 ? '正在营业' : '已打烊')
                  .fontSize(14)
                  .fontColor(this.shopInfo.status === 1 ? Color.Green : Color.Gray)
                  .margin({ right: 10 })
                Toggle({ type: ToggleType.Switch, isOn: this.shopInfo.status === 1 })
                  .selectedColor($r('app.color.theme_color'))
                  .onChange((isOn: boolean) => {
                    this.toggleStatus(isOn);
                  })
              }
              .width('100%')
              .height(60)
              .padding({ left: 15, right: 15 })
              .backgroundColor(Color.White)
            }.margin({ bottom: 10 })

            // 3. 基础信息
            this.InfoItem('店铺名称', this.shopInfo.name)
            this.InfoItem('联系电话', this.shopInfo.phone)
            this.InfoItem('店铺地址', this.shopInfo.address)
            this.InfoItem('店铺简介', this.shopInfo.description || '暂无简介喵~')

            // 4. 店铺评分 (只读)
            ListItem() {
              Row() {
                Text('店铺评分').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                Text(this.shopInfo.score.toFixed(1))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFB000')
                Text(' 分').fontSize(12).fontColor('#999999')
              }
              .width('100%')
              .height(60)
              .padding({ left: 15, right: 15 })
              .backgroundColor(Color.White)
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
      .justifyContent(FlexAlign.Center)
    }
    .title('店铺设置')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  InfoItem(label: string, value: string) {
    ListItem() {
      Row() {
        Text(label).fontSize(16).fontColor($r('app.color.text_main'))
        Blank()
        Text(value)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .margin({ left: 20 })
        Image($r('app.media.startIcon')) // 箭头
          .width(16).height(16).opacity(0.3).margin({ left: 10 })
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor(Color.White)
      .onClick(() => {
        promptAction.showToast({ message: `修改${ label }功能建设中喵~` });
      })
    }.margin({ bottom: 1 })
  }
}
