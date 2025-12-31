import { AuthService } from '../../service/AuthService';
import { EmployeeLoginVO } from '../../model/EmployeeLoginModel';
import { PreferencesUtil } from '../../common/PreferencesUtil';
import { promptAction } from '@kit.ArkUI';

@Component
export struct MineContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @State employeeInfo: EmployeeLoginVO | null = null;

  async aboutToAppear() {
    // 从 AppStorage 获取用户信息
    this.employeeInfo = AppStorage.get<EmployeeLoginVO>('employeeInfo') || null;
  }

  async handleLogout() {
    try {
      // 1. 调用退出接口 (虽然不需要参数，但告知后端 token 失效是个好习惯)
      // TODO: 目前 AuthService.logout 只是清除本地，如果后端有接口也可以调
      
      // 2. 清除本地存储
      await AuthService.logout();
      
      promptAction.showToast({ message: '已退出登录喵！' });
      
      // 3. 跳转回登录页 (清空栈)
      this.pageStack.clear();
      this.pageStack.pushPath({ name: 'Login' });
      
    } catch (e) {
      promptAction.showToast({ message: '退出失败，请重试喵' });
    }
  }

  build() {
    Column() {
      // 头部背景
      Column() {
        Row() {
          Image($r('app.media.startIcon')) // 这里应该用员工头像，暂时用 Logo
            .width(60)
            .height(60)
            .borderRadius(30)
            .margin({ right: 15 })
            .backgroundColor(Color.White)
            .padding(5)
          
          Column() {
            Text(this.employeeInfo?.name || '商家员工')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(this.employeeInfo?.userName || 'admin')
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
      .backgroundColor($r('app.color.theme_color')) // 黄色背景
      
      // 菜单列表
      List() {
        ListItem() {
          this.MenuItem('账号设置', '修改密码等')
        }
        ListItem() {
          this.MenuItem('声音设置', '接单语音提醒开关')
        }
        ListItem() {
          this.MenuItem('关于我们', '版本 v1.0.0')
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
              // 弹窗确认
              AlertDialog.show({
                title: '提示',
                message: '确定要退出登录吗喵？',
                primaryButton: {
                  value: '取消',
                  action: () => {}
                },
                secondaryButton: {
                  value: '退出',
                  fontColor: Color.Red,
                  action: () => {
                    this.handleLogout();
                  }
                }
              })
            })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding(15)
      .margin({ top: -20 }) // 上移一点，盖住黄色背景
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  MenuItem(title: string, subTitle: string) {
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
  }
}
