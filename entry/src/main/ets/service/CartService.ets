import { CartItem, DishVO } from '../model/entity/ShopModel';

// 使用 @Observed 装饰器，让这个类的数据变化可以被UI感知到喵
@Observed
export class CartService {
  // 购物车中的所有商品喵
  public cartItems: CartItem[] = [];

  // 私有构造函数，保证这是个单例，不能随便 new 喵
  private constructor() {
  }

  // 获取单例实例的唯一方法喵
  public static getInstance(): CartService {
    // 从 AppStorage 中获取或创建一个单例实例喵
    // 这样可以保证在应用的整个生命周期中，只有一个 CartService 实例存在喵
    let instance = AppStorage.get<CartService>('CartService');
    if (!instance ) {
      instance = new CartService();
      AppStorage.setOrCreate('CartService', instance);
    }
    return instance;
  }

  /**
   * 发送更新信号
   */
  private notifyUpdate() {
    // 写入一个当前时间戳，保证每次值都不一样，强制触发 UI 更新
    AppStorage.setOrCreate('CartUpdateSignal', Date.now());
    console.info(`喵！购物车发生变动，广播已发出！当前总数: ${ this.totalCount }`);
  }

  /**
   * 添加商品到购物车喵
   * @param dish 要添加的菜品
   * @param flavors 选择的口味，如果没有则为空字符串喵
   */
  addItem(dish: DishVO, flavors: string): void {
    const newItem = new CartItem(dish.id, dish.name, dish.image, dish.price, 1, flavors);
    const existingItem = this.cartItems.find(item => item.uniqueKey === newItem.uniqueKey);

    if ( existingItem ) {
      // 如果购物车里已经有这个规格的菜了，数量+1就好喵
      existingItem.count++;
      // 关键改动：创建一个新数组副本，强制触发UI更新！
      this.cartItems = [ ...this.cartItems ];
    } else {
      // 关键改动：使用扩展运算符创建一个新数组，而不是用 a.push(b)
      this.cartItems = [ ...this.cartItems, newItem ];
    }
    // ArkUI 是响应式的，数组的变化会自动触发UI更新，妮娅在控制台打印一下方便主人调试喵
    console.info(`喵！购物车更新: ${ JSON.stringify(this.cartItems) }`);
    this.notifyUpdate();
  }

  /**
   * 从购物车减少一个商品数量喵
   * @param itemToDecrease 要减少数量的购物车项
   */
  decreaseItem(itemToDecrease: CartItem): void {
    const existingItem = this.cartItems.find(item => item.uniqueKey === itemToDecrease.uniqueKey);
    if ( existingItem ) {
      if ( existingItem.count <= 1 ) {
        // 如果数量只有1了，就直接移除它喵
        this.removeItem(itemToDecrease);
      } else {
        existingItem.count--;
        // 关键改动：创建一个新数组副本，强制触发UI更新！
        this.notifyUpdate();
      }
    }
    console.info(`喵！购物车更新: ${ JSON.stringify(this.cartItems) }`);
  }

  /**
   * 妮娅的新方法：从购物车增加一个商品数量喵
   * @param itemToIncrease 要增加数量的购物车项
   */
  increaseItem(itemToIncrease: CartItem): void {
    const existingItem = this.cartItems.find(item => item.uniqueKey === itemToIncrease.uniqueKey);
    if (existingItem) {
      existingItem.count++;
      this.notifyUpdate();
    }
    console.info(`喵！购物车更新: ${ JSON.stringify(this.cartItems) }`);
  }

  /**
   * 从购物车里完完整整地移除一个条目喵
   * @param itemToRemove
   */
  removeItem(itemToRemove: CartItem): void {
    // 关键改动：使用 filter() 返回一个全新的数组，保证响应性！
    this.cartItems = this.cartItems.filter(item => item.uniqueKey !== itemToRemove.uniqueKey);
    this.notifyUpdate();
  }


  /**
   * 一键清空购物车喵！
   */
  clearCart(): void {
    this.cartItems = [];
    console.info('喵~ 购物车已清空！');
    this.notifyUpdate();
  }

  // 这是个计算属性，自动计算购物车里所有商品的总件数喵
  get totalCount(): number {
    return this.cartItems.reduce((sum, item) => sum + item.count, 0);
  }

  // 这也是个计算属性，自动计算购物车里所有商品的总价钱喵
  get totalPrice(): number {
    return this.cartItems.reduce((sum, item) => sum + ( item.price * item.count ), 0);
  }

  // --- 妮娅新增的三个工具方法喵 ---

  /**
   * 根据菜品ID和口味减少一项商品喵
   */
  decreaseItemByDish(dishId: number, flavors: string): void {
    const uniqueKey = `${ dishId }_${ flavors }`;
    const existingItem = this.cartItems.find(item => item.uniqueKey === uniqueKey);
    if ( existingItem ) {
      this.decreaseItem(existingItem); // 复用已有的 decreaseItem 逻辑喵
    }
  }

  /**
   * 获取指定规格菜品在购物车中的数量喵
   */
  getDishQuantity(dishId: number, flavors: string): number {
    const uniqueKey = `${ dishId }_${ flavors }`;
    const existingItem = this.cartItems.find(item => item.uniqueKey === uniqueKey);
    return existingItem ? existingItem.count : 0;
  }

  /**
   * 获取指定菜品（不区分规格）在购物车中的总数量喵
   */
  getTotalQuantityForDish(dishId: number): number {
    return this.cartItems
      .filter(item => item.dishId === dishId)
      .reduce((sum, item) => sum + item.count, 0);
  }
}
