import { MessageEntity, MessageRdb } from '../../common/utils/MessageRdb';
import { MessageManager } from '../../manager/MessageManager';

/**
 * ✨ 定义聊天页跳转参数类
 */
export class ChatPageParam {
  sessionId: string;
  title: string;
  targetAvatar: string; // ✨ 新增：对方头像

  constructor(sessionId: string, title: string, targetAvatar: string) {
    this.sessionId = sessionId;
    this.title = title;
    this.targetAvatar = targetAvatar;
  }
}

/**
 * 聊天详情页 (NavDestination)
 */
@Component
export struct ChatPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State messages: MessageEntity[] = [];
  @State inputText: string = '';
  @State sessionId: string = '';
  @State title: string = '';
  @State targetAvatar: string = ''; // 对方头像
  // ✨ 获取我的头像 (AppStorage)
  @StorageProp('userAvatar') myAvatar: string = '';

  initParams(params: ChatPageParam) {
    this.sessionId = params.sessionId;
    this.title = params.title;
    this.targetAvatar = params.targetAvatar; // 获取对方头像

    // ✨ 进入聊天会话状态，抑制通知
    MessageManager.getInstance().enterChat(this.sessionId);

    MessageRdb.clearUnread(this.sessionId);
    this.loadMessages();
  }

  // ✨ 页面销毁或隐藏时调用
  onDisappear() {
    console.info('喵！离开聊天页，恢复通知');
    MessageManager.getInstance().leaveChat();
  }

  async loadMessages() {
    this.messages = await MessageRdb.getMessages(this.sessionId);
  }

  async sendMessage() {
    if (!this.inputText.trim() ) {
      return;
    }

    // sessionId 格式约定: "shop_123"
    let receiverId = 0;

    if ( this.sessionId.startsWith('shop_') ) {
      receiverId = parseInt(this.sessionId.split('_')[1]);
    }

    // 调用 Manager 发送消息
    // ✨ 传入当前会话的标题(商家名)和头像，确保消息列表更新正确
    await MessageManager.getInstance().sendMessage(this.inputText, receiverId, 1, this.title, this.targetAvatar);

    this.inputText = '';
    this.loadMessages(); // 刷新
  }

  build() {
    NavDestination() {
      Column() {
        // 消息列表
        List() {
          ForEach(this.messages, (item: MessageEntity) => {
            ListItem() {
              Row() {
                if ( item.role === 1 ) { // 对方发的 (左边)
                  // ✨ 使用传递进来的 targetAvatar，如果为空则显示默认 Logo
                  Image(this.targetAvatar ? this.targetAvatar : $r('app.media.shop_logo'))
                    .width(40).height(40).borderRadius(20)
                    .objectFit(ImageFit.Cover)

                  Text(item.content)
                    .backgroundColor('#FFFFFF')
                    .fontColor('#333333')
                    .padding({
                      left: 12,
                      right: 12,
                      top: 10,
                      bottom: 10
                    })
                    .borderRadius(8)
                    .margin({ left: 10 })
                    .constraintSize({ maxWidth: '70%' }) // 限制最大宽度
                } else { // 我发的 (右边)
                  // 我的气泡
                  Text(item.content)
                    .backgroundColor('#007DFF') // 品牌蓝
                    .fontColor(Color.White)
                    .padding({
                      left: 12,
                      right: 12,
                      top: 10,
                      bottom: 10
                    })
                    .borderRadius(8)
                    .margin({ right: 10 })
                    .constraintSize({ maxWidth: '70%' })

                  // ✨ 使用我的头像 myAvatar
                  Image(this.myAvatar ? this.myAvatar : $r('app.media.logo'))
                    .width(40).height(40).borderRadius(20)
                    .objectFit(ImageFit.Cover)
                }
              }
              .width('100%')
              .justifyContent(item.role === 1 ? FlexAlign.Start : FlexAlign.End)
              .padding({
                left: 12,
                right: 12,
                top: 8,
                bottom: 8
              })
            }
          })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')

        // 底部输入区域
        Row() {
          TextInput({ text: this.inputText, placeholder: '想问老板点什么...?' })
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
            .backgroundColor('#007DFF')
        }
        .width('100%')
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })
        .backgroundColor(Color.White)
        .shadow({ radius: 2, color: '#10000000', offsetY: -1 }) // 底部阴影
      }
      .width('100%').height('100%')
    }
    .title(this.title)
    .onReady((ctx: NavDestinationContext) => {
      const params = ctx.pathInfo.param as ChatPageParam;
      if ( params ) {
        this.initParams(params);
      }
    })
    .onDisAppear(() => {
      this.onDisappear();
    })
  }
}