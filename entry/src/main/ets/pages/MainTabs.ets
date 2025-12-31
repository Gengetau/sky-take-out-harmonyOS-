@Component
export struct MainTabs {
  @Consume('pageStack') pageStack: NavPathStack;

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          Text('待处理订单')
            .fontSize(30)
        }
        .tabBar('待处理')

        TabContent() {
          Text('店铺管理')
            .fontSize(30)
        }
        .tabBar('店铺')
      }
      .scrollable(false)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      // 在主页按返回键，拦截默认行为，防止直接退出或回退
      // 这里可以做一个“再按一次退出应用”的逻辑，或者直接返回true表示已处理
      return true; 
    })
  }
}
