import { AuthService } from '../service/AuthService';
import { EmployeeLoginDTO } from '../model/EmployeeLoginModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct Login {
  @Consume('pageStack') pageStack: NavPathStack;
  @State username: string = 'admin';
  @State password: string = '123456';
  @State isLoading: boolean = false;

  build() {
    NavDestination() {
      Column() {
        // 1. Logo 区域
        Image($r('app.media.startIcon'))
          .width(100)
          .height(100)
          .margin({ top: 100, bottom: 20 })
          .objectFit(ImageFit.Contain)

        Text('Meow外卖 · 商家版')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .margin({ bottom: 50 })

        // 2. 输入框区域
        Column({ space: 15 }) {
          TextInput({ placeholder: '请输入账号', text: this.username })
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange((value) => {
              this.username = value;
            })

          TextInput({ placeholder: '请输入密码', text: this.password })
            .type(InputType.Password)
            .height(50)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange((value) => {
              this.password = value;
            })
        }
        .width('80%')

        // 3. 登录按钮
        Button(this.isLoading ? '登录中...' : '登 录')
          .width('80%')
          .height(45)
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .fontSize(18)
          .margin({ top: 40 })
          .enabled(!this.isLoading)
          .onClick(async () => {
            if (this.username === '' || this.password === '') {
              promptAction.showToast({ message: '账号或密码不能为空喵！' });
              return;
            }

            this.isLoading = true;
            try {
              const dto = new EmployeeLoginDTO(this.username, this.password);
              await AuthService.login(dto);
              promptAction.showToast({ message: '登录成功喵！' });

              // 登录成功，清除路由栈并跳转到主页 (防止返回到登录页)
              this.pageStack.clear();
              this.pageStack.pushPath({ name: 'MainTabs' });

            } catch (err) {
              // 错误处理留给 HttpUtil
            } finally {
              this.isLoading = false;
            }
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
  }
}