/**
 * 商店业务
 */
import { HttpUtil } from '../common/utils/HttpUtil';
// 复用我们之前定义的聚合类
import { CategoryWithItems } from '../model/entity/MockData';
import { CategoryVO, DishVO, SetMealVO, ShopVO } from '../model/entity/ShopModel';
import { FollowItem, FollowRdb } from '../common/utils/FollowRdb'; // ✨ 引入 FollowItem

export class ShopService {
  // 🔗 接口地址
  private static readonly CAT_URL = '/client/category';
  private static readonly DISH_URL = '/client/dish';
  private static readonly SETMEAL_URL = '/client/setmeal';
  private static readonly SHOP_STATUS_URL = '/client/shop/status';
  private static readonly SHOP_LIST_URL = '/client/shop/list'; 
  private static readonly SHOP_DETAIL_URL = '/client/shop'; 

  /**
   * ❤️ 关注店铺 (本地 RDB)
   */
  static async followShop(shop: ShopVO): Promise<boolean> {
    return await FollowRdb.getInstance().followShop(shop);
  }

  /**
   * 💔 取消关注 (本地 RDB)
   */
  static async unfollowShop(shopId: number): Promise<boolean> {
    return await FollowRdb.getInstance().unfollowShop(shopId);
  }

  /**
   * 🔍 检查是否已关注 (本地 RDB)
   */
  static async isShopFollowed(shopId: number): Promise<boolean> {
    return await FollowRdb.getInstance().isFollowed(shopId);
  }

  /**
   * 📜 获取关注列表 (本地 RDB)
   */
  static async getFollowList(): Promise<FollowItem[]> {
    return await FollowRdb.getInstance().getFollowList();
  }

  /**
   * 0️⃣ 获取店铺营业状态 (全局)
   */
  static async getShopStatus(): Promise<number> {
    try {
      const status = await HttpUtil.get<number>(ShopService.SHOP_STATUS_URL);
      return status;
    } catch ( e ) {
      console.error('获取店铺状态失败喵', JSON.stringify(e));
      return 0; 
    }
  }

  /**
   * 🌟 0.1️⃣ 获取商家列表 (API 1.2)
   */
  static async getShopList(typeId: number, longitude?: number, latitude?: number, page: number = 1): Promise<ShopVO[]> {
    let url = `${ ShopService.SHOP_LIST_URL }/${ typeId }?page=${ page }`;
    if ( longitude !== undefined && latitude !== undefined ) {
      url += `&longitude=${ longitude }&latitude=${ latitude }`;
    }
    try {
      const list = await HttpUtil.get<ShopVO[]>(url);
      return list || [];
    } catch ( e ) {
      console.error('获取商家列表失败喵', e);
      return [];
    }
  }

  /**
   * 🌟 0.2️⃣ 获取商家详情 (API 1.3)
   */
  static async getShopDetail(id: number): Promise<ShopVO | null> {
    try {
      return await HttpUtil.get<ShopVO>(`${ ShopService.SHOP_DETAIL_URL }/${ id }`);
    } catch ( e ) {
      console.error(`获取商家 ${ id } 详情失败喵`, e);
      return null;
    }
  }

  /**
   * 🌟 1️⃣ 获取指定店铺的分类列表 (API 4.1 升级版 ✨)
   */
  static async getCategoryList(shopId: number): Promise<CategoryVO[]> {
    try {
      // 现在的接口需要带上 shopId 喵
      const url = `${ ShopService.CAT_URL }/all/${ shopId }`;
      const list = await HttpUtil.get<CategoryVO[]>(url);
      return list || [];
    } catch ( err ) {
      console.error(`获取商家 ${ shopId } 的分类失败喵`);
      return [];
    }
  }

  /**
   * 2️⃣ 获取某分类下的菜品
   */
  static async getDishList(categoryId: number): Promise<DishVO[]> {
    try {
      const url = `${ ShopService.DISH_URL }/${ categoryId }`;
      const list = await HttpUtil.get<DishVO[]>(url);
      return list || [];
    } catch ( err ) {
      console.error(`获取分类 ${ categoryId } 的菜品失败喵`);
      return []; 
    }
  }

  /**
   * 2.5️⃣ 获取某分类下的套餐
   */
  static async getSetmealList(categoryId: number): Promise<SetMealVO[]> {
    try {
      const url = `${ ShopService.SETMEAL_URL }/${ categoryId }`;
      const list = await HttpUtil.get<SetMealVO[]>(url);
      return list || [];
    } catch ( err ) {
      console.error(`获取分类 ${ categoryId } 的套餐失败喵`);
      return [];
    }
  }


  /**
   * 🚀 3️⃣ 【核心大招】获取全店数据 (分类 + 菜品/套餐) 并组装
   * 现在必须传入 shopId 喵！
   */
  static async getShopData(shopId: number): Promise<CategoryWithItems[]> {
    // A. 先拿指定商店的所有分类
    const categories = await ShopService.getCategoryList(shopId);
    if ( categories.length === 0 ) {
      return [];
    }

    // B. 并发请求内容
    const tasks = categories.map(async(cat) => {
      let items: DishVO[] = [];
      if ( cat.type === 1 ) {
        items = await ShopService.getDishList(cat.id);
      } else {
        const setmeals = await ShopService.getSetmealList(cat.id);
        items = setmeals.map(s => new DishVO(
          s.id,
          s.name,
          s.categoryId,
          s.price,
          s.image,
          s.description,
          s.status,
          cat.name, 
          []
        ));
      }
      return new CategoryWithItems(cat, items);
    });

    const result = await Promise.all(tasks);
    return result;
  }
}