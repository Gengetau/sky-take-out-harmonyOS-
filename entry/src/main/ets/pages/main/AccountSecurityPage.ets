import { promptAction } from '@kit.ArkUI';
import { UserInfoVO } from '../../model/entity/LoginModel';
import { AuthService } from '../../service/AuthService';

@CustomDialog
struct ModifyPhoneDialog {
  controller: CustomDialogController;
  @State phoneNumber: string = '';
  @State code: string = '';
  @State countdown: number = 0;
  private timer: number = -1;
  // 注入用户信息以便刷新和对比
  @Link userInfo: UserInfoVO | null;

  // ⏱️ 复用 Login 页面的倒计时逻辑
  startCountdown() {
    this.countdown = 60;
    this.timer = setInterval(() => {
      if ( this.countdown > 0 ) {
        this.countdown--;
      } else {
        clearInterval(this.timer);
      }
    }, 1000);
  }

  // 📨 获取验证码
  async handleGetCode() {
    // 1. 校验手机号长度
    if ( this.phoneNumber.length !== 11 ) {
      promptAction.showToast({ message: '请输入11位手机号喵！😿' });
      return;
    }

    // 2. 拦截相同手机号
    if ( this.userInfo && this.phoneNumber === this.userInfo.phone ) {
      promptAction.showToast({ message: '新手机号不能与当前手机号相同喵！🐱' });
      return;
    }

    this.startCountdown();

    try {
      const serverCode = await AuthService.sendVerifyCode(this.phoneNumber);
      if ( serverCode ) {
        setTimeout(() => {
          promptAction.showDialog({
            title: '📨 新消息',
            message: `【苍穹外卖】您的验证码是：${ serverCode }。您正在修改手机号，若非本人操作请忽略。`,
            buttons: [
              { text: '关闭', color: '#999999' },
              { text: '自动填写', color: '#0D9FFB' }
            ]
          }).then((res) => {
            if ( res.index === 1 ) {
              this.code = serverCode;
            }
          });
        }, 500);
      } else {
        this.countdown = 0;
        clearInterval(this.timer);
        promptAction.showToast({ message: '验证码发送失败，请重试喵' });
      }
    } catch ( err ) {
      promptAction.showToast({ message: '发送失败，请稍后再试喵~' });
      this.countdown = 0;
      clearInterval(this.timer);
    }
  }

  // ✅ 确认修改
  async handleConfirm() {
    // 1. 校验格式
    if ( this.phoneNumber.length !== 11 ) {
      promptAction.showToast({ message: '手机号格式不对喵！' });
      return;
    }

    // 2. 再次校验相同手机号
    if ( this.userInfo && this.phoneNumber === this.userInfo.phone ) {
      promptAction.showToast({ message: '新手机号不能与原手机号相同喵！🐱' });
      return;
    }

    // 3. 校验验证码
    if (!this.code || this.code.length < 4 ) {
      promptAction.showToast({ message: '验证码不正确喵！' });
      return;
    }

    try {
      await AuthService.updateUserSingleInfo('phone', this.phoneNumber);

      if ( this.userInfo ) {
        const newUserInfo: UserInfoVO = {
          id: this.userInfo.id,
          openid: this.userInfo.openid,
          meowId: this.userInfo.meowId,
          name: this.userInfo.name,
          phone: this.phoneNumber,
          sex: this.userInfo.sex,
          avatar: this.userInfo.avatar,
          profile: this.userInfo.profile,
          createTime: this.userInfo.createTime,
          idNumber: this.userInfo.idNumber
        };
        this.userInfo = newUserInfo;
        AppStorage.setOrCreate('currentUserInfo', newUserInfo);
      }

      promptAction.showToast({ message: '手机号修改成功喵！✨' });
      this.controller.close();
    } catch ( err ) {
      promptAction.showToast({ message: '修改失败，请重试喵~' });
    }
  }

