/**
 * 用户首选项工具
 */
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 👜 全局用户首选项工具类 (单例模式)
 */
export class PreferencesUtil {
  // 1. 定义静态变量，持有 preferences 实例
  private static pref: preferences.Preferences | null = null;

  // 定义数据库的名字 (类似于钱包的名字)
  private static readonly STORE_NAME: string = 'SkyTakeout_Pref';
  // 定义 Token 的 Key
  private static readonly KEY_TOKEN: string = 'user_token';

  /**
   * 🚀 初始化方法 (必须在 EntryAbility 里调用一次)
   */
  static async loadPreference(context: Context) {
    try {
      // 获取实例
      PreferencesUtil.pref = await preferences.getPreferences(context, PreferencesUtil.STORE_NAME);
      console.info('[PreferencesUtil] 钱包初始化成功喵！');
    } catch (err) {
      let e = err as BusinessError;
      console.error(`[PreferencesUtil] 初始化失败: ${e.code}, ${e.message}`);
    }
  }

  /**
   * 💾 保存 Token
   */
  static async saveToken(token: string) {
    if (!PreferencesUtil.pref) return;
    try {
      // 1. 写入内存
      await PreferencesUtil.pref.put(PreferencesUtil.KEY_TOKEN, token);
      // 2. 刷入磁盘 (这一步千万不能忘！否则杀后台就丢了)
      await PreferencesUtil.pref.flush();
      console.info('[PreferencesUtil] Token 保存成功喵！');
    } catch (err) {
      console.error('[PreferencesUtil] 保存 Token 失败喵');
    }
  }

  /**
   * 🔍 获取 Token
   * @returns token 字符串，如果没有则返回空字符串 ''
   */
  static async getToken(): Promise<string> {
    if (!PreferencesUtil.pref) return '';
    try {
      // get 的第二个参数是默认值
      const token = await PreferencesUtil.pref.get(PreferencesUtil.KEY_TOKEN, '');
      return token as string;
    } catch (err) {
      return '';
    }
  }

  /**
   * 🗑️ 删除 Token (退出登录用)
   */
  static async deleteToken() {
    if (!PreferencesUtil.pref) return;
    try {
      await PreferencesUtil.pref.delete(PreferencesUtil.KEY_TOKEN);
      await PreferencesUtil.pref.flush(); // 删除也要 flush 哦
      console.info('[PreferencesUtil] Token 已销毁喵！');
    } catch (err) {
      console.error('[PreferencesUtil] 删除 Token 失败喵');
    }
  }
}