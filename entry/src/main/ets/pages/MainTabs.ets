import { OrderListContent } from '../view/home/OrderListContent';
import { ManageContent } from '../view/manage/ManageContent';
import { MineContent } from '../view/mine/MineContent';

class StatusItem {
  label: string;
  value: number;

  constructor(label: string, value: number) {
    this.label = label;
    this.value = value;
  }
}

@Component
export struct MainTabs {
  @Consume('pageStack') pageStack: NavPathStack;
  @State currentIndex: number = 0;
  @State orderStatusIndex: number = 0; // 0:全部, 1:待接单, 2:待派送, 3:已完成
  private tabsController: TabsController = new TabsController();

  private statusList: StatusItem[] = [
    new StatusItem('全部', 0),
    new StatusItem('待接单', 2),
    new StatusItem('待派送', 3),
    new StatusItem('已完成', 5)
  ];

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
    })
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
        // 1. 订单管理
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
                  
                  // 选中红线（这里用主题黄）
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

        // 2. 菜品管理
        TabContent() {
          ManageContent()
        }
        .tabBar(this.TabBuilder('管理', 1, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 3. 数据统计 (占位)
        TabContent() {
          Column() { Text('数据统计建设中...').fontSize(18) }.width('100%').height('100%').justifyContent(FlexAlign.Center)
        }
        .tabBar(this.TabBuilder('数据', 2, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 4. 个人中心
        TabContent() {
          MineContent()
        }
        .tabBar(this.TabBuilder('我的', 3, $r('app.media.startIcon'), $r('app.media.startIcon')))
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
