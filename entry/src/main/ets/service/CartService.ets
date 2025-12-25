import { common } from '@kit.AbilityKit';
import { CartRdb } from '../common/utils/CartRdb';
import { CartItem, DishVO, SetMealVO } from '../model/entity/ShopModel';

/**
 * 🛒 购物车聚合信息接口 (用于多店展示喵)
 */
export interface ShopCartGroup {
  shopId: number;
  count: number;
  amount: number;
  items: CartItem[];
}

/**
 * 购物车服务 (RDB 持久化版 🛡️)
 */
@Observed
export class CartService {
  // 👁️ 当前店铺的购物车视图
  public cartItems: CartItem[] = [];
  
  // 当前正在操作的 shopId
  private currentShopId: number = 0;
  
  // RDB 是否已就绪
  private isRdbReady: boolean = false;

  private constructor() {
  }

  public static getInstance(): CartService {
    let instance = AppStorage.get<CartService>('CartService');
    if (!instance ) {
      instance = new CartService();
      AppStorage.setOrCreate('CartService', instance);
    }
    return instance;
  }

  /**
   * 🌟 初始化 RDB
   */
  async initRdb(context: common.UIAbilityContext) {
    if (this.isRdbReady) return;
    await CartRdb.init(context);
    this.isRdbReady = true;
    console.info('喵！CartService RDB 已连接');
  }

  /**
   * 🚀 切换当前店铺
   */
  async switchShop(shopId: number) {
    if (shopId <= 0) return;
    
    this.currentShopId = shopId;
    this.cartItems = []; 

    if (this.isRdbReady) {
      try {
        const items = await CartRdb.getCartByShopId(shopId);
        this.cartItems = items;
        console.info(`喵！已从RDB加载店铺 ${shopId} 的购物车，共 ${items.length} 项`);
      } catch (e) {
        console.error('加载店铺购物车失败', e);
      }
    }
    this.notifyUpdate();
  }

  private notifyUpdate() {
    AppStorage.setOrCreate('CartUpdateSignal', Date.now());
  }

  /**
   * 添加商品
   */
  async addItem(dish: DishVO, flavors: string) {
    if (this.currentShopId <= 0) {
      console.warn('喵！未指定店铺，无法添加购物车');
      return;
    }

    const newItem = new CartItem(dish.id, undefined, dish.name, dish.image, dish.price, 1, flavors);
    const existingItem = this.cartItems.find(item => item.uniqueKey === newItem.uniqueKey);

    if ( existingItem ) {
      existingItem.count++;
      this.cartItems = [ ...this.cartItems ];
      if (this.isRdbReady) {
        await CartRdb.saveItem(this.currentShopId, existingItem);
      }
    } else {
      this.cartItems = [ ...this.cartItems, newItem ];
      if (this.isRdbReady) {
        await CartRdb.saveItem(this.currentShopId, newItem);
      }
    }
    
    this.notifyUpdate();
  }

  /**
   * 添加套餐
   */
  async addSetmeal(setmeal: SetMealVO) {
    if (this.currentShopId <= 0) return;

    const newItem = new CartItem(undefined, setmeal.id, setmeal.name, setmeal.image, setmeal.price, 1, '');
    const existingItem = this.cartItems.find(item => item.uniqueKey === newItem.uniqueKey);

    if ( existingItem ) {
      existingItem.count++;
      this.cartItems = [ ...this.cartItems ];
      if (this.isRdbReady) {
        await CartRdb.saveItem(this.currentShopId, existingItem);
      }
    } else {
      this.cartItems = [ ...this.cartItems, newItem ];
      if (this.isRdbReady) {
        await CartRdb.saveItem(this.currentShopId, newItem);
      }
    }
    
    this.notifyUpdate();
  }

  /**
   * 减少商品
   */
  async decreaseItem(itemToDecrease: CartItem) {
    const existingItem = this.cartItems.find(item => item.uniqueKey === itemToDecrease.uniqueKey);
    if ( existingItem ) {
      if ( existingItem.count <= 1 ) {
        await this.removeItem(itemToDecrease);
      } else {
        existingItem.count--;
        if (this.isRdbReady) {
          await CartRdb.saveItem(this.currentShopId, existingItem);
        }
        this.notifyUpdate();
      }
    }
  }

  async increaseItem(itemToIncrease: CartItem) {
    const existingItem = this.cartItems.find(item => item.uniqueKey === itemToIncrease.uniqueKey);
    if (existingItem) {
      existingItem.count++;
      if (this.isRdbReady) {
        await CartRdb.saveItem(this.currentShopId, existingItem);
      }
      this.notifyUpdate();
    }
  }

  async removeItem(itemToRemove: CartItem) {
    this.cartItems = this.cartItems.filter(item => item.uniqueKey !== itemToRemove.uniqueKey);
    if (this.isRdbReady) {
      await CartRdb.deleteItem(this.currentShopId, itemToRemove);
    }
    this.notifyUpdate();
  }

  async clearCart() {
    this.cartItems = [];
    if (this.isRdbReady && this.currentShopId > 0) {
      await CartRdb.clearShopCart(this.currentShopId);
    }
    this.notifyUpdate();
  }

  async clearAllCarts() {
    this.cartItems = [];
    if (this.isRdbReady) {
      await CartRdb.clearAll();
    }
    this.notifyUpdate();
  }

  // --- 📊 统计属性 ---

  get totalCount(): number {
    return this.cartItems.reduce((sum, item) => sum + item.count, 0);
  }

  get totalPrice(): number {
    return this.cartItems.reduce((sum, item) => sum + ( item.price * item.count ), 0);
  }

  /**
   * 🌍 获取所有店铺的购物车总览 (供 CartPage 使用)
   * ✅ 修复 ArkTS 语法：使用正式接口返回喵
   */
  async getAllShopCarts(): Promise<ShopCartGroup[]> {
    if (!this.isRdbReady) return [];
    
    const allCartsMap = await CartRdb.getAllCarts();
    const result: ShopCartGroup[] = [];
    
    // 获取所有键名并遍历喵
    const keys = Object.keys(allCartsMap);
    for (let i = 0; i < keys.length; i++) {
      const shopId = Number(keys[i]);
      const items = allCartsMap[shopId];
      if (items && items.length > 0) {
        const count = items.reduce((sum, item) => sum + item.count, 0);
        const amount = items.reduce((sum, item) => sum + (item.price * item.count), 0);
        result.push({ 
          shopId: shopId, 
          count: count, 
          amount: amount, 
          items: items 
        });
      }
    }
    return result;
  }

  // --- 🛠️ 工具方法 ---

  decreaseItemByDish(dishId: number, flavors: string): void {
    const uniqueKey = `${ dishId }_null_${ flavors }`;
    const existingItem = this.cartItems.find(item => item.uniqueKey === uniqueKey);
    if ( existingItem ) {
      this.decreaseItem(existingItem);
    }
  }

  getDishQuantity(dishId: number, flavors: string): number {
    const uniqueKey = `${ dishId }_null_${ flavors }`;
    const existingItem = this.cartItems.find(item => item.uniqueKey === uniqueKey);
    return existingItem ? existingItem.count : 0;
  }

  getTotalQuantityForDish(dishId: number): number {
    return this.cartItems
      .filter(item => item.dishId === dishId)
      .reduce((sum, item) => sum + item.count, 0);
  }
}