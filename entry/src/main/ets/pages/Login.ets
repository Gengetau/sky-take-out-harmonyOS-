import { promptAction } from '@kit.ArkUI';
import { UserLoginDTO } from '../model/entity/LoginModel';
import { AuthService } from '../service/AuthService';

@Builder
export function LoginBuilder(): void {
  Login()
    .onAppear(() => { // 👈 把日志藏在这里！
      console.info('喵！LoginBuilder 成功执行，Login 组件已挂载！');
    });
}

/**
 * 登陆页面
 */
@Component
struct Login {
  @Consume('pageStack') pageStack: NavPathStack; //  接收路由栈，以便跳转
  @State phone: string = '';
  @State code: string = '';
  @State countDown: number = 0;
  private timer: number = -1;
  @State isLoading: boolean = false; //登陆加载状态

  // ⏱️ 倒计时逻辑
  startCountDown() {
    this.countDown = 60;
    this.timer = setInterval(() => {
      this.countDown--;
      if ( this.countDown <= 0 ) {
        clearInterval(this.timer);
      }
    }, 1000);
  }

  // 📨 发送验证码逻辑
  async handleSendCode() {
    if ( this.phone.length !== 11 ) {
      promptAction.showToast({ message: '请输入11位手机号喵！' });
      return;
    }

    // 1. 开始倒计时
    this.startCountDown();

    // 2. 调用 Service 发送
    const verifyCode = await AuthService.sendVerifyCode(this.phone);

    if ( verifyCode ) {
      // 🎭 3. 模拟短信弹窗 (这会让体验超级棒！)
      // 延迟一点点，模拟网络传输
      setTimeout(() => {
        promptAction.showDialog({
          title: '📨 新消息',
          message: `【Meow外卖】您的验证码是：${ verifyCode }。您正在登录，若非本人操作请忽略。`,
          buttons: [
            { text: '关闭', color: '#999999' },
            { text: '自动填写', color: '#0D9FFB' }// 贴心的功能
          ]
        }).then((res) => {
          if ( res.index === 1 ) {
            this.code = verifyCode; // 自动回填
          }
        });
      }, 500);
    } else {
      // 发送失败，重置倒计时
      clearInterval(this.timer);
      this.countDown = 0;
    }
  }

  // 🔐 登录逻辑
  async handleLogin() {
    if (!this.phone || !this.code ) {
      promptAction.showToast({ message: '请填写完整喵！' });
      return;
    }

    this.isLoading = true;

    // 1. 组装 DTO
    const dto = new UserLoginDTO(this.phone, this.code);

    // 2. 调用登录
    const success = await AuthService.login(dto);

    console.info("是否登录成功:", { success })

    this.isLoading = false;

    if ( success ) {
      promptAction.showToast({ message: '登录成功，准备点餐！🍔' });
      // 3. 跳转主页
      this.pageStack.replacePath({ name: 'MainTabs' }, true);
    }
  }

  build() {
    NavDestination() {
      Column() {
        // logo展示
        Column({ space: 15 }) {
          Image($r('app.media.logo'))
            .height(150)
            .width('80%')
            .objectFit(ImageFit.Contain)
          Text($r('app.string.slogan'))
            .fontSize(27)
            .fontColor('#333333')
            .fontStyle(FontStyle.Italic)
        }
        .margin({ bottom: 50 })

        // 输入区域
        Column({ space: 15 }) {
          TextInput({ placeholder: '手机号' })
            .height(50)
            .type(InputType.PhoneNumber)
            .backgroundColor(Color.White)
            .onChange((val) => {
              this.phone = val;
            })
          Row() {
            TextInput({ placeholder: '验证码', text: this.code })
              .height(50)
              .type(InputType.Number)
              .backgroundColor(Color.White)
              .width('70%')
              .onChange((val) => {
                this.code = val;
              })
            Button(this.countDown > 0 ? `${ this.countDown }s` : '发送验证码')
              .fontSize(12)
              .type(ButtonType.Capsule)
              // 💡 体验优化：倒计时期间禁用按钮，颜色变灰
              .backgroundColor(this.countDown > 0 ? '#CCCCCC' : '#0D9FFB')
              .enabled(this.countDown === 0) // 只有倒计时为 0 时才能点
              .onClick(() => {
                this.handleSendCode();
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
        }
        .width('95%')

        // 登录按钮
        Row() {
          Button() {
            Row() {
              if ( this.isLoading ) {
                LoadingProgress().width(20).height(20).color(Color.White).margin({ right: 5 })
              }
              Text(this.isLoading ? '登 录 中...' : '登 录')
                .fontColor(Color.White)
                .fontSize(18)
            }
          }
          .type(ButtonType.Capsule)
          .width('80%')
          .height(50)
          .backgroundColor('#ffcc00') // 苍穹外卖的主题黄
          .onClick(() => {
            this.handleLogin() // 调用下面的逻辑
          })
          // 加载中禁止点击
          .enabled(!this.isLoading)
        }
        .margin({ top: 50 })

        Blank()
          .layoutWeight(1)

        Row() {
          Text('其他方式登录')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ bottom: 10 })
        }

        Row() {
          this.ThirdPartyIcon($r('app.media.wechat'))
          this.ThirdPartyIcon($r('app.media.qq'))
          this.ThirdPartyIcon($r('app.media.alipay'))
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .margin({ bottom: 30 }) // 离底部有点距离
      }
      .width('100%')
      .height('100%')
      .backgroundColor("#f5f5f5") // 背景色稍微淡一点，眼睛舒服喵
    }
    .hideTitleBar(true)
  }

  @Builder
  ThirdPartyIcon(icon: Resource) {
    Button() {
      Image(icon).width(40).height(40).objectFit(ImageFit.Contain)
    }
    .type(ButtonType.Circle)
    .width(50)
    .height(50)
    .backgroundColor(Color.White) // 给个白色底，图标更清晰
    .onClick(() => {
      promptAction.showToast({ message: '暂未开放' })
    })
  }
}

export { Login };
