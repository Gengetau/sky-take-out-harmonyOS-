import { common } from '@kit.AbilityKit';
import { OrderListContent } from '../view/home/OrderListContent';
import { ManageContent } from '../view/manage/ManageContent';
import { MineContent } from '../view/mine/MineContent';
import { MessageContent } from '../view/message/MessageContent';
import { StatisticsContent } from '../view/statistics/StatisticsContent';
import { MessageDTO } from '../model/MessageModel';
import { MessageManager } from '../manager/MessageManager';
import { EmployeeLoginVO } from '../model/EmployeeLoginModel';
import { ShopService } from '../service/ShopService';
import { ShopInfoVO } from '../model/ShopModel';

class StatusItem {
  label: string;
  value: number;

  constructor(label: string, value: number) {
    this.label = label;
    this.value = value;
  }
}

/**
 * 新订单全局弹窗组件喵
 */
@CustomDialog
struct NewOrderDialog {
  controller: CustomDialogController;
  message?: MessageDTO;
  confirm: (orderId: number) => void = () => {};

  build() {
    Column() {
      // 头部装饰
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 80, height: 80 })
          .fill($r('app.color.theme_color'))
          .opacity(0.1)
        
        Image($r('app.media.startIcon'))
          .width(40)
          .height(40)
      }
      .margin({ top: 20, bottom: 10 })

      Text('您有新订单啦！')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
      
      Text(this.message?.content || '收到一个已支付的新订单喵~')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8, bottom: 20 })
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })

      Divider().color('#EEEEEE').strokeWidth(0.5)

      Row() {
        Button('稍后处理')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_secondary'))
          .height(50)
          .onClick(() => {
            this.controller.close();
          })

        Divider().vertical(true).height(30).color('#EEEEEE').strokeWidth(0.5)

        Button('立即查看')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.theme_color'))
          .fontWeight(FontWeight.Bold)
          .height(50)
          .onClick(() => {
            if (this.message?.orderId) {
              this.confirm(this.message.orderId);
            }
            this.controller.close();
          })
      }
      .width('100%')
    }
    .width('85%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

@Component
export struct MainTabs {
  @Consume('pageStack') pageStack: NavPathStack;
  @State currentIndex: number = 0;
  @State orderStatusIndex: number = 0; // 0:全部, 1:待接单, 2:待派送, 3:已完成
  private tabsController: TabsController = new TabsController();

  // 监听登录信息
  @StorageLink('employeeInfo') employeeInfo: EmployeeLoginVO | null = null;
  @StorageLink('shopInfo') shopInfo: ShopInfoVO | null = null;

  async aboutToAppear() {
    // 检查是否有登录信息，并初始化消息管理器喵
    if (this.employeeInfo && this.employeeInfo.shopId) {
      console.info(`喵！发现店铺 ID: ${this.employeeInfo.shopId}，尝试初始化消息中心...`);
      const context = getContext(this) as common.UIAbilityContext;
      await MessageManager.getInstance().init(context, this.employeeInfo.shopId);
      
      // 获取并存储店铺详情 (Logo, 营业状态等)
      try {
        const info = await ShopService.getShopInfo();
        AppStorage.setOrCreate('shopInfo', info);
        console.info('喵！店铺信息加载成功:', info.name);
      } catch (e) {
        console.error('喵！店铺信息加载失败:', e);
      }
    }
  }

  // 监听新订单消息喵
  @StorageLink('NewOrderMessage') @Watch('onNewOrder') newOrderMsg: MessageDTO | null = null;

  private statusList: StatusItem[] = [
    new StatusItem('全部', 0),
    new StatusItem('待接单', 2),
    new StatusItem('待派送', 3),
    new StatusItem('已完成', 5)
  ];

  // 弹窗控制器喵
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: NewOrderDialog({
      message: this.newOrderMsg || undefined,
      confirm: (orderId) => {
        // 跳转到订单详情页 (假设路径名为 OrderDetailPage)
        this.pageStack.pushPath({ name: 'OrderDetailPage', param: orderId });
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  onNewOrder() {
    if (this.newOrderMsg) {
      console.info('喵！监听到新订单，弹出对话框');
      // 重新创建控制器以更新数据 (ArkUI 某些版本需要这样做)
      this.dialogController = new CustomDialogController({
        builder: NewOrderDialog({
          message: this.newOrderMsg,
          confirm: (orderId) => {
            this.pageStack.pushPath({ name: 'OrderDetailPage', param: orderId });
          }
        }),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true
      });
      this.dialogController.open();
    }
  }

  @Builder
  TabBuilder(title: string, index: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontColor(this.currentIndex === index ? $r('app.color.text_main') : $r('app.color.text_secondary'))
        .fontSize(10)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(this.currentIndex);
      
      // 喵！如果切换到数据统计(Index 3)，发送刷新信号
      if (index === 3) {
        AppStorage.setOrCreate('RefreshStatistics', Date.now());
      }
    })
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
        // 1. 订单管理 (Index 0)
        TabContent() {
          Column() {
            // 顶部状态栏
            Row() {
              ForEach(this.statusList, (item: StatusItem, index: number) => {
                Column() {
                  Text(item.label)
                    .fontSize(16)
                    .fontColor(this.orderStatusIndex === index ? $r('app.color.text_main') : $r('app.color.text_secondary'))
                    .fontWeight(this.orderStatusIndex === index ? FontWeight.Bold : FontWeight.Normal)
                  
                  // 选中红线
                  Rect()
                    .width(20)
                    .height(3)
                    .fill($r('app.color.theme_color'))
                    .margin({ top: 4 })
                    .opacity(this.orderStatusIndex === index ? 1 : 0)
                }
                .layoutWeight(1)
                .onClick(() => {
                  this.orderStatusIndex = index;
                })
              })
            }
            .width('100%')
            .height(50)
            .backgroundColor(Color.White)
            .padding({ left: 10, right: 10 })

            // 订单列表
            OrderListContent({ status: this.statusList[this.orderStatusIndex].value })
              .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
        }
        .tabBar(this.TabBuilder('订单', 0, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 2. 菜品管理 (Index 1)
        TabContent() {
          ManageContent()
        }
        .tabBar(this.TabBuilder('管理', 1, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 3. 消息中心 (Index 2)
        TabContent() {
          MessageContent()
        }
        .tabBar(this.TabBuilder('消息', 2, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 4. 数据统计 (Index 3)
        TabContent() {
          StatisticsContent()
        }
        .tabBar(this.TabBuilder('数据', 3, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 5. 个人中心 (Index 4)
        TabContent() {
          MineContent()
        }
        .tabBar(this.TabBuilder('我的', 4, $r('app.media.startIcon'), $r('app.media.startIcon')))
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.white'))
      .barHeight(60)
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      return true;
    })
  }
}
