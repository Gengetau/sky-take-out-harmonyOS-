/**
 * 商店业务
 */
import { HttpUtil } from '../common/utils/HttpUtil';
// 复用我们之前定义的聚合类
import { CategoryWithDishes } from '../model/entity/MockData';
import { CategoryVO, DishVO } from '../model/entity/ShopModel';

export class ShopService {
  // 🔗 接口地址
  private static readonly CAT_URL = '/client/category';
  private static readonly DISH_URL = '/client/dish';
  private static readonly SHOP_STATUS_URL = '/client/shop/status';

  /**
   * 0️⃣ 获取店铺营业状态
   */
  static async getShopStatus(): Promise<number> {
    try {
      const status = await HttpUtil.get<number>(ShopService.SHOP_STATUS_URL);
      return status;
    } catch (e) {
      console.error('获取店铺状态失败喵', JSON.stringify(e));
      return 0; // 默认返回休息中
    }
  }

  /**
   * 1️⃣ 获取分类列表
   */
  static async getCategoryList(): Promise<CategoryVO[]> {
    try {
      const url = `${ ShopService.CAT_URL }/1`;
      // type=1 表示菜品分类 (type=2是套餐，暂时只看菜品)
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
   * 🚀 3️⃣ 【核心大招】获取全店数据 (分类 + 菜品) 并组装
   * 供 UI 层直接调用，拿到就是能用的结构！
   */
  static async getShopData(): Promise<CategoryWithDishes[]> {
    // A. 先拿所有分类
    const categories = await ShopService.getCategoryList();
    if ( categories.length === 0 ) {
      return [];
    }

    // B. 并发请求：同时去拿每一个分类下的菜品 (效率最高！)
    // map 生成一个 Promise 数组
    const tasks = categories.map(async(cat) => {
      const dishes = await ShopService.getDishList(cat.id);
      // 组装成我们要的结构
      return new CategoryWithDishes(cat, dishes);
    });

    // C. 等待所有请求完成
    const result = await Promise.all(tasks);

    // 过滤掉没有菜品的分类 (可选，防止显示空标题)
    // return result.filter(item => item.dishes.length > 0);
    return result;
  }
}