  aboutToDisappear() {
    if ( this.timer !== -1 ) {
      clearInterval(this.timer);
    }
  }

  build() {
    Column({ space: 15 }) {
      Text('修改手机号码').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })

      TextInput({ placeholder: '请输入新手机号' })
        .width('100%')
        .height(50)
        .type(InputType.PhoneNumber)
        .maxLength(11)
        .onChange((val) => this.phoneNumber = val)

      Row({ space: 10 }) {
        TextInput({ placeholder: '验证码', text: this.code })
          .layoutWeight(1)
          .height(50)
          .type(InputType.Number)
          .maxLength(6)
          .onChange((val) => this.code = val)

        Button(this.countdown > 0 ? `${ this.countdown }s` : '获取验证码')
          .height(50)
          .backgroundColor(this.countdown > 0 ? '#F0F0F0' : '#FFCC00')
          .fontColor(this.countdown > 0 ? '#999' : '#333')
          .enabled(this.countdown === 0)
          .onClick(() => this.handleGetCode())
      }.width('100%')

      Row({ space: 20 }) {
        Button('取消').layoutWeight(1).backgroundColor('#F5F5F5').fontColor('#666')
          .onClick(() => this.controller.close())
        Button('确定').layoutWeight(1).backgroundColor('#FFCC00').fontColor('#333')
          .onClick(() => this.handleConfirm())
      }.width('100%').margin({ top: 10 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

@CustomDialog
struct RealNameAuthDialog {
  controller: CustomDialogController;
  @State realName: string = '';
  @State idNumber: string = '';
  @Link userInfo: UserInfoVO | null;

  // 🆔 简单的身份证格式校验 (18位)
  isValidIdNumber(id: string): boolean {
    const reg = /^\d{17}[\dXx]$/;
    return reg.test(id);
  }

  build() {
    Column({ space: 15 }) {
      Text('实名认证').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })

      TextInput({ placeholder: '真实姓名' })
        .width('100%')
        .height(50)
        .onChange((val) => this.realName = val)

      TextInput({ placeholder: '身份证号码' })
        .width('100%')
        .height(50)
        .maxLength(18)
        .onChange((val) => this.idNumber = val)

      Row({ space: 20 }) {
        Button('取消').layoutWeight(1).backgroundColor('#F5F5F5').fontColor('#666')
          .onClick(() => this.controller.close())
        Button('提交认证').layoutWeight(1).backgroundColor('#FFCC00').fontColor('#333')
          .onClick(async() => {
            // 1. 姓名校验
            if (!this.realName || this.realName.trim().length < 2 ) {
              promptAction.showToast({ message: '请输入真实的姓名喵！' });
              return;
            }

            // 2. 身份证格式校验
            if (!this.isValidIdNumber(this.idNumber) ) {
              promptAction.showToast({ message: '身份证号格式不对喵！😿' });
              return;
            }

            try {
              await AuthService.updateUserSingleInfo('idNumber', this.idNumber);

              if ( this.userInfo ) {
                const newUserInfo: UserInfoVO = {
                  id: this.userInfo.id,
                  openid: this.userInfo.openid,
                  meowId: this.userInfo.meowId,
                  name: this.userInfo.name,
                  phone: this.userInfo.phone,
                  sex: this.userInfo.sex,
                  avatar: this.userInfo.avatar,
                  profile: this.userInfo.profile,
                  createTime: this.userInfo.createTime,
                  idNumber: this.idNumber
                };
                this.userInfo = newUserInfo;
                AppStorage.setOrCreate('currentUserInfo', newUserInfo);
              }

              promptAction.showToast({ message: '实名认证成功喵！📝' });
              this.controller.close();
            } catch ( err ) {
              promptAction.showToast({ message: '认证提交失败，请重试喵~' });
            }
          })
      }.width('100%').margin({ top: 10 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

@Component
export struct AccountSecurityPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('currentUserInfo') userInfo: UserInfoVO | null = null;
  phoneDialogController: CustomDialogController = new CustomDialogController({
    builder: ModifyPhoneDialog({ userInfo: $userInfo }),
    alignment: DialogAlignment.Center
  });
  authDialogController: CustomDialogController = new CustomDialogController({
    builder: RealNameAuthDialog({ userInfo: $userInfo }),
    alignment: DialogAlignment.Center
  });

  // 🛡️ 手机号脱敏处理
  maskPhone(phone: string): string {
    if (!phone || phone.length !== 11 ) {
      return '未绑定';
    }
    return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2');
  }

  // 🆔 身份证脱敏处理
  maskIdNumber(idNumber?: string): string {
    if (!idNumber ) {
      return '未认证';
    }
    return idNumber.replace(/^(.{2}).+(.{2})$/, '$1****************$2');
  }

  async aboutToAppear() {
    const info = await AuthService.getUserInfo();
    if ( info ) {
      this.userInfo = info;
      AppStorage.setOrCreate('currentUserInfo', info);
    }
  }

  /**
   * 🗑️ 处理注销账号 (接入真实 API 9.5)
   */
  handleDeleteAccount() {
    AlertDialog.show({
      title: '⚠️ 危险操作',
      message: '注销账号将永久删除所有数据，且无法恢复。确定要继续吗喵？😿',
      primaryButton: {
        value: '我再想想',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确认注销',
        fontColor: Color.Red,
        action: async() => {
          try {
            promptAction.showToast({ message: '正在注销，江湖再见喵...' });

            // 1. 调用后端注销接口 (API 9.5)
            await AuthService.cancelAccount();

            // 2. 调用本地清理逻辑 (清理 Token, WS 等)
            await AuthService.logout();

            // 3. 跳转登录页
            this.pageStack.clear();
            this.pageStack.pushPath({ name: 'Login' });

            promptAction.showToast({ message: '账号已注销，后会有期喵 👋' });
          } catch ( err ) {
            promptAction.showToast({ message: '注销失败，请稍后重试喵' });
          }
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

          Text('账号与安全')
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
            // 📱 修改手机号码
            ListItem() {
              Row() {
                Text('修改手机号码').fontSize(16).fontColor('#333')
                Blank()
                Text(this.maskPhone(this.userInfo?.phone || ''))
                  .fontSize(14)
                  .fontColor('#999')
                  .margin({ right: 8 })
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(16)
                  .fontColor([ '#CCC' ])
              }
              .width('100%')
              .height(54)
              .padding({ left: 16, right: 16 })
              .onClick(() => this.phoneDialogController.open())
            }

            // 🆔 实名认证
            ListItem() {
              Row() {
                Text('实名认证').fontSize(16).fontColor('#333')
                Blank()
                Text(this.maskIdNumber(this.userInfo?.idNumber))
                  .fontSize(14)
                  .fontColor('#999')
                  .margin({ right: 8 })
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(16)
                  .fontColor([ '#CCC' ])
              }
              .width('100%')
              .height(54)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                if ( this.userInfo?.idNumber ) {
                  promptAction.showToast({ message: '主人已经实名认证过啦喵！✨' });
                } else {
                  this.authDialogController.open();
                }
              })
            }
          }
          .backgroundColor(Color.White)
          .margin({ top: 12 })
          .divider({
            strokeWidth: 0.5,
            color: '#F0F0F0',
            startMargin: 16,
            endMargin: 16
          })

          // 🗑️ 注销账号
          ListItem() {
            Row() {
              Text('注销账号').fontSize(16).fontColor('#FF3B30').layoutWeight(1)
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(16)
                .fontColor([ '#CCC' ])
            }
            .width('100%')
            .height(54)
            .padding({ left: 16, right: 16 })
            .onClick(() => this.handleDeleteAccount())
          }
          .backgroundColor(Color.White)
          .margin({ top: 12 })
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
}
