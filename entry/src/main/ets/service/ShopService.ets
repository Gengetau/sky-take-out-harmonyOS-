import { HttpUtil } from '../common/HttpUtil';

export class ShopService {
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
