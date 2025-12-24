import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { fileIo, picker } from '@kit.CoreFileKit';
import { UserInfoVO } from '../../model/entity/LoginModel';
import { AuthService } from '../../service/AuthService';

/**
 * ✏️ 修改昵称的弹窗
 */
@CustomDialog
struct EditNameDialog {
  controller: CustomDialogController;
  @Link name: string;
  onConfirm: () => void = () => {};

  build() {
    Column({ space: 15 }) {
      Text('修改昵称').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })
      TextInput({ text: this.name, placeholder: '请输入新昵称' })
        .width('100%')
        .height(50)
        .onChange((val) => this.name = val)
      
      Row({ space: 20 }) {
        Button('取消').layoutWeight(1).backgroundColor('#F5F5F5').fontColor('#666')
          .onClick(() => this.controller.close())
        Button('确定').layoutWeight(1).backgroundColor('#FFCC00').fontColor('#333')
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }.width('100%').margin({ top: 10 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

/**
 * 📝 修改简介的弹窗
 */
@CustomDialog
struct EditProfileDialog {
  controller: CustomDialogController;
  @Link profile: string;
  onConfirm: () => void = () => {};

  build() {
    Column({ space: 15 }) {
      Text('个人简介').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })
      TextArea({ text: this.profile, placeholder: '介绍一下自己吧喵~' })
        .width('100%')
        .height(100)
        .onChange((val) => this.profile = val)
      
      Row({ space: 20 }) {
        Button('取消').layoutWeight(1).backgroundColor('#F5F5F5').fontColor('#666')
          .onClick(() => this.controller.close())
        Button('确定').layoutWeight(1).backgroundColor('#FFCC00').fontColor('#333')
          .onClick(() => {
            this.onConfirm();
            this.controller.close();
          })
      }.width('100%').margin({ top: 10 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

/**
 * 🚻 性别选择弹窗
 */
@CustomDialog
struct SexSelectDialog {
  controller: CustomDialogController;
  onSelect: (sex: string) => void = () => {};

  build() {
    Column() {
      Text('选择性别')
        .fontSize(16)
        .fontColor('#999')
        .margin({ top: 15, bottom: 15 })
      
      Divider().color('#F0F0F0')

      Text('男')
        .width('100%')
        .height(56)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontColor('#333')
        .onClick(() => {
          this.onSelect('1');
          this.controller.close();
        })
      
      Divider().color('#F0F0F0')

      Text('女')
        .width('100%')
        .height(56)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontColor('#333')
        .onClick(() => {
          this.onSelect('0');
          this.controller.close();
        })

      Divider().height(8).color('#F7F8FA')

      Text('取消')
        .width('100%')
        .height(56)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontColor('#333')
        .onClick(() => this.controller.close())
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

/**
 * 👤 个人信息页面
 */
@Component
export struct UserProfilePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('currentUserInfo') userInfo: UserInfoVO | null = null;
  @State isLoading: boolean = false;

  // 本地 State
  @State currentName: string = '';
  @State currentProfile: string = '';
  @State currentSex: string = '';
  @State currentAvatar: string = '';
  @State currentMeowId: string = '';
  @State currentCreateTime: string = '';

  @State tempName: string = '';
  @State tempProfile: string = '';

  // 弹窗控制器
  nameEditController: CustomDialogController | null = new CustomDialogController({
    builder: EditNameDialog({
      name: $tempName,
      onConfirm: (): void => { this.saveField('name', this.tempName) }
    }),
    alignment: DialogAlignment.Center
  });

  profileEditController: CustomDialogController | null = new CustomDialogController({
    builder: EditProfileDialog({
      profile: $tempProfile,
      onConfirm: (): void => { this.saveField('profile', this.tempProfile) }
    }),
    alignment: DialogAlignment.Center
  });

  sexSelectController: CustomDialogController | null = new CustomDialogController({
    builder: SexSelectDialog({
      onSelect: (sex: string): void => { this.saveField('sex', sex) }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  async aboutToAppear() {
    if (this.userInfo) {
      this.syncToLocalState(this.userInfo);
    }
    this.loadUserInfo();
  }

  // 🔄 同步到本地 State
  syncToLocalState(info: UserInfoVO) {
    this.currentName = info.name;
    this.currentProfile = info.profile || '未填写';
    this.currentSex = info.sex;
    this.currentAvatar = info.avatar;
    this.currentMeowId = info.meowId;
    this.currentCreateTime = info.createTime;
    
    this.tempName = info.name;
    this.tempProfile = info.profile || '';
  }

  async loadUserInfo() {
    if (!this.userInfo) this.isLoading = true;
    try {
      console.info(`喵！[loadUserInfo] 开始拉取... t=${Date.now()}`);
      // 加时间戳防缓存
      const info = await AuthService.getUserInfo();
      if (info) {
        console.info(`喵！[loadUserInfo] 拉取成功: name=${info.name}`);
        this.userInfo = info; 
        this.syncToLocalState(info);
      }
    } catch (err) {
      // Error
    } finally {
      this.isLoading = false;
    }
  }

  // 📸 上传头像
  async handleUploadAvatar() {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoViewPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);

      if ( photoSelectResult && photoSelectResult.photoUris.length > 0 ) {
        const uri = photoSelectResult.photoUris[0];
        this.isLoading = true;

        const context = getContext(this) as common.UIAbilityContext;
        const fileName = `avatar_${ Date.now() }.jpg`;
        const cachePath = `${ context.cacheDir }/${ fileName }`;

        const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
        const stat = fileIo.statSync(file.fd);
        if (stat.size > 2 * 1024 * 1024) {
          fileIo.closeSync(file);
          promptAction.showToast({ message: '图片太大了喵，请选择小于2MB的图片！' });
          this.isLoading = false;
          return;
        }
        fileIo.copyFileSync(file.fd, cachePath);
        fileIo.closeSync(file);

        // Upload
        const newAvatarUrl = await AuthService.uploadAvatar(cachePath);
        
        // 立即刷新
        this.currentAvatar = newAvatarUrl;
        
        if (this.userInfo) {
           const newUserInfo: UserInfoVO = {
            id: this.userInfo.id,
            openid: this.userInfo.openid,
            meowId: this.userInfo.meowId,
            name: this.userInfo.name,
            phone: this.userInfo.phone,
            sex: this.userInfo.sex,
            avatar: newAvatarUrl, 
            profile: this.userInfo.profile,
            createTime: this.userInfo.createTime
          };
          this.userInfo = newUserInfo;
          AppStorage.setOrCreate('currentUserInfo', newUserInfo);
        }
        
        promptAction.showToast({ message: '头像更新成功喵！' });
        this.loadUserInfo();
      }
    } catch (err) {
      console.error('上传头像失败:', err);
    } finally {
      this.isLoading = false;
    }
  }

  // ✏️ 修改字段
  async saveField(code: string, value: string) {
    if (!this.userInfo) return;
    this.isLoading = true;
    try {
      console.info(`喵！[saveField] 请求修改: ${code} -> ${value}`);
      await AuthService.updateUserSingleInfo(code, value);
      
      // ✅ 强制本地立即刷新
      if (code === 'name') this.currentName = value;
      if (code === 'profile') this.currentProfile = value;
      if (code === 'sex') this.currentSex = value;
      
      // 这里的 log 用于验证本地 State 是否变了
      console.info(`喵！[saveField] 本地State已更新: currentName=${this.currentName}`);

      // 构造新对象同步全局
      const newUserInfo: UserInfoVO = {
        id: this.userInfo.id,
        openid: this.userInfo.openid,
        meowId: this.userInfo.meowId,
        name: this.currentName, // 使用最新的本地值
        phone: this.userInfo.phone,
        sex: this.currentSex,
        avatar: this.userInfo.avatar,
        profile: this.currentProfile,
        createTime: this.userInfo.createTime
      };
      
      this.userInfo = newUserInfo;
      AppStorage.setOrCreate('currentUserInfo', newUserInfo);
      
      promptAction.showToast({ message: '修改成功喵！' });
      
      this.loadUserInfo();
    } catch (err) {
      // Error
    } finally {
      this.isLoading = false;
    }
  }

  handleEditSex() {
    this.sexSelectController?.open();
  }

  build() {
    NavDestination() {
      Column() {
        if (this.userInfo) {
          List() {
            // 0. 头像
            ListItem() {
              Column() {
                Stack({ alignContent: Alignment.BottomEnd }) {
                  Image(this.currentAvatar || $r('app.media.logo'))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                    .shadow({ radius: 10, color: '#20000000', offsetY: 5 })
                  
                  Row() {
                    SymbolGlyph($r('sys.symbol.camera'))
                      .fontSize(16)
                      .fontColor([Color.White])
                  }
                  .width(30)
                  .height(30)
                  .backgroundColor('#99000000')
                  .borderRadius(15)
                  .justifyContent(FlexAlign.Center)
                  .border({ width: 2, color: Color.White })
                }
                .margin({ top: 30, bottom: 30 })
                .onClick(() => this.handleUploadAvatar())
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }

            // 1. 昵称 (直接内联 UI，确保响应式)
            ListItem() {
              Row() {
                Text('昵称').fontSize(16).fontColor('#333')
                Blank()
                Text(this.currentName) // 🔥 直接绑定本地 @State
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ right: 10 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ maxWidth: '60%' })
                
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#CCC'])
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
              .onClick(() => {
                this.tempName = this.currentName;
                this.nameEditController?.open();
              })
            }

            // 2. Meow号
            ListItem() {
              Row() {
                Text('Meow号').fontSize(16).fontColor('#333')
                Blank()
                Text(this.currentMeowId || '未设置')
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ right: 10 })
                
                Blank().width(16) // 占位
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
            }

            // 3. 性别
            ListItem() {
              Row() {
                Text('性别').fontSize(16).fontColor('#333')
                Blank()
                Text(this.currentSex === '1' ? '男' : (this.currentSex === '0' ? '女' : '未知'))
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ right: 10 })
                
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#CCC'])
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
              .onClick(() => this.handleEditSex())
            }

            // 4. 简介
            ListItem() {
              Row() {
                Text('个人简介').fontSize(16).fontColor('#333')
                Blank()
                Text(this.currentProfile)
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ right: 10 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ maxWidth: '60%' })
                
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#CCC'])
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
              .onClick(() => {
                this.tempProfile = (this.currentProfile === '未填写') ? '' : this.currentProfile;
                this.profileEditController?.open();
              })
            }

            // 5. 注册时间
            ListItem() {
              Row() {
                Text('注册时间').fontSize(16).fontColor('#333')
                Blank()
                Text(this.currentCreateTime)
                  .fontSize(16)
                  .fontColor('#666')
                  .margin({ right: 10 })
                
                Blank().width(16)
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
            }
          }
          .width('100%')
          .height('100%')
          .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 16, endMargin: 0 })
          .backgroundColor('#F7F8FA')
        } else if (this.isLoading) {
          Column() {
            LoadingProgress().width(50).height(50)
          }
          .width('100%')
          .margin({ top: 100 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('个人信息')
    .hideTitleBar(false)
  }
}

@Builder
export function UserProfilePageBuilder() {
  UserProfilePage()
}
