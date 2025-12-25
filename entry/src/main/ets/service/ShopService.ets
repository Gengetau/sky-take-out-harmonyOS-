/**
 * 商店业务
 */
import { HttpUtil } from '../common/utils/HttpUtil';
// 复用我们之前定义的聚合类
import { CategoryWithItems } from '../model/entity/MockData';
import { CategoryVO, DishVO, SetMealVO, ShopVO } from '../model/entity/ShopModel';

export class ShopService {
  // 🔗 接口地址
  private static readonly CAT_URL = '/client/category';
  private static readonly DISH_URL = '/client/dish';
  private static readonly SETMEAL_URL = '/client/setmeal';
  private static readonly SHOP_STATUS_URL = '/client/shop/status';
  private static readonly SHOP_LIST_URL = '/client/shop/list'; // 商家列表
  private static readonly SHOP_DETAIL_URL = '/client/shop'; // 商家详情

  /**
   * 0️⃣ 获取店铺营业状态 (全局)
   */
  static async getShopStatus(): Promise<number> {
    try {
      const status = await HttpUtil.get<number>(ShopService.SHOP_STATUS_URL);
      return status;
    } catch ( e ) {
      console.error('获取店铺状态失败喵', JSON.stringify(e));
      return 0; // 默认返回休息中
    }
  }

  /**
   * 🌟 0.1️⃣ 获取商家列表 (API 1.2)
   * @param typeId 分类ID
   * @param longitude 经度
   * @param latitude 纬度
   * @param page 页码
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
   * @param id 商家ID
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
   * 1️⃣ 获取分类列表
   */
  static async getCategoryList(): Promise<CategoryVO[]> {
    try {
      const url = `${ ShopService.CAT_URL }/all`;
      const list = await HttpUtil.get<CategoryVO[]>(url);
      return list || [];
    } catch ( err ) {
      console.error('获取分类失败');
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
      return []; // 失败返回空数组，不影响其他分类显示
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
   * 供 UI 层直接调用，拿到就是能用的结构！
   */
  static async getShopData(): Promise<CategoryWithItems[]> {
    // A. 先拿所有分类
    const categories = await ShopService.getCategoryList();
    if ( categories.length === 0 ) {
      return [];
    }

    // B. 并发请求：同时去拿每一个分类下的内容 (效率最高！)
    const tasks = categories.map(async(cat) => {
      let items: DishVO[] = [];
      if ( cat.type === 1 ) {
        // 菜品
        items = await ShopService.getDishList(cat.id);
      } else {
        // 套餐 (SetMealVO) -> 转换为 DishVO
        const setmeals = await ShopService.getSetmealList(cat.id);
        items = setmeals.map(s => new DishVO(
          s.id,
          s.name,
          s.categoryId,
          s.price,
          s.image,
          s.description,
          s.status,
          cat.name, // categoryName
          []// flavors
        ));
      }
      // 组装成我们要的结构
      return new CategoryWithItems(cat, items);
    });

    // C. 等待所有请求完成
    const result = await Promise.all(tasks);

    // 过滤掉没有菜品的分类 (可选，防止显示空标题)
    // return result.filter(item => item.items.length > 0);
    return result;
  }
}