import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../service/AuthService';

/**
 * 设置页面
 */
@Component
export struct SettingsPage {
  @Consume('pageStack') pageStack: NavPathStack;

  async handleLogout() {
    AlertDialog.show({
      title: '退出登录',
      message: '主人真的要离开妮娅吗？😿',
      primaryButton: {
        value: '取消', action: () => {
        }
      },
      secondaryButton: {
        value: '确认退出',
        action: async() => {
          await AuthService.logout();
          this.pageStack.clear();
          this.pageStack.pushPath({ name: 'Login' });
        }
      }
    });
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([ '#333' ])
            .onClick(() => this.pageStack.pop())

          Text('设置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 24 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)

        List() {
          ListItemGroup() {
            this.SettingItem('个人资料', () => {
              this.pageStack.pushPath({ name: 'UserProfilePage' });
            })
            this.SettingItem('账号安全', () => {
              this.pageStack.pushPath({ name: 'AccountSecurityPage' });
            })
          }
          .backgroundColor(Color.White)
          .margin({ top: 12 })
          .divider({
            strokeWidth: 0.5,
            color: '#F0F0F0',
            startMargin: 16,
            endMargin: 16
          })

          ListItemGroup() {
            this.SettingItem('清理缓存', () => promptAction.showToast({ message: '缓存已清理干净喵！✨' }))
            this.SettingItem('关于我们', () => promptAction.showToast({ message: '妮娅 v1.0' }))
          }
          .backgroundColor(Color.White)
          .margin({ top: 12 })
          .divider({
            strokeWidth: 0.5,
            color: '#F0F0F0',
            startMargin: 16,
            endMargin: 16
          })

          // 退出按钮
          ListItem() {
            Button('退出登录')
              .width('90%')
              .height(45)
              .margin({ top: 40 })
              .type(ButtonType.Capsule)
              .backgroundColor(Color.White)
              .fontColor('#FF3B30')
              .border({ width: 1, color: '#FF3B30' })
              .onClick(() => this.handleLogout())
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  SettingItem(title: string, onClick: () => void) {
    ListItem() {
      Row() {
        Text(title).fontSize(16).fontColor('#333').layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([ '#CCC' ])
      }
      .width('100%')
      .height(54)
      .padding({ left: 16, right: 16 })
      .onClick(onClick)
    }
  }
}
