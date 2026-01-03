import { AuthService } from '../../service/AuthService';
import { EmployeeLoginVO } from '../../model/EmployeeLoginModel';
import { PreferencesUtil } from '../../common/PreferencesUtil';
import { promptAction } from '@kit.ArkUI';
import { ShopInfoVO } from '../../model/ShopModel';

@Component
export struct MineContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @State employeeInfo: EmployeeLoginVO | null = null;
  @StorageLink('shopInfo') shopInfo: ShopInfoVO | null = null;

  async aboutToAppear() {
    this.employeeInfo = AppStorage.get<EmployeeLoginVO>('employeeInfo') || null;
  }

  async handleLogout() {
    try {
      await AuthService.logout();
      promptAction.showToast({ message: '已退出登录喵！' });
      this.pageStack.clear();
      this.pageStack.pushPath({ name: 'Login' });
    } catch (e) {
      promptAction.showToast({ message: '退出失败，请重试喵' });
    }
  }

  build() {
    Column() {
      // 1. 头部背景
      Column() {
        Row() {
          // 优先显示店铺Logo，否则显示启动图标喵
          Image(this.shopInfo?.avatar || $r('app.media.startIcon'))
            .width(60)
            .height(60)
            .borderRadius(30)
            .margin({ right: 15 })
            .backgroundColor(Color.White)
            .objectFit(ImageFit.Cover)
            .padding(2)
          
          Column() {
            Text(this.employeeInfo?.name || '商家员工')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(this.shopInfo?.name || '未绑定店铺')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ top: 60, bottom: 40, left: 20, right: 20 })
      }
      .width('100%')
      .backgroundColor($r('app.color.theme_color')) 
      
      // 2. 菜单列表
      List() {
        // ✨ 新增店铺设置入口
        ListItem() {
          this.MenuItem('店铺设置', this.shopInfo?.status === 1 ? '营业中' : '已打烊', () => {
            this.pageStack.pushPath({ name: 'ShopInfoPage' });
          })
        }

        ListItem() {
          this.MenuItem('账号设置', '修改密码等', () => {
            promptAction.showToast({ message: '功能建设中喵~' });
          })
        }
        
        ListItem() {
          this.MenuItem('关于我们', '版本 v1.0.0', () => {
            promptAction.showToast({ message: '妮娅一直在陪着您喵！🐾' });
          })
        }
        
        ListItem() {
          Button('退出登录')
            .width('100%')
            .height(50)
            .backgroundColor(Color.White)
            .fontColor(Color.Red)
            .fontSize(16)
            .margin({ top: 30 })
            .onClick(() => {
              AlertDialog.show({
                title: '提示',
                message: '确定要退出登录吗喵？',
                primaryButton: { value: '取消', action: () => {} },
                secondaryButton: {
                  value: '退出',
                  fontColor: Color.Red,
                  action: () => { this.handleLogout(); }
                }
              })
            })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding(15)
      .margin({ top: -20 }) 
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  MenuItem(title: string, subTitle: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(16).fontColor($r('app.color.text_main'))
      Blank()
      Text(subTitle).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ right: 10 })
      Image($r('app.media.startIcon')) // 箭头
        .width(16)
        .height(16)
        .opacity(0.3)
    }
    .width('100%')
    .height(55)
    .padding({ left: 15, right: 15 })
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 10 })
    .onClick(onClick)
  }
}