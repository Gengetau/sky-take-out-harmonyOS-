import { HttpUtil } from '../common/utils/HttpUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { SendCodeDTO, UserLoginDTO, UserLoginVO } from '../model/entity/LoginModel';

/**
 * 认证业务
 */
export class AuthService {
  // 🔗 接口地址常量 (C端接口)
  private static readonly SEND_CODE_URL = '/client/user/code';
  private static readonly LOGIN_URL = '/client/user/login';

  /**
   * 📨 发送验证码 (并获取后端返回的 Code 用于模拟)
   * @param phone 手机号
   * @returns string | null 如果成功返回验证码，失败返回 null
   */
  static async sendVerifyCode(phone: string): Promise<string | null> {
    try {
      // 假设接口只需要传 phone 参数 (后端可能用 @RequestParam 或 @RequestBody)
      // 如果后端需要对象: { phone: phone }
      // 这里泛型 <string> 表示后端 data 直接返回了验证码字符串
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
      // 发送登录请求
      const data = await HttpUtil.post<UserLoginVO>(AuthService.LOGIN_URL, dto);

      if (data && data.token) {
        // ✅ 1. 持久化保存 Token
        await PreferencesUtil.saveToken(data.token);

        // ✅ 2. 更新内存 Token (拦截器用)
        AppStorage.setOrCreate('token', data.token);

        // ✅ 3. 保存用户 ID (可选，后续业务可能用)
        AppStorage.setOrCreate('userId', data.id);

        return true;
      }
      return false;
    } catch (err) {
      return false; // 错误信息 HttpUtil 已经弹过了
    }
  }
}