import { AuthService } from '../service/AuthService';
import { EmployeeLoginDTO } from '../model/EmployeeLoginModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct Login {
  @Consume('pageStack') pageStack: NavPathStack;
  @State username: string = ''; // 🐾 已清空默认值
  @State password: string = ''; // 🐾 已清空默认值
  @State isLoading: boolean = false;
  @State isLoginMode: boolean = false; // 控制显示欢迎页还是登录页

  build() {
    NavDestination() {
      Column() {
        // 1. Logo 区域 (共享)
        Image($r('app.media.app_logo'))
          .width(100)
          .height(100)
          .margin({ top: 100, bottom: 20 })
          .objectFit(ImageFit.Contain)

        Text('Meow外卖 · 商家版')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .margin({ bottom: 50 })

        if (this.isLoginMode) {
          // === 登录模式 ===
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
                this.pageStack.clear();
                this.pageStack.pushPath({ name: 'MainTabs' });
              } catch (err) {
              } finally {
                this.isLoading = false;
              }
            })
            
          Text('返回选择')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 20 })
            .onClick(() => {
              this.isLoginMode = false;
            })

        } else {
          // === 欢迎模式 ===
          Column({ space: 20 }) {
            Button('已经入驻？去登录')
              .width('80%')
              .height(50)
              .backgroundColor($r('app.color.theme_color'))
              .fontColor(Color.Black)
              .fontSize(18)
              .onClick(() => {
                this.isLoginMode = true;
              })

            Button('我要入驻 Meow')
              .width('80%')
              .height(50)
              .backgroundColor(Color.White)
              .fontColor($r('app.color.theme_color'))
              .border({ width: 1, color: $r('app.color.theme_color') })
              .fontSize(18)
              .onClick(() => {
                this.pageStack.pushPath({ name: 'RegisterPage' });
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .hideTitleBar(true)
  }
}
