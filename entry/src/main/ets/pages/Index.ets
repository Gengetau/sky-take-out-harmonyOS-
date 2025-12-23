import { common } from '@kit.AbilityKit';
import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { AddressEditPage } from './address/AddressEditPage';
import { AddressMapPage } from './address/AddressMapPage';
import { Login } from './Login';
import { ConfirmOrderView } from './main/ConfirmOrderPage';
import { MainTabs } from './MainTabs';
import { ShopPage } from './shop/ShopPage';
import { RemarkPage } from './main/RemarkPage';
import { PaymentPage } from './main/PaymentPage';
import { WebSocketService } from '../service/WebSocketService';


@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State isShowSplash: boolean = true; // 控制启动屏显示

  @Builder
  PagesMap(name: string) {
    if ( name === 'Login' ) {
      Login()
    } else if ( name === 'MainTabs' ) {
      MainTabs();
    } else if ( name === 'ShopPage' ) {
      ShopPage()
    } else if ( name === 'ConfirmOrderPage' ) {
      ConfirmOrderView()
    } else if ( name === 'AddressEditPage' ) {
      AddressEditPage()
    } else if ( name === 'AddressMapPage' ) {
      AddressMapPage()
    } else if ( name === 'RemarkPage' ) {
      RemarkPage()
    } else if ( name === 'PaymentPage' ) {
      PaymentPage()
    }
  }

  /**
   * 应用初始化
   */
  async initializeApp() {
    console.info('喵！[Index] 开始初始化应用...');
    const uiContext = this.getUIContext();
    HttpUtil.setContext(uiContext);

    const context = uiContext.getHostContext() as common.UIAbilityContext;
    await PreferencesUtil.loadPreference(context);

    // 从持久化存储加载 Token 和 UserId
    const persistentToken = await PreferencesUtil.getToken();
    const persistentUserId = await PreferencesUtil.getUserId();

    console.info(`喵！[Index] 读取持久化数据: Token=${persistentToken ? 'Yes' : 'No'}, UserId=${persistentUserId}`);

    if ( persistentToken && persistentToken.length > 0 ) {
      AppStorage.setOrCreate('token', persistentToken);
      AppStorage.setOrCreate('userId', persistentUserId);
    } 

    this.checkLoginAndJump();
  }

  async checkLoginAndJump() {
    await new Promise<void>((r) => {
      setTimeout(r, 1000);
    });

    const token = AppStorage.get<string>('token');
    let targetName = 'Login';

    if ( token && token.length > 0 ) {
      console.info('喵！[Index] 正在验证 Token 有效性...');
      try {
        await HttpUtil.get<string>('/client/type/list');
        
        const userId = AppStorage.get<number>('userId') || 0;
        console.info(`喵！[Index] Token有效，UserId=${userId}`);
        
        if (userId > 0) {
          // ✅ 数据完整，连接 WS 并进入主页
          // 使用 192.168.0.210 以匹配您的真机/局域网环境
          WebSocketService.getInstance().connect(userId, '192.168.0.210:8080');
          targetName = 'MainTabs';
        } else {
          // ⚠️ 关键修复：如果是旧版本升级上来的数据（有Token无ID），必须重登
          console.warn('喵！！！[Index] 发现脏数据：有Token但UserId为0。正在清除数据...');
          await this.clearLoginData();
          targetName = 'Login';
        }
        
      } catch ( error ) {
        console.error('喵！[Index] Token失效或网络请求失败，准备去 Login:', error);
        await this.clearLoginData();
        targetName = 'Login';
      }
    } else {
      console.info('喵！[Index] 没有Token，直接去 Login');
    }

    console.info(`喵！[Index] 最终跳转目标: ${targetName}`);
    this.pageStack.pushPath({ name: targetName }, false);
    this.isShowSplash = false;
  }

  async clearLoginData() {
    AppStorage.delete('token');
    AppStorage.delete('userId');
    await PreferencesUtil.deleteToken();
  }

  build() {
    Navigation(this.pageStack) {
      Stack() {
        Column() {
          Image($r('app.media.logo'))
            .width(100)
            .height(100)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 20 })

          Text('Meow外卖')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .letterSpacing(4)

          Text('Powered by HarmonyOS')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 200 })
        }
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .width('100%')
      }
      .backgroundColor('#FFFFFF')
      .onAppear(() => {
        // 确保 initializeApp 只被调用一次
        this.initializeApp();
      })
    }
    .navDestination(this.PagesMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .height('100%')
    .width('100%')
  }
}