import { promptAction } from '@kit.ArkUI';
import { ShopInfoVO } from '../../model/ShopModel';
import { ShopService } from '../../service/ShopService';

@Component
export struct ManageContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @State shopStatus: number = 0; // 1:营业中, 0:打烊中
  @State shopInfo: ShopInfoVO | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadShopInfo();
  }

  async loadShopInfo() {
    this.isLoading = true;
    try {
      this.shopInfo = await ShopService.getShopInfo();
      if ( this.shopInfo ) {
        this.shopStatus = this.shopInfo.status;
      }
    } catch ( e ) {
      // 错误已处理
    } finally {
      this.isLoading = false;
    }
  }

  async updateStatus(targetStatus: number) {
    // 🛑 关键防线：如果目标状态和当前一致，说明是数据加载引起的变更，或者是重复点击，直接忽略！
    if (targetStatus === this.shopStatus) return;

    // 🛑 弹窗确认
    const isOpening = targetStatus === 1;
    AlertDialog.show({
      title: isOpening ? '开始营业' : '暂停营业',
      message: isOpening ? '确认要开始营业吗？新的一天要开始接单啦喵！' : '确认要关闭店铺吗？打烊后顾客将无法下单喵。',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消操作，需要把 Toggle 的状态在 UI 上改回去 (因为 Toggle 点击后视觉上已经变了)
          // 通过重新赋值触发状态刷新
          const originalStatus = this.shopStatus;
          this.shopStatus = -1; // 先改成一个无效值
          setTimeout(() => {
            this.shopStatus = originalStatus; // 再改回来，强制 UI 刷新
          }, 10);
        }
      },
      secondaryButton: {
        value: '确认',
        fontColor: isOpening ? $r('app.color.theme_color') : Color.Red,
        action: async () => {
          try {
            await ShopService.setStatus(targetStatus);
            this.shopStatus = targetStatus;
            promptAction.showToast({ message: targetStatus === 1 ? '店铺已开始营业喵！' : '店铺已打烊喵~' });
          } catch (e) {
            this.loadShopInfo(); 
          }
        }
      }
    });
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('店铺管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)

      // 营业状态卡片
      Column() {
        Row() {
          Image(this.shopInfo?.avatar || $r('app.media.app_logo'))
            .width(50)
            .height(50)
            .borderRadius(25) // 圆形头像
            .margin({ right: 15 })

          Column() {
            Text(this.shopInfo?.name || '我的店铺')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_main'))
              .margin({ bottom: 4 })
            Text(this.shopStatus === 1 ? '营业中 · 顾客可下单' : '打烊中 · 暂停接单')
              .fontSize(14)
              .fontColor(this.shopStatus === 1 ? '#4CAF50' : $r('app.color.text_secondary')) // 营业绿色，打烊灰色
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.shopStatus === 1 })
            .selectedColor($r('app.color.theme_color'))
            .onChange((isOn: boolean) => {
              this.updateStatus(isOn ? 1 : 0);
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
      }
      .padding({ left: 15, right: 15, top: 10 })

            // 其他功能菜单 (占位)

            List() {

              ListItem() {

                this.MenuItem('菜品管理', '管理您的美味佳肴', 'DishManagePage')

              }

              ListItem() {

                this.MenuItem('套餐管理', '组合优惠更好卖喵', 'SetmealManagePage')

              }

              ListItem() {

                this.MenuItem('分类管理', '让菜单井井有条', 'CategoryManagePage')

              }

            }
      .margin({ top: 20 })
      .padding({ left: 15, right: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

    @Builder
    MenuItem(title: string, subTitle: string, targetPage: string) {
      Row() {
        Column() {
          Text(title).fontSize(16).fontColor($r('app.color.text_main')).fontWeight(FontWeight.Medium)
          Text(subTitle).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)
        
        Blank()
        
        Image($r('app.media.startIcon')) // 这里用前进箭头图标喵
          .width(16)
          .height(16)
          .opacity(0.3)
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ bottom: 10 })
      .onClick(() => {
        this.pageStack.pushPath({ name: targetPage });
      })
    }}
