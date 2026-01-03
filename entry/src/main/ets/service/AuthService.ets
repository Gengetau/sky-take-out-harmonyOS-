import { HttpUtil } from '../common/HttpUtil';
import { PreferencesUtil } from '../common/PreferencesUtil';
import { EmployeeLoginDTO, EmployeeLoginVO,PasswordEditDTO } from '../model/EmployeeLoginModel';

export class AuthService {
  /**
   * 员工登录
   */
  static async login(dto: EmployeeLoginDTO): Promise<EmployeeLoginVO> {
    const result = await HttpUtil.post<EmployeeLoginVO>('/employee/login', dto);
    AppStorage.setOrCreate('token', result.token);
    AppStorage.setOrCreate('employeeInfo', result);
    await PreferencesUtil.saveToken(result.token);
    await PreferencesUtil.saveEmployeeInfo(result);
    return result;
  }

  /**
   * 退出登录
   */
  static async logout() {
    try {
      await HttpUtil.post<void>('/employee/logout');
    } catch ( e ) {
    }
    AppStorage.setOrCreate('token', '');
    AppStorage.setOrCreate('employeeInfo', null);
    await PreferencesUtil.deleteToken();
  }

  /**
   * 修改密码喵 (API 2.3)
   */
  static async updatePassword(oldPassword: string, newPassword: string): Promise<void> {
    const data:PasswordEditDTO = {
      oldPassword : oldPassword,
      newPassword : newPassword
    }
    return HttpUtil.put<void>('/employee/password', data);
  }
}