/**
 * 登录模型
 */
// 📤 登录请求参数 (C端只用手机号+验证码)
export class UserLoginDTO {
  phone: string;
  code: string;

  constructor(phone: string, code: string) {
    this.phone = phone;
    this.code = code;
  }
}

export class SendCodeDTO {
  phone: string = '';
  constructor(phone: string) { this.phone = phone; }
}

// 📥 登录响应数据 (包含 Token)
export interface UserLoginVO {
  id: number;
  openid: string;
  token: string; // 🔑 核心凭证
}
