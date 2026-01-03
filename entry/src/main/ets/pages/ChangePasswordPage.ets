import { promptAction } from '@kit.ArkUI';
import { PasswordEditDTO } from '../model/EmployeeLoginModel';
import { AuthService } from '../service/AuthService';

@Component
export struct ChangePasswordPage {
  @Consume('pageStack') pageStack: NavPathStack;
  
  @State oldPass: string = '';
  @State newPass: string = '';
  @State confirmPass: string = '';
  @State isLoading: boolean = false;

  async handleUpdate() {
    if (!this.oldPass || !this.newPass || !this.confirmPass) {
      promptAction.showToast({ message: '请填写完整喵！' });
      return;
    }
    if (this.newPass !== this.confirmPass) {
      promptAction.showToast({ message: '两次输入的新密码不一致喵！' });
      return;
    }

    this.isLoading = true;
    try {
      await AuthService.updatePassword(this.oldPass, this.newPass);
      promptAction.showToast({ message: '密码修改成功，请重新登录喵！' });
      
      // 修改密码后通常需要重新登录
      await AuthService.logout();
      this.pageStack.clear();
      this.pageStack.pushPath({ name: 'Login' });
    } catch (e) {
      // 错误已处理
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        Column({ space: 20 }) {
          TextInput({ placeholder: '请输入旧密码', text: this.oldPass })
            .type(InputType.Password)
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange(val => this.oldPass = val)

          TextInput({ placeholder: '请输入新密码', text: this.newPass })
            .type(InputType.Password)
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange(val => this.newPass = val)

          TextInput({ placeholder: '请再次输入新密码', text: this.confirmPass })
            .type(InputType.Password)
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange(val => this.confirmPass = val)
        }
        .width('90%')
        .margin({ top: 40 })

        Button(this.isLoading ? '提交中...' : '确认修改')
          .width('90%')
          .height(45)
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .margin({ top: 40 })
          .onClick(() => this.handleUpdate())
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .title('修改密码')
  }
}
