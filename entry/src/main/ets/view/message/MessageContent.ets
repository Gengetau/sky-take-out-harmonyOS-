import { SessionModel } from '../../model/MessageModel';
import { MessageRdb } from '../../common/MessageRdb';
import { ChatPageParam } from '../../pages/message/ChatPage';
import { EmployeeLoginVO } from '../../model/EmployeeLoginModel';

@Component
export struct MessageContent {
  @Consume('pageStack') pageStack: NavPathStack;
  @State sessionList: SessionModel[] = [];
  @StorageLink('NewMessageSignal') @Watch('onMessageSignal') signal: number = 0;
  
  // 🐾 获取当前商家信息以拿到 shopId
  @StorageLink('employeeInfo') employeeInfo: EmployeeLoginVO | null = null;

  async aboutToAppear() {
    this.refreshList();
  }

  async onMessageSignal() {
    this.refreshList();
  }

  async refreshList() {
    if (this.employeeInfo?.shopId) {
      this.sessionList = await MessageRdb.getSessionList(this.employeeInfo.shopId);
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
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
          if (this.employeeInfo?.shopId) {
            await MessageRdb.deleteSession(this.employeeInfo.shopId, sessionId);
            this.refreshList();
          }
        })
    }
  }

  build() {
    Column() {
      Row() {
        Text('消息中心')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)

      if (this.sessionList.length === 0) {
        Column() {
          Image($r('app.media.startIcon')) 
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
                if (item.sessionId === 'system_notify') {
                  Image($r('app.media.app_logo'))
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                } else if (typeof item.avatar === 'string' && item.avatar.length > 0) {
                  Image(item.avatar)
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                } else {
                  Image($r('app.media.startIcon'))
                    .width(50).height(50)
                    .borderRadius(25)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')
                }
                
                Column() {
                  Row() {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_main'))
                      .layoutWeight(1)
                    Text(this.formatTime(item.lastTime))
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  
                  Row() {
                    Text(item.lastMsg)
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                      .margin({ top: 4 })
                    
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
                const avatarStr = typeof item.avatar === 'string' ? item.avatar : '';
                const params = new ChatPageParam(item.sessionId, item.title, avatarStr);
                this.pageStack.pushPath({ name: 'ChatPage', param: params });
              })
            }
            .swipeAction({ end: this.itemEnd(item.sessionId) })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 78, endMargin: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}