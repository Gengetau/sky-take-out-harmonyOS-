import { common } from '@kit.AbilityKit';
import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { Login } from './Login';
import { MainTabs } from './MainTabs';
import { ShopPage } from './shop/ShopPage';


@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State isShowSplash: boolean = true; // 控制启动屏显示

  @Builder
  PagesMap(name: string) {
    if ( name === 'Login' ) {
      Login() // 直接调用！不要中间商赚差价！
    } else if ( name === 'MainTabs' ) {
      MainTabs();
    } else if ( name === 'ShopPage' ) { // 👈 新增这一行！
      ShopPage() // 直接调用组件，不需要 Builder 包装函数
    }
  }

  /**
   * 应用初始化
   */
  async initializeApp() {
    // 1. 获取并设置UI上下文
    const uiContext = this.getUIContext();
    HttpUtil.setContext(uiContext);

    // 2. 初始化持久化存储工具 (必须等待它完成)
    const context = uiContext.getHostContext() as common.UIAbilityContext;
    await PreferencesUtil.loadPreference(context);

    // 3. 核心：从持久化存储加载Token到内存(AppStorage)，实现状态恢复
    const persistentToken = await PreferencesUtil.getToken();
    if ( persistentToken && persistentToken.length > 0 ) {
      AppStorage.setOrCreate('token', persistentToken);
      console.info('喵！[Index] 已从首选项加载持久化Token到AppStorage。');
    } else {
      console.info('喵！[Index] 首选项中没有找到Token。');
    }

    // 4. 在所有初始化完成后，再检查登录并跳转
    this.checkLoginAndJump();
  }

  async checkLoginAndJump() {
    // 模拟启动屏展示时间
    await new Promise<void>((r) => {
      setTimeout(r, 1000);
    });

    // HttpUtil的拦截器会自动携带AppStorage中的token
    const token = AppStorage.get<string>('token'); // 直接从 AppStorage 读
    let targetName = 'Login'; // 默认去登录页

    if ( token && token.length > 0 ) {
      console.info('喵！[Index] 检测到内存中存在Token，正在通过 HttpUtil 验证有效性...');
      try {
        // HttpUtil.get 会自动处理 base_url 和 token 拦截器
        await HttpUtil.get<string>('/client/type/list');
        console.info('喵！[Index] Token有效，准备去 MainTabs');
        targetName = 'MainTabs';
      } catch ( error ) {
        // 捕获到错误，说明 token 失效 (NOT_LOGIN) 或网络异常
        console.error('喵！[Index] Token验证失败或网络异常，准备去 Login。错误:', error);
        targetName = 'Login';
        // 清理一下 AppStorage 和持久化存储中已失效的 token
        AppStorage.delete('token');
        await PreferencesUtil.deleteToken();
        console.info('喵！[Index] 已清除所有失效的Token');
      }
    } else {
      console.info('喵！[Index] AppStorage 中没有Token，准备去 Login');
      targetName = 'Login';
    }


    // 🚀 执行跳转
    this.pageStack.pushPath({ name: targetName }, false);

    // 🕵️‍♀️ 探针日志：看看栈里到底有没有东西？
    setTimeout(() => {
      const size = this.pageStack.size();
      console.info(`喵！[Index] 跳转指令已发出。当前路由栈大小: ${ size }`);
      console.info(`喵！[Index] 栈顶页面名字: ${ JSON.stringify(this.pageStack.getAllPathName()) }`);

      // 如果 size 还是 0，说明 router_map 配置绝对有错！
      if ( size === 0 ) {
        console.error('喵！！！跳转失败了！系统找不到名为 ' + targetName + ' 的路由配置！请检查 router_map.json！');
      }
    }, 100);

    // 关掉启动屏（可选，如果 pushPath 没动画，这步其实会被新页面覆盖）
    this.isShowSplash = false;
  }

  build() {
    Navigation(this.pageStack) {

      // --- 启动屏 UI (Splash) ---
      Stack() {
        Column() {
          Image($r('app.media.logo')) // 您的 Logo
            .width(100)
            .height(100)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 20 })

          Text('苍穹外卖')
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
        // 在页面出现时，开始执行初始化流程
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