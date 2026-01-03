import { MessageEntity, MessageRdb } from '../../common/MessageRdb';
import { MessageManager } from '../../manager/MessageManager';
import { EmployeeLoginVO } from '../../model/EmployeeLoginModel';
import { SessionModel } from '../../model/MessageModel';
import { ShopInfoVO } from '../../model/ShopModel';

/**
 * 聊天页参数类
 */
export class ChatPageParam {
  sessionId: string;
  title: string;
  targetAvatar: string;

  constructor(sessionId: string, title: string, targetAvatar: string) {
    this.sessionId = sessionId;
    this.title = title;
    this.targetAvatar = targetAvatar;
  }
}

/**
 * 聊天详情页 (隔离版)
 */
@Component
export struct ChatPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State messages: MessageEntity[] = [];
  @State inputText: string = '';
  @State sessionId: string = '';
  @State title: string = '';
  @State targetAvatar: string = ''; 
  
  @StorageLink('NewMessageSignal') @Watch('onMessageSignal') signal: number = 0;
  @StorageLink('shopInfo') shopInfo: ShopInfoVO | null = null;
  // 🐾 拿到 shopId
  @StorageLink('employeeInfo') employeeInfo: EmployeeLoginVO | null = null;
  private defaultAvatar: Resource = $r('app.media.app_logo');

  initParams(params: ChatPageParam) {
    this.sessionId = params.sessionId;
    this.title = params.title;
    this.targetAvatar = params.targetAvatar;
    MessageManager.getInstance().enterChat(this.sessionId);
    this.refreshMessages();
  }
  
  aboutToDisappear() {
    MessageManager.getInstance().leaveChat();
  }

  onMessageSignal() {
    this.refreshMessages();
  }

  async refreshMessages() {
    if (!this.employeeInfo?.shopId) return;
    const shopId = this.employeeInfo.shopId;

    // 🐾 调用带 shopId 的查询
    this.messages = await MessageRdb.getMessages(shopId, this.sessionId);
    
    // 🐾 保存会话也带上 shopId
    await MessageRdb.saveSession(shopId, new SessionModel(
      this.sessionId,
      this.title,
      this.targetAvatar,
      this.messages.length > 0 ? this.messages[this.messages.length - 1].content : '',
      Date.now(),
      0
    ));
  }

  async sendMessage() {
    if (!this.inputText.trim()) return;

    let receiverId = 0;
    if (this.sessionId.startsWith('user_')) {
      receiverId = parseInt(this.sessionId.split('_')[1]);
    } else {
      return;
    }

    await MessageManager.getInstance().sendMessage(
      this.inputText, 
      receiverId, 
      0, 
      this.title, 
      this.targetAvatar
    );

    this.inputText = '';
  }

  build() {
    NavDestination() {
      Column() {
        List() {
          ForEach(this.messages, (item: MessageEntity) => {
            ListItem() {
              Row() {
                if (item.role === 1) { // 对方
                  if (this.sessionId === 'system_notify') {
                     Image($r('app.media.app_logo'))
                      .width(40).height(40).borderRadius(20)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('#F0F0F0')
                  } else {
                     Image(this.targetAvatar ? this.targetAvatar : $r('app.media.startIcon'))
                      .width(40).height(40).borderRadius(20)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('#F0F0F0')
                  }

                  Text(item.content)
                    .backgroundColor(Color.White)
                    .fontColor('#333333')
                    .padding(12)
                    .borderRadius(8)
                    .margin({ left: 10 })
                    .constraintSize({ maxWidth: '70%' })
                } else { // 我
                  Text(item.content)
                    .backgroundColor($r('app.color.theme_color'))
                    .fontColor('#333333')
                    .padding(12)
                    .borderRadius(8)
                    .margin({ right: 10 })
                    .constraintSize({ maxWidth: '70%' })

                  Image(this.shopInfo?.avatar ? this.shopInfo.avatar : this.defaultAvatar)
                    .width(40).height(40).borderRadius(20)
                    .objectFit(ImageFit.Cover)
                }
              }
              .width('100%')
              .justifyContent(item.role === 1 ? FlexAlign.Start : FlexAlign.End)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            }
          })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')

        if (this.sessionId !== 'system_notify') {
          Row() {
            TextInput({ text: this.inputText, placeholder: '回复用户...' })
              .layoutWeight(1)
              .height(40)
              .backgroundColor('#F9F9F9')
              .borderRadius(20)
              .padding({ left: 16 })
              .onChange((value) => this.inputText = value)
              .onSubmit(() => this.sendMessage())

            Button('发送')
              .height(36)
              .fontSize(14)
              .onClick(() => this.sendMessage())
              .margin({ left: 12 })
              .backgroundColor($r('app.color.theme_color'))
              .fontColor('#333333')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Color.White)
          .shadow({ radius: 2, color: '#10000000', offsetY: -1 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.title)
    .onReady((ctx: NavDestinationContext) => {
      const params = ctx.pathInfo.param as ChatPageParam;
      if (params) {
        this.initParams(params);
      }
    })
  }
}
