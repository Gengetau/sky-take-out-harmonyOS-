import { SessionModel } from '../../model/MessageModel';
import { MessageRdb } from '../../common/MessageRdb';
import { ChatPageParam } from '../../pages/message/ChatPage';

@Component
export struct MessageContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @State sessionList: SessionModel[] = [];
  @StorageLink('NewMessageSignal') @Watch('onMessageSignal') signal: number = 0;

  async aboutToAppear() {
    this.refreshList();
  }

  // 监听到新消息信号，刷新列表喵
  async onMessageSignal() {
    console.info('喵！收到新消息信号，刷新会话列表 🔄');
    this.refreshList();
  }

  async refreshList() {
    this.sessionList = await MessageRdb.getSessionList();
  }

  // 格式化时间戳
  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    // 简单处理：如果是今天显示 HH:mm，否则显示 MM-dd
    if (date.getDate() === now.getDate() && date.getMonth() === now.getMonth()) {
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
    return `${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  // 侧滑删除按钮
  @Builder itemEnd(sessionId: string) {
    Row() {
      Button("删除")
        .type(ButtonType.Normal)
        .backgroundColor(Color.Red)
        .fontColor(Color.White)
        .height('100%')
        .width(80)
        .onClick(async () => {
          await MessageRdb.deleteSession(sessionId);
          this.refreshList();
        })
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('消息中心')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)

      // 列表内容
      if (this.sessionList.length === 0) {
        Column() {
          Image($r('app.media.startIcon')) // 暂时用启动图标
            .width(80)
            .height(80)
            .opacity(0.3)
            .grayscale(1)
          Text('暂无消息喵~')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 15 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.sessionList, (item: SessionModel) => {
            ListItem() {
              Row() {
                // 头像处理喵
                if (item.sessionId === 'system_notify') {
                  // 系统通知统一用 App Logo 喵
                  Image($r('app.media.app_logo'))
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                } else if (typeof item.avatar === 'string' && item.avatar.length > 0) {
                  // 私聊用用户头像喵
                  Image(item.avatar)
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                } else {
                  // 默认头像喵
                  Image($r('app.media.startIcon'))
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                }
                
                // 内容区域
                Column() {
                  Row() {
                    // 标题
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_main'))
                      .layoutWeight(1)
                    // 时间
                    Text(this.formatTime(item.lastTime))
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  
                  Row() {
                    // 消息预览
                    Text(item.lastMsg)
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                      .margin({ top: 4 })
                    
                    // 未读红点
                    if (item.unreadCount > 0) {
                      Text(item.unreadCount > 99 ? '99+' : item.unreadCount.toString())
                        .fontSize(10)
                        .fontColor(Color.White)
                        .backgroundColor(Color.Red)
                        .borderRadius(10)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .margin({ left: 8 })
                    }
                  }
                  .width('100%')
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(Color.White)
              .onClick(() => {
                // 跳转到聊天详情页喵
                const avatarStr = typeof item.avatar === 'string' ? item.avatar : '';
                const params = new ChatPageParam(item.sessionId, item.title, avatarStr);
                this.pageStack.pushPath({ name: 'ChatPage', param: params });
              })
            }
            .swipeAction({ end: this.itemEnd(item.sessionId) }) // 绑定侧滑删除
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 78, endMargin: 0 }) // 列表分割线
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
