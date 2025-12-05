import { HttpUtil } from '../common/utils/HttpUtil';
import { ShopTypeVO } from '../model/entity/ShopTypeModel';

/**
 * 首页业务
 */
export class HomeService {
  // 🔗 接口地址常量 (C端接口)
  private static readonly QUERY_TYPELIST = '/client/type/list';

  /**
   * 获取店铺列表
   */
  static async getShopTypes(): Promise<ShopTypeVO[]> {
    try {
      const result = await HttpUtil.get<ShopTypeVO[]>(HomeService.QUERY_TYPELIST);

      console.info(`后端返回的数据是: ${ result }`);
      return result;
    } catch ( err ) {
      console.error('发送验证码失败');
      return [];
    }
  }
}