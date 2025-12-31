import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * 本地持久化工具类
 */
export class PreferencesUtil {
  private static readonly PREF_NAME = 'MeowAdminPrefs';
  private static readonly KEY_TOKEN = 'token';
  private static readonly KEY_EMPLOYEE_INFO = 'employee_info'; // 存储员工信息 JSON 字符串

  private static pref: preferences.Preferences | null = null;

  static async loadPreference(context: common.UIAbilityContext) {
    try {
      PreferencesUtil.pref = await preferences.getPreferences(context, PreferencesUtil.PREF_NAME);
      console.info('喵！PreferencesUtil 加载成功');
    } catch (err) {
      console.error('喵！PreferencesUtil 加载失败:', err);
    }
  }

  static async saveToken(token: string) {
    if (!PreferencesUtil.pref) return;
    await PreferencesUtil.pref.put(PreferencesUtil.KEY_TOKEN, token);
    await PreferencesUtil.pref.flush();
  }

  static async getToken(): Promise<string> {
    if (!PreferencesUtil.pref) return '';
    return await PreferencesUtil.pref.get(PreferencesUtil.KEY_TOKEN, '') as string;
  }

  static async deleteToken() {
    if (!PreferencesUtil.pref) return;
    await PreferencesUtil.pref.delete(PreferencesUtil.KEY_TOKEN);
    await PreferencesUtil.pref.flush();
  }
  
  static async saveEmployeeInfo(info: object) {
    if (!PreferencesUtil.pref) return;
    await PreferencesUtil.pref.put(PreferencesUtil.KEY_EMPLOYEE_INFO, JSON.stringify(info));
    await PreferencesUtil.pref.flush();
  }
}
