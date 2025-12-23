import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { WebSocketService } from './WebSocketService';
import { SendCodeDTO, UserLoginDTO, UserLoginVO, UserInfoVO } from '../model/entity/LoginModel';

/**
 * 认证业务
 */
export class AuthService {
  // 🔗 接口地址常量 (C端接口)
  private static readonly SEND_CODE_URL = '/client/user/code';
  private static readonly LOGIN_URL = '/client/user/login';
  private static readonly USER_INFO_URL = '/client/user/info';
  private static readonly LOGOUT_URL = '/client/user/logout';

  /**
   * 📨 发送验证码
   */
  static async sendVerifyCode(phone: string): Promise<string | null> {
    try {
      const dto = new SendCodeDTO(phone);
      const code = await HttpUtil.post<string>(AuthService.SEND_CODE_URL, dto);
      console.info(`后端返回的验证码是: ${code}`);
      return code;
    } catch (err) {
      console.error('发送验证码失败');
      return null;
    }
  }

  /**
   * 🔐 用户登录
   */
  static async login(dto: UserLoginDTO): Promise<boolean> {
    try {
      const data = await HttpUtil.post<UserLoginVO>(AuthService.LOGIN_URL, dto);

      if (data && data.token) {
        // ✅ 1. 持久化保存 Token 和 UserID
        await PreferencesUtil.saveToken(data.token);
        await PreferencesUtil.saveUserId(data.id);

        // ✅ 2. 更新内存 Token
        AppStorage.setOrCreate('token', data.token);
        AppStorage.setOrCreate('userId', data.id);

        // ✅ 3. 连接 WebSocket
        WebSocketService.getInstance().connect(data.id, '192.168.0.210:8080');

        return true;
      }
      return false;
    } catch (err) {
      return false;
    }
  }

  /**
   * 👤 获取当前登录用户信息
   */
  static async getUserInfo(): Promise<UserInfoVO | null> {
    try {
      return await HttpUtil.get<UserInfoVO>(AuthService.USER_INFO_URL);
    } catch (err) {
      console.error('获取用户信息失败喵', err);
      return null;
    }
  }

  /**
   * 🚪 退出登录
   */
  static async logout() {
    try {
      // 1. 通知后端销毁 Token
      // ✨ 修正：使用 Record 类型明确空对象的类型，绕过 ArkTS 检查
      const emptyBody: Record<string, string> = {};
      await HttpUtil.post<string>(AuthService.LOGOUT_URL, emptyBody);
      console.info('喵！后端 Session 已销毁');
    } catch (err) {
      console.warn('喵！后端退出通知失败，可能 Token 已过期，继续清理本地数据', err);
    } finally {
      // 2. 清理本地持久化数据
      await PreferencesUtil.deleteToken();
      // 3. 清理内存状态
      AppStorage.delete('token');
      AppStorage.delete('userId');
      // 4. 断开 WebSocket
      WebSocketService.getInstance().close();
      console.info('喵！本地登录数据已清理，WS 已断开');
    }
  }
}