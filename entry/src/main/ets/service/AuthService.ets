import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { WebSocketService } from './WebSocketService';
import { SendCodeDTO, UserLoginDTO, UserLoginVO } from '../model/entity/LoginModel';

/**
 * 认证业务
 */
export class AuthService {
  // 🔗 接口地址常量 (C端接口)
  private static readonly SEND_CODE_URL = '/client/user/code';
  private static readonly LOGIN_URL = '/client/user/login';

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

        // ✅ 3. 连接 WebSocket (使用宿主机IP)
        WebSocketService.getInstance().connect(data.id, '10.0.2.2:8080');

        return true;
      }
      return false;
    } catch (err) {
      return false;
    }
  }
}
