import { HttpUtil } from '../common/HttpUtil';
import { EmployeeLoginDTO, EmployeeLoginVO } from '../model/EmployeeLoginModel';
import { PreferencesUtil } from '../common/PreferencesUtil';

export class AuthService {
  /**
   * 员工登录
   * @param dto 登录参数
   * @returns 登录结果
   */
  static async login(dto: EmployeeLoginDTO): Promise<EmployeeLoginVO> {
    // 发送登录请求
    const result = await HttpUtil.post<EmployeeLoginVO>('/employee/login', dto);
    
    // 1. 存入内存，供当前会话使用
    AppStorage.setOrCreate('token', result.token);
    AppStorage.setOrCreate('employeeInfo', result);

    // 2. 持久化存储，下次启动自动登录
    await PreferencesUtil.saveToken(result.token);
    await PreferencesUtil.saveEmployeeInfo(result);
    
    return result;
  }
  
  /**
   * 退出登录
   */
  static logout() {
    AppStorage.setOrCreate('token', '');
    AppStorage.setOrCreate('employeeInfo', null);
    // TODO: 跳转回登录页逻辑
  }
}
