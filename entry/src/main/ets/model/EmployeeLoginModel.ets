/**
 * 员工登录交互对象 (DTO)
 */
export class EmployeeLoginDTO {
  username: string;
  password: string; // 注意：实际项目中建议传输加密后的密码或由前端加密
  
  constructor(username: string, password: string) {
    this.username = username;
    this.password = password;
  }
}

/**
 * 员工登录响应对象 (VO)
 */
export interface EmployeeLoginVO {
  id: number;
  userName: string;
  name: string;
  token: string;
  shopId: number;
}
