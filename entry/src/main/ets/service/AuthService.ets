import { HttpUtil } from '../common/HttpUtil';
import { EmployeeLoginDTO, EmployeeLoginVO } from '../model/EmployeeLoginModel';

export class AuthService {
  /**
   * 员工登录
   * @param dto 登录参数
   * @returns 登录结果
   */
  static async login(dto: EmployeeLoginDTO): Promise<EmployeeLoginVO> {
    // 发送登录请求
    const result = await HttpUtil.post<EmployeeLoginVO>('/admin/employee/login', dto);
    
    // 登录成功后，持久化 Token (简化版，先存 AppStorage)
    AppStorage.setOrCreate('token', result.token);
    AppStorage.setOrCreate('employeeInfo', result);
    
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
