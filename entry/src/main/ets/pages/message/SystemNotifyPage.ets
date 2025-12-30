import { MessageRdb, MessageEntity } from '../../common/utils/MessageRdb';
import { OrderService } from '../../service/OrderService';
import { OrderVO } from '../../model/api/OrderModel';

/**
 * 聚合后的通知组
 */
interface NotificationGroup {
  orderId: number;
  latestTime: number;
  latestMsg: MessageEntity;
  totalCount: number;
  imageUrl: string;
  messageIds: number[]; // ✨ 新增：记录该组包含的所有消息ID
}

/**
 * ✨ 定义订单详情页跳转参数类
 */
export class OrderDetailParam {
  id: number = 0;
  constructor(id: number) { this.id = id; }
}

/**
 * 系统通知页
 */
@Component
export struct SystemNotifyPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State notificationGroups: NotificationGroup[] = [];

  aboutToAppear() {
    this.loadMessages();
    MessageRdb.clearUnread('system_notify');
  }

  async loadMessages() {
    const allMessages = await MessageRdb.getMessages('system_notify');
    
    // 按 orderId 分组
    const groups: Map<number, MessageEntity[]> = new Map();
    const otherMessages: MessageEntity[] = [];

    allMessages.forEach(msg => {
      let finalOrderId = msg.orderId;
      if (!finalOrderId || finalOrderId === 0) {
        if (msg.content.includes('订单') || msg.content.includes('支付') || msg.content.includes('接单') || msg.content.includes('配送')) {
          finalOrderId = 9999; 
        }
      }

      if (finalOrderId && finalOrderId > 0) {
        if (!groups.has(finalOrderId)) {
          groups.set(finalOrderId, []);
        }
        groups.get(finalOrderId)?.push(msg);
      } else {
        otherMessages.push(msg);
      }
    });

    const result: NotificationGroup[] = [];
    const queryPromises: Promise<void>[] = [];

    // 1. 处理订单组
    groups.forEach((msgs, orderId) => {
      msgs.sort((a, b) => b.createTime - a.createTime);
      
      const group: NotificationGroup = {
        orderId: orderId,
        latestTime: msgs[0].createTime,
        latestMsg: msgs[0],
        totalCount: 0,
        imageUrl: '',
        messageIds: msgs.map(m => m.id as number) // ✨ 收集所有ID
      };
      
      result.push(group);

      if (orderId !== 9999) {
        const query = async () => {
          try {
            const orderDetail = await OrderService.getOrderDetail(orderId);
            if (orderDetail && orderDetail.orderDetailList && orderDetail.orderDetailList.length > 0) {
              let count = 0;
              orderDetail.orderDetailList.forEach(item => count += item.number);
              group.totalCount = count;
              if (orderDetail.orderDetailList[0].image) {
                group.imageUrl = orderDetail.orderDetailList[0].image;
              }
            }
          } catch (e) {
            console.warn(`喵！查询订单 ${orderId} 详情失败:`, e);
          }
        };
        queryPromises.push(query());
      } else {
        group.totalCount = 1;
      }
    });

    // 2. 处理无订单消息
    otherMessages.forEach(msg => {
      result.push({
        orderId: 0,
        latestTime: msg.createTime,
        latestMsg: msg,
        totalCount: 0,
        imageUrl: '',
        messageIds: [msg.id as number] // 单条消息也是一个列表
      });
    });

    if (queryPromises.length > 0) {
       await Promise.all(queryPromises);
    }

    result.sort((a, b) => b.latestTime - a.latestTime);
    this.notificationGroups = result;
  }

  // 格式化时间
  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const yy = date.getFullYear().toString().slice(-2);
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');
    return `${yy}/${mm}/${dd}`;
  }

  // 提取标题
  getTitle(content: string): string {
    if (content.includes('支付')) return '支付成功通知';
    if (content.includes('接单')) return '商家已接单';
    if (content.includes('配送')) return '骑手配送中';
    if (content.includes('送达')) return '订单已送达';
    if (content.includes('取消')) return '订单取消提醒';
    if (content.includes('退款')) return '退款成功通知';
    return '订单状态更新';
  }

  // 侧滑删除按钮
  @Builder itemEnd(group: NotificationGroup) {
    Row() {
      Button("删除")
        .type(ButtonType.Normal)
        .backgroundColor(Color.Red)
        .fontColor(Color.White)
        .height('100%')
        .width(80)
        .onClick(async () => {
          // ✨ 无论是否是聚合组，都直接根据 messageIds 批量删除
          if (group.messageIds && group.messageIds.length > 0) {
            await MessageRdb.deleteBatch(group.messageIds);
          }
          this.loadMessages(); // 刷新列表
        })
    }
    .padding(8)
  }

  build() {
    NavDestination() {
      Column() {
        if (this.notificationGroups.length === 0) {
          Column() {
             SymbolGlyph($r('sys.symbol.bell'))
              .fontSize(60)
              .fontColor(['#BDC3C7'])
             Text('暂无通知喵~').fontSize(14).fontColor('#999999').margin({ top: 10 })
          }
          .width('100%')
          .padding({ top: 100 })
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.notificationGroups, (group: NotificationGroup) => {
              ListItem() {
                Column() {
                  Row() {
                    Image($r('app.media.logo'))
                      .width(20).height(20)
                      .margin({ right: 8 })
                    Text('Meow外卖')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                    Blank()
                    Text(this.formatTime(group.latestTime))
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ right: 4 })
                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(12)
                      .fontColor(['#CCCCCC'])
                  }
                  .width('100%')
                  .padding({ bottom: 12 })
                  
                  Row() {
                    Column() {
                      Text(group.orderId > 0 ? this.getTitle(group.latestMsg.content) : '官方公告')
                        .fontSize(17)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#333333')
                        .margin({ bottom: 6 })
                      Text(group.latestMsg.content)
                        .fontSize(13)
                        .fontColor('#666666')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .lineHeight(18)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .margin({ right: 12 })
                    
                    if (group.orderId > 0) {
                      Stack({ alignContent: Alignment.Bottom }) {
                        Image(group.imageUrl ? group.imageUrl : $r('app.media.logo')) 
                          .width(64).height(64)
                          .borderRadius(6)
                          .objectFit(ImageFit.Cover)
                          .backgroundColor('#F5F5F5')
                        if (group.totalCount > 0) {
                          Row() {
                            Text(`共${group.totalCount}件`)
                              .fontSize(10)
                              .fontColor(Color.White)
                          }
                          .backgroundColor('#99000000')
                          .borderRadius({ topLeft: 4, bottomRight: 6 })
                          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                          .width('100%')
                          .justifyContent(FlexAlign.Center)
                        }
                      }
                      .width(64).height(64)
                      .borderRadius(6)
                      .clip(true)
                    }
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                }
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(12)
                .padding(16)
              }
              .swipeAction({ end: this.itemEnd(group) })
              .onClick(() => {
                if (group.orderId > 0 && group.orderId !== 9999) {
                   this.pageStack.pushPath({ name: 'OrderDetailPage', param: new OrderDetailParam(group.orderId) });
                }
              })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('订单动态')
  }
}