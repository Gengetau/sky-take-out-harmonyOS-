import { HttpUtil } from '../common/HttpUtil';
import { ShopInfoVO, ShopTypeVO } from '../model/ShopModel';

export class ShopService {
  /**
   * 获取店铺详情
   */
  static async getShopInfo(): Promise<ShopInfoVO> {
    return HttpUtil.get<ShopInfoVO>('/shop/'); 
  }

  /**
   * 修改店铺信息喵 (API 3.5)
   */
  static async updateShopInfo(data: Partial<ShopInfoVO>): Promise<void> {
    return HttpUtil.put<void>('/shop/', data);
  }

  /**
   * 获取店铺营业状态
   */
  static async getStatus(): Promise<number> {
    return HttpUtil.get<number>('/shop/status');
  }

  /**
   * 设置店铺营业状态
   */
  static async setStatus(status: number): Promise<void> {
    return HttpUtil.put<void>(`/shop/${status}`);
  }

  /**
   * 注册新店铺
   */
  static async register(data: object): Promise<void> {
    return HttpUtil.post<void>('/shop/register', data);
  }

  /**
   * 获取店铺类型列表
   */
  static async getShopTypes(): Promise<ShopTypeVO[]> {
    return HttpUtil.get<ShopTypeVO[]>('/type/list');
  }
}
