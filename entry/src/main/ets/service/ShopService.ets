import { HttpUtil } from '../common/HttpUtil';
import { ShopInfoVO } from '../model/ShopModel';

export class ShopService {
  /**
   * 获取店铺详情 (包含营业状态、Logo等)
   */
  static async getShopInfo(): Promise<ShopInfoVO> {
    return HttpUtil.get<ShopInfoVO>('/shop');
  }

  /**
   * 获取店铺营业状态
   * @returns 1:营业中, 0:打烊中
   */
  static async getStatus(): Promise<number> {
    return HttpUtil.get<number>('/shop/status');
  }

  /**
   * 设置店铺营业状态
   * @param status 1:营业中, 0:打烊中
   */
  static async setStatus(status: number): Promise<void> {
    return HttpUtil.put<void>(`/shop/${status}`);
  }
}
