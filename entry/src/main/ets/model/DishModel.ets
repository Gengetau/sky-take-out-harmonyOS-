/**
 * 菜品口味模型
 */
export class DishFlavor {
  id?: number;
  dishId?: number; // 菜品id
  name: string; // 口味名称
  value: string; //口味数据, 后端传来的是JSON字符串，如 '["不辣", "微辣"]'

  constructor(name: string, value: string, id?: number, dishId?: number) {
    this.name = name;
    this.value = value;
    this.id = id;
    this.dishId = dishId;
  }
}

/**
 * 菜品模型
 */
export interface DishVO {
  id: number;
  name: string;
  categoryId: number;
  categoryName?: string;
  price: number;
  image: string;
  description: string;
  status: number; // 1:起售, 0:停售
  updateTime?: string;
  flavors: DishFlavor[]; // ✨ 菜品口味列表
}

/**
 * 菜品状态修改 DTO
 */
export class DishStatusDTO {
  id: number;
  status: number;

  constructor(id: number, status: number) {
    this.id = id;
    this.status = status;
  }
}