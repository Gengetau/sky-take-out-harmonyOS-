
/**
 * 地址簿模型
 * 喵！这个模型用来记录用户的收货地址信息。
 */
export interface AddressBook {
  id: number;
  userId?: number;   // 用户ID
  consignee: string; // 收货人
  phone: string;     // 手机号
  sex: string;       // 性别 0 女 1 男
  provinceCode: string;
  provinceName: string;
  cityCode: string;
  cityName: string;
  districtCode: string;
  districtName: string;
  detail: string;    // 详细地址
  label: string;     // 标签（家、公司）
  isDefault: number; // 是否默认 0 否 1 是
}
