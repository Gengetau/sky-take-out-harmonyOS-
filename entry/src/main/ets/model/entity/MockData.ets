/**
 * 模拟数据
 */
import { CategoryVO, DishFlavor, DishVO } from './ShopModel'; // 假设您的模型在这个文件里

export class MockData {
  // 1. 模拟分类数据 (左侧列表)
  static getCategories(): CategoryVO[] {
    return [
      new CategoryVO(1, 1, '今日特惠', 1, 1),
      new CategoryVO(2, 1, '精品热菜', 2, 1),
      new CategoryVO(3, 1, '爽口凉菜', 3, 1),
      new CategoryVO(4, 1, '主食', 4, 1),
      new CategoryVO(5, 1, '饮料', 5, 1),
    ];
  }

  // 2. 模拟菜品数据 (右侧列表)
  // 为了方便 ListItemGroup 分组，我们通常需要一个方法：根据分类ID获取菜品
  static getDishes(): DishVO[] {
    return [
      // --- Category 1: 今日特惠 ---
      new DishVO(101, '特价大盘鸡', 1, 29.9, 'fig1', '分量足，味道鲜', 1, '今日特惠', [
        new DishFlavor(1, 101, '辣度', '[ "微辣", "中辣" ]')
      ]),

      // --- Category 2: 精品热菜 ---
      new DishVO(201, '龙井虾仁', 2, 88.0, 'fig2', '清新爽口', 1, '精品热菜', []),
      new DishVO(202, '宫保鸡丁', 2, 48.0, 'fig3', '经典川菜', 1, '精品热菜', [
        new DishFlavor(2, 202, '辣度', '[ "微辣", "特辣" ]'),
        new DishFlavor(3, 202, '加料', '[ "加花生", "加葱" ]')
      ]),
      new DishVO(203, '红烧肉', 2, 68.0, 'fig4', '肥而不腻', 1, '精品热菜', []),

      // --- Category 3: 爽口凉菜 ---
      new DishVO(301, '拍黄瓜', 3, 12.0, 'fig1', '脆爽', 1, '爽口凉菜', []),
      new DishVO(302, '凉拌木耳', 3, 16.0, 'fig2', '解腻神器', 1, '爽口凉菜', []),

      // --- Category 4: 主食 ---
      new DishVO(401, '米饭', 4, 2.0, 'fig3', '五常大米', 1, '主食', []),
      new DishVO(402, '馒头', 4, 1.0, 'fig4', '手工大馒头', 1, '主食', []),
    ];
  }

  /**
   * 🛠️ 辅助方法：把数据整合成 ListItemGroup 需要的结构
   * 结构：CategoryVO -> [DishVO, DishVO...]
   */
  static getCategoryWithItems(): CategoryWithItems[] {
    const categories = MockData.getCategories();
    const allDishes = MockData.getDishes();

    return categories.map(cat => {
      // 找到该分类下的所有菜品
      const items = allDishes.filter(d => d.categoryId === cat.id);
      return new CategoryWithItems(cat, items);
    });
  }
}

// 📦 定义一个聚合类，专门给点餐页面的列表用
export class CategoryWithItems {
  category: CategoryVO;
  items: DishVO[];

  constructor(category: CategoryVO, items: DishVO[]) {
    this.category = category;
    this.items = items;
  }
}