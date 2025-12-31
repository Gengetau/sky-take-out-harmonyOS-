import { HttpUtil } from '../common/HttpUtil';

/**
 * 套餐内菜品 DTO/VO
 */
export class SetmealDishDTO {
  dishId: number;
  copies: number;
  name?: string; // 可选，用于回显
  price?: number;

  constructor(dishId: number, copies: number) {
    this.dishId = dishId;
    this.copies = copies;
  }
}

/**
 * 套餐完整信息 VO
 */
export interface SetmealVO {
  id: number;
  categoryId: number;
  categoryName?: string;
  name: string;
  price: number;
  status: number; // 1:起售, 0:停售
  description: string;
  image: string;
  updateTime?: string;
  setmealDishes: SetmealDishDTO[]; // ✨ 加上这个字段，any 就消失啦喵！
}

/**
 * 套餐新增/修改 DTO
 */
export class SetmealDTO {
  id?: number;
  categoryId: number;
  name: string;
  price: number;
  status: number;
  description: string;
  image: string;
  setmealDishes: SetmealDishDTO[];

  constructor(categoryId: number, name: string, price: number, image: string, description: string, dishes: SetmealDishDTO[], id?: number) {
    this.categoryId = categoryId;
    this.name = name;
    this.price = price;
    this.image = image;
    this.description = description;
    this.setmealDishes = dishes;
    this.status = 1;
    this.id = id;
  }
}

export class SetmealService {
  /**
   * 分类查询套餐
   */
  static async getList(categoryId: number): Promise<SetmealVO[]> {
    return HttpUtil.get<SetmealVO[]>(`/setmeal/list?categoryId=${categoryId}`);
  }

  /**
   * 套餐起售/停售
   */
  static async setStatus(id: number, status: number): Promise<void> {
    return HttpUtil.post<void>(`/setmeal/status/${status}?id=${id}`);
  }

  /**
   * 根据ID查询套餐详情
   */
  static async getById(id: number): Promise<SetmealVO> {
    return HttpUtil.get<SetmealVO>(`/setmeal/${id}`);
  }

  /**
   * 新增套餐
   */
  static async add(dto: SetmealDTO): Promise<void> {
    return HttpUtil.post<void>('/setmeal', dto);
  }

  /**
   * 修改套餐
   */
  static async update(dto: SetmealDTO): Promise<void> {
    return HttpUtil.put<void>('/setmeal', dto);
  }

  /**
   * 批量删除套餐
   */
  static async deleteBatch(ids: string): Promise<void> {
    return HttpUtil.delete<void>(`/setmeal?ids=${ids}`);
  }
}
