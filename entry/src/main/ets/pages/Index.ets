import { common } from '@kit.AbilityKit';
import { HttpUtil } from '../common/HttpUtil';
import { PreferencesUtil } from '../common/PreferencesUtil';
import { Login } from './Login';
import { MainTabs } from './MainTabs';

@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State isShowSplash: boolean = true;

  @Builder
  PagesMap(name: string) {
    if (name === 'Login') {
      Login()
    } else if (name === 'MainTabs') {
      MainTabs()
    }
  }

  async initializeApp() {
    console.info('喵！[Index] 商家端初始化...');
    const uiContext = this.getUIContext();
    
    // 设置 HttpUtil 的 context (虽然目前的 HttpUtil 没强依赖，但为了 Toast 最好加上)
    // 注意：我们需要在 HttpUtil 里加一个 setContext 方法，或者直接在这里用不到它
    // 之前 HttpUtil 代码里没加 setContext，待会儿我去补上喵！
    
    const context = uiContext.getHostContext() as common.UIAbilityContext;
    await PreferencesUtil.loadPreference(context);

    const token = await PreferencesUtil.getToken();
    
    // 模拟启动延时
    await new Promise<void>(r => setTimeout(r, 1000));

    if (token) {
      console.info('喵！发现 Token，尝试进入主页');
      AppStorage.setOrCreate('token', token);
      this.pageStack.pushPath({ name: 'MainTabs' }, false);
    } else {
      console.info('喵！无 Token，进入登录页');
      this.pageStack.pushPath({ name: 'Login' }, false);
    }
    
    this.isShowSplash = false;
  }

  build() {
    Navigation(this.pageStack) {
      if (this.isShowSplash) {
        Column() {
          Image($r('app.media.startIcon'))
            .width(100)
            .height(100)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 20 })
          Text('Meow外卖 · 商家端')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .navDestination(this.PagesMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .height('100%')
    .width('100%')
    .onAppear(() => {
      this.initializeApp();
    })
  }
}
