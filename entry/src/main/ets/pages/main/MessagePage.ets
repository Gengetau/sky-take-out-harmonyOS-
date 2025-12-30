import { MessageRdb, SessionModel } from '../../common/utils/MessageRdb';
import { ChatPageParam } from '../message/ChatPage'; // ✨ 引入新的参数类

/**
 * 消息页 (会话列表)
 */
@Component
export struct MessagePage {
  // 消费上一级提供的 Navigation Stack
  @Consume('pageStack') pageStack: NavPathStack; 
  @State sessionList: SessionModel[] = [];
  @StorageLink('NewMessageSignal') @Watch('onMessageSignal') signal: number = 0;

  async aboutToAppear() {
    this.refreshList();
  }

  async onMessageSignal() {
    console.info('喵！收到新消息信号，刷新列表 🔄');
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
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)

      // 列表
      if (this.sessionList.length === 0) {
        Column() {
          // 使用系统图标 envelope_open_fill 喵
          SymbolGlyph($r('sys.symbol.envelope_open_fill'))
            .fontSize(80)
            .fontColor(['#BDC3C7'])
          Text('暂无消息喵~')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ top: 15 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.sessionList, (item: SessionModel) => {
            ListItem() {
              Row() {
                // 头像
                Image(item.sessionId === 'system_notify' ? $r('app.media.logo') : (item.avatar ? item.avatar : $r('app.media.logo'))) // 优先使用 item.avatar
                  .width(50).height(50)
                  .borderRadius(25)
                  .margin({ right: 12 })
                  .objectFit(ImageFit.Cover)
                
                // 内容区域
                Column() {
                  Row() {
                    // 标题特殊处理：系统通知 -> Meow外卖
                    Text(item.sessionId === 'system_notify' ? 'Meow外卖' : item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                    Text(this.formatTime(item.lastTime))
                      .fontSize(12)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  
                  Row() {
                    Text(item.lastMsg)
                      .fontSize(14)
                      .fontColor('#666666')
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
                // 喵！这里进行分流跳转
                if (item.sessionId === 'system_notify') {
                  this.pageStack.pushPath({ name: 'SystemNotifyPage' });
                } else {
                  // 私聊跳转
                  // ✨ 传递 item.avatar 给 ChatPage
                  const params = new ChatPageParam(item.sessionId, item.title, item.avatar);
                  this.pageStack.pushPath({ name: 'ChatPage', param: params });
                }
              })
            }
            .swipeAction({ end: this.itemEnd(item.sessionId) }) // 侧滑删除
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 78, endMargin: 0 }) // 分割线
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F5F5')
  }
}