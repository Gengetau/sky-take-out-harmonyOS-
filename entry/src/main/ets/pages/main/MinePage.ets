import { promptAction } from '@kit.ArkUI';
import { UserInfoVO } from '../../model/entity/LoginModel';
import { AuthService } from '../../service/AuthService';

/**
 * 我的页面 (美团风格版 - 终极修复版 ✨)
 */
@Component
export struct MinePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('currentUserInfo') userInfo: UserInfoVO | null = null;
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.loadUserInfo();
  }

  async loadUserInfo() {
    this.isLoading = true;
    try {
      const info = await AuthService.getUserInfo();
      if ( info ) {
        // 更新全局状态，这会自动同步到 UserProfilePage
        AppStorage.setOrCreate('currentUserInfo', info);
      }
    } catch (err) {
      console.error('加载用户信息失败', err);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      List() {
        // --- 1. 头部区域 ---
        ListItem() {
          Stack({ alignContent: Alignment.Top }) {
            // 背景色块 - 黄色系
            Column()
              .width('100%')
              .height(180)
              .backgroundColor('#FFCC00')

            // 核心内容容器
            Column() {
              // 1.1 顶部工具栏 (对齐设置与客服)
              Row({ space: 20 }) {
                Blank()
                SymbolGlyph($r('sys.symbol.service'))
                  .fontSize(24)
                  .fontColor([ '#333' ])
                  .onClick(() => promptAction.showToast({ message: '客服小姐姐正在赶来喵~' }))

                SymbolGlyph($r('sys.symbol.gearshape'))
                  .fontSize(24)
                  .fontColor([ '#333' ])
                  .onClick(() => {
                    this.pageStack.pushPath({ name: 'SettingsPage' });
                  })
              }
              .width('100%')
              .padding({ top: 40, right: 20 })

              // 1.2 用户信息区域
              Row({ space: 15 }) {
                Image(this.userInfo?.avatar || $r('app.media.logo'))
                  .width(64)
                  .height(64)
                  .borderRadius(32)
                  .backgroundColor(Color.White)
                  .objectFit(ImageFit.Cover)

                Column({ space: 6 }) {
                  Row() {
                    Text(this.userInfo?.name || '立即登录')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    if ( this.userInfo?.openid ) {
                      Image($r('app.media.wechat')).width(16).height(16).margin({ left: 6 })
                    }
                  }

                  // 个人主页链接
                  Row() {
                    Text('个人主页')
                      .fontSize(12)
                      .fontColor('#555')
                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(12)
                      .fontColor([ '#555' ])
                  }
                  .backgroundColor('rgba(255,255,255,0.4)')
                  .padding({
                    left: 10,
                    right: 6,
                    top: 3,
                    bottom: 3
                  })
                  .borderRadius(12)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 24, top: 15 })
              .onClick(() => {
                this.pageStack.pushPath({ name: 'UserProfilePage' });
              })
            }
            .width('100%')
          }
          .width('100%')
          .height(180)
        }

        // --- 2. 订单入口栏 (悬浮效果) ---
        ListItem() {
          Column() {
            Row() {
              Text('我的订单').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
              Blank()
              Row() {
                Text('全部订单').fontSize(12).fontColor('#999')
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(12)
                  .fontColor([ '#999' ])
              }
            }
            .width('100%')
            .padding({
              left: 16,
              right: 12,
              top: 16,
              bottom: 16
            })

            // 保持图标设置不动的四个入口
            Flex({ justifyContent: FlexAlign.SpaceAround }) {
              this.OrderIconItem($r('sys.symbol.doc_plaintext'), '全部订单')
              this.OrderIconItem($r('sys.symbol.clock'), '待收货')
              this.OrderIconItem($r('sys.symbol.ellipsis_message'), '待评价')

              // 售后图标 - 使用SVG
              Column({ space: 5 }) {
                Image($r('app.media.ic_refund'))
                  .width(28)
                  .height(28)
                Text('退款/售后')
                  .fontSize(12)
                  .fontColor('#333')
              }
              .onClick(() => {
                promptAction.showToast({ message: '退款/售后 页面正在装修喵~' });
              })
            }
            .padding({ bottom: 16 })
          }
          .width('92%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ top: -25 })
          .shadow({ radius: 15, color: '#0a000000', offsetY: 4 })
        }
        .width('100%')
        .align(Alignment.Top)

        // --- 3. 功能列表分组 ---
        ListItemGroup({ header: this.GroupHeader('我的资产') }) {
          ListItem() {
            this.FuncItem($r('sys.symbol.envelope'), '我的红包', '5个可用')
          }

          ListItem() {
            this.FuncItem($r('sys.symbol.map_badge_local'), '我的地址', '', () => {
              this.pageStack.pushPath({ name: 'AddressBookPage' });
            })
          }
        }
        .backgroundColor(Color.White)
        .margin({ left: 16, right: 16, top: 16 })
        .borderRadius(16)
        .divider({
          strokeWidth: 0.5,
          color: '#F2F2F2',
          startMargin: 52,
          endMargin: 16
        })

        ListItemGroup({ header: this.GroupHeader('更多服务') }) {
          ListItem() {
            this.FuncItem($r('sys.symbol.person_badge_plus'), '商家入驻')
          }

          ListItem() {
            this.FuncItem($r('sys.symbol.questionmark_circle'), '帮助与反馈')
          }

          ListItem() {
            this.FuncItem($r('sys.symbol.info_circle'), '关于妮娅')
          }
        }
        .backgroundColor(Color.White)
        .margin({
          left: 16,
          right: 16,
          top: 16,
          bottom: 30
        })
        .borderRadius(16)
        .divider({
          strokeWidth: 0.5,
          color: '#F2F2F2',
          startMargin: 52,
          endMargin: 16
        })

      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F7F8FA')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  // 订单入口小组件
  @Builder
  OrderIconItem(icon: Resource, title: string) {
    Column({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(26)
        .fontColor([ '#333' ])
      Text(title)
        .fontSize(12)
        .fontColor('#444')
    }
    .onClick(() => {
      promptAction.showToast({ message: `${ title } 页面正在装修喵~` });
    })
  }

  @Builder
  GroupHeader(title: string) {
    Row() {
      Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
    }
    .width('100%')
    .padding({ left: 16, top: 16, bottom: 8 })
  }

  @Builder
  FuncItem(icon: Resource, title: string, subInfo: string = '', onClick?: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([ '#FFCC00' ])
        .margin({ right: 14 })

      Text(title).fontSize(16).fontColor('#333').layoutWeight(1)

      if ( subInfo ) {
        Text(subInfo).fontSize(13).fontColor('#999').margin({ right: 6 })
      }

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([ '#CCC' ])
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if ( onClick ) {
        onClick();
      } else {
        promptAction.showToast({ message: '敬请期待喵~' });
      }
    })
  }
}