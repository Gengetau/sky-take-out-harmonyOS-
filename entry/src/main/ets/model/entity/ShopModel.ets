// 商店模型
/**
 * 分类模型
 */
export class CategoryVO {
  id: number; // 编号
  type: number; // 类型
  name: string; //名称
  sort: number; //排序
  status: number; //状态 0 禁用 1 启用

  constructor(id: number, type: number, name: string, sort: number, status: number) {
    this.id = id;
    this.type = type;
    this.name = name;
    this.sort = sort;
    this.status = status;
  }
}

/**
 * 商家/店铺模型 (API 1.2 & 1.3)
 */
export interface ShopVO {
  id: number;
  name: string;
  avatar: string; // 临时 OSS 预签名 URL
  score: number; // 评分
  monthlySales: number; // 月售
  deliveryPrice: number; // 起送价
  shippingFee: number; // 配送费
  averageDeliveryTime: number; // 平均配送时间 (分钟)
  distance?: string; // 距离 (由后端计算，如 "1.2km")
  status: number; // 0: 休息中, 1: 营业中
  description?: string; // 店铺公告/描述
  address?: string; // 店铺详细地址
}

/**
 * 菜品口味模型
 */
export class DishFlavor {
  id: number;
  dishId: number; // 菜品id
  name: string; // 口味名称
  value: string; //口味数据, 后端传来的是JSON字符串，如 '["不辣", "微辣"]'

  constructor(id: number, dishId: number, name: string, value: string) {
    this.id = id;
    this.dishId = dishId;
    this.name = name;
    this.value = value;
  }
}

/**
 * 妮娅的魔法 ✨: 把后端传来的口味JSON字符串安全地解析成数组
 * 这是一个独立的工具函数，避免了 `this` 指向和类实例的问题
 * @param value 来自 DishFlavor.value 的字符串
 * @returns string[]
 */
export function parseFlavorOptions(value: string): string[] {
  try {
    // 检查字符串是否看起来像一个数组
    if ( value && value.startsWith('[') && value.endsWith(']') ) {
      const options: string[] = JSON.parse(value);
      if ( Array.isArray(options) ) {
        return options;
      }
    }
    // 如果它不是JSON数组字符串 (比如 "加冰", "标准"), 但也不是空的,
    // 就把它当作一个单一元素的数组返回
    return value ? [ value ] : [];
  } catch ( e ) {
    console.error(`[ShopModel] 解析口味value失败: "${ value }"`, e);
    // 如果解析JSON出错，也把它当作单一元素返回，保证UI不崩溃
    return value ? [ value ] : [];
  }
}


/**
 * 菜品模型
 */
export class DishVO {
  id: number;
  name: string; // 菜品名称
  categoryId: number; // 菜品分类id
  price: number; // 菜品价格
  image: string; // 图片地址
  description: string; // 详细信息
  status: number; // 状态 0 停售 1 起售
  categoryName: string; // 分类名称
  flavors: Array<DishFlavor>; // 菜品口味列表

  constructor(id: number, name: string, categoryId: number, price: number, image: string, description: string,
    status: number, categoryName: string, flavors: Array<DishFlavor>) {
    this.id = id;
    this.name = name;
    this.categoryId = categoryId;
    this.price = price;
    this.image = image;
    this.description = description;
    this.status = status;
    this.categoryName = categoryName;
    this.flavors = flavors;
  }
}

/**
 * 查询菜品模型
 */
export class DishQueryDTO {
  categoryId: number;

  constructor(categoryId: number) {
    this.categoryId = categoryId;
  }
}

/**
 * 套餐模型
 */
export class SetMealVO {
  id: number;
  categoryId: number;
  name: string;
  price: number;
  status: number;
  description: string;
  image: string;

  constructor(id: number, categoryId: number, name: string, price: number, status: number, description: string, image: string) {
    this.id = id;
    this.categoryId = categoryId;
    this.name = name;
    this.price = price;
    this.status = status;
    this.description = description;
    this.image = image;
  }
}

/**
 * 📦 聚合类：分类 + 该分类下的菜品列表
 * (原 MockData 中迁移至此 ✨)
 */
export class CategoryWithItems {
  category: CategoryVO;
  items: DishVO[];

  constructor(category: CategoryVO, items: DishVO[]) {
    this.category = category;
    this.items = items;
  }
}

// 监听装饰器
@Observed
export class CartItem {
  dishId?: number; // 菜品ID (可选)
  setmealId?: number; // 套餐ID (可选)
  name: string;
  image: string;
  price: number;
  count: number;
  flavors: string; // 已选口味字符串，如 "微辣, 加葱"

  constructor(dishId: number | undefined, setmealId: number | undefined, name: string, image: string, price: number, count: number, flavors: string) {
    this.dishId = dishId;
    this.setmealId = setmealId;
    this.name = name;
    this.image = image;
    this.price = price;
    this.count = count;
    this.flavors = flavors;
  }

  // 用于判断是否是同一个规格的菜
  get uniqueKey(): string {
    return `${ this.dishId ?? 'null' }_${ this.setmealId ?? 'null' }_${ this.flavors }`;
  }
}