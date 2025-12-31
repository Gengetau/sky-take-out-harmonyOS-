/**
 * 店铺详细信息 VO
 */
export interface ShopInfoVO {
  id: number;
  name: string;
  avatar: string; // ✨ 店铺 Logo
  phone: string;
  address: string;
  score: number;
  status: number; // 营业状态 1:营业 0:打烊
  description: string;
}