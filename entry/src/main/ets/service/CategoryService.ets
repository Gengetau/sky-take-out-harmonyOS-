import { HttpUtil } from '../common/HttpUtil';
import { CategoryVO, CategoryStatusDTO } from '../model/CategoryModel';

/**
 * 分类新增/修改 DTO
 */
export class CategoryDTO {
  id?: number;
  type: number; // 1:菜品分类 2:套餐分类
  name: string;
  sort: number;

  constructor(type: number, name: string, sort: number, id?: number) {
    this.type = type;
    this.name = name;
    this.sort = sort;
    this.id = id;
  }
}

export class CategoryService {
  /**
   * 根据类型查询分类列表
   * @param type 1:菜品分类, 2:套餐分类
   */
  static async getList(type: number): Promise<CategoryVO[]> {
    return HttpUtil.get<CategoryVO[]>(`/category/list?type=${type}`);
  }

  /**
   * 启用/禁用分类
   */
  static async setStatus(id: number, status: number): Promise<void> {
    return HttpUtil.post<void>(`/category/status/${status}?id=${id}`);
  }

  /**
   * 新增分类
   */
  static async add(dto: CategoryDTO): Promise<void> {
    return HttpUtil.post<void>('/category', dto);
  }

  /**
   * 修改分类
   */
  static async update(dto: CategoryDTO): Promise<void> {
    return HttpUtil.put<void>('/category', dto);
  }

  /**
   * 删除分类
   */
  static async deleteById(id: number): Promise<void> {
    return HttpUtil.delete<void>(`/category?id=${id}`);
  }
}