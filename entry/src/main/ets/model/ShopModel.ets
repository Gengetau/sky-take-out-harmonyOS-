/**
 * 店铺详细信息 VO
 */
export interface ShopInfoVO {
  id: number;
  name: string;
  avatar: string; 
  phone: string;
  address: string;
  score: number;
  status: number; 
  description: string;
  // 🐾 补全 API 3.5 的新字段，确保点语法可用
  deliveryPrice: number;
  shippingFee: number;
}

/**
 * 店铺类型 VO
 */
export interface ShopTypeVO {
  id: number;
  name: string;
  icon: string;
  sort: number;
}

/**
 * 店铺注册 DTO
 */
export class RegisterDTO {
  name: string;
  address: string;
  phone: string;
  shopTypeId: number;
  avatar: string;
  longitude: number;
  latitude: number;

  constructor(name: string, address: string, phone: string, shopTypeId: number, avatar: string, longitude: number, latitude: number) {
    this.name = name;
    this.address = address;
    this.phone = phone;
    this.shopTypeId = shopTypeId;
    this.avatar = avatar;
    this.longitude = longitude;
    this.latitude = latitude;
  }
}
