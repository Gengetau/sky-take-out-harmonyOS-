import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { WebSocketService } from './WebSocketService';
import { SendCodeDTO, UserLoginDTO, UserLoginVO, UserInfoVO, UserEditDTO } from '../model/entity/LoginModel';

/**
 * 认证业务
 */
export class AuthService {
  // 🔗 接口地址常量 (C端接口)
  private static readonly SEND_CODE_URL = '/client/user/code';
  private static readonly LOGIN_URL = '/client/user/login';
  private static readonly USER_INFO_URL = '/client/user/info';
  private static readonly LOGOUT_URL = '/client/user/logout';
  private static readonly EDIT_INFO_URL = '/client/user/edit';
  private static readonly CANCEL_URL = '/client/user/cancel'; // 🆔 注销接口 (新增)

  /**
   * 📨 发送验证码
   */
  static async sendVerifyCode(phone: string): Promise<string | null> {
    const dto = new SendCodeDTO(phone);
    const code = await HttpUtil.post<string>(AuthService.SEND_CODE_URL, dto);
    console.info(`后端返回的验证码是: ${code}`);
    return code;
  }

  /**
   * 🔐 用户登录
   */
  static async login(dto: UserLoginDTO): Promise<boolean> {
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
  }

  /**
   * 👤 获取当前登录用户信息
   */
  static async getUserInfo(): Promise<UserInfoVO | null> {
    // 加上时间戳防止缓存
    return await HttpUtil.get<UserInfoVO>(`${AuthService.USER_INFO_URL}?t=${Date.now()}`);
  }

  /**
   * ✏️ 修改单项用户信息 (API 9.4)
   * @param code 字段标识 (name, sex, profile 等)
   * @param value 新值
   */
  static async updateUserSingleInfo(code: string, value: string): Promise<string> {
    const dto = new UserEditDTO(code, value);
    return await HttpUtil.put<string>(AuthService.EDIT_INFO_URL, dto);
  }

  /**
   * 📸 上传头像
   * @param fileUri 图片文件的本地 URI
   */
  static async uploadAvatar(fileUri: string): Promise<string> {
    return HttpUtil.upload<string>('/client/user/uploadAvatar', fileUri);
  }

  /**
   * 🚪 退出登录
   */
  static async logout() {
    try {
      // 1. 通知后端销毁 Token
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
      AppStorage.delete('currentUserInfo');
      // 4. 断开 WebSocket
      WebSocketService.getInstance().close();
      console.info('喵！本地登录数据已清理，WS 已断开');
    }
  }

  /**
   * 🗑️ 注销账号 (API 9.5)
   */
  static async cancelAccount(): Promise<string> {
    const emptyBody: Record<string, string> = {};
    return await HttpUtil.post<string>(AuthService.CANCEL_URL, emptyBody);
  }
}