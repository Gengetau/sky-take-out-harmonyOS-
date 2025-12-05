import { CartPage } from './main/CartPage';
import { HomePageContent } from './main/HomePageContent';
import { MessagePage } from './main/MessagePage';
import { MinePage } from './main/MinePage';

@Component
export struct MainTabs {
  @State currentIndex: number = 0; //当前页
  private tabsController: TabsController = new TabsController(); // Tabs容器控制器

  @Builder
  // 自定义TabBar
  TabBuilder(title: string, targetIndex: number, symbolIcon: Resource) {
    Column() {
      // 图标
      SymbolGlyph(symbolIcon)
        .fontSize(24)
        // 选中变蓝(#0D9FFB)，未选中灰色(#999999)
        .fontColor([ this.currentIndex === targetIndex ? '#0D9FFB' : '#999999' ])
        // 加上 Q 弹的动画效果
        .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP),
          this.currentIndex === targetIndex)

      // 文字
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#0D9FFB' : '#999999')
        .fontSize(10)
        .margin({ top: 4 })
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.Transparent) // 点击背景透明
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(targetIndex);
    })
  }

  build() {
    NavDestination(){
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
        // --- Tab 1: 首页 ---
        TabContent() {
          HomePageContent()
        }
        .tabBar(this.TabBuilder('首页', 0, $r('sys.symbol.house')))

        // --- Tab 2: 消息 (新增) ---
        TabContent() {
          MessagePage()
        }
        .tabBar(this.TabBuilder('消息', 1, $r('sys.symbol.message'))) // 系统气泡图标

        // --- Tab 3: 购物车 (新增) ---
        TabContent() {
          CartPage()
        }
        .tabBar(this.TabBuilder('购物车', 2, $r('sys.symbol.cart'))) // 系统购物车图标

        // --- Tab 4: 我的 ---
        TabContent() {
          MinePage()
        }
        .tabBar(this.TabBuilder('我的', 3, $r('sys.symbol.person')))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .scrollable(false) // 禁止左右滑动切换，符合主流 App 习惯
      .barHeight(56) // 底部导航栏高度
    }
    .hideTitleBar(true)
  }
}