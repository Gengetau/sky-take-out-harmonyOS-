import { HttpUtil } from '../common/HttpUtil';
import { DishVO, DishFlavor } from '../model/DishModel';

/**
 * 菜品新增/修改 DTO
 */
export class DishDTO {
  id?: number;
  name: string;
  categoryId: number;
  price: number;
  image: string;
  description: string;
  status: number;
  flavors: DishFlavor[]; // ✨ 使用正确的口味模型喵

  constructor(name: string, categoryId: number, price: number, image: string, description: string, status: number = 1, id?: number) {
    this.name = name;
    this.categoryId = categoryId;
    this.price = price;
    this.image = image;
    this.description = description;
    this.status = status;
    this.flavors = [];
    this.id = id;
  }
}

export class DishService {
  /**
   * 根据分类查询菜品列表
   */
  static async getList(categoryId: number): Promise<DishVO[]> {
    return HttpUtil.get<DishVO[]>(`/dish/list?categoryId=${categoryId}`);
  }

  /**
   * 菜品起售/停售
   */
  static async setStatus(id: number, status: number): Promise<void> {
    return HttpUtil.post<void>(`/dish/status/${status}?id=${id}`);
  }

  /**
   * 根据ID查询菜品详情
   */
  static async getById(id: number): Promise<DishVO> {
    return HttpUtil.get<DishVO>(`/dish/${id}`);
  }

  /**
   * 新增菜品
   */
  static async add(dto: DishDTO): Promise<void> {
    return HttpUtil.post<void>('/dish', dto);
  }

  /**
   * 修改菜品
   */
  static async update(dto: DishDTO): Promise<void> {
    return HttpUtil.put<void>('/dish', dto);
  }

  /**
   * 批量删除菜品
   * @param ids 逗号分隔的ID字符串
   */
  static async deleteBatch(ids: string): Promise<void> {
    return HttpUtil.delete<void>(`/dish?ids=${ids}`);
  }

  /**
   * 上传图片
   * @param fileUri 本地文件路径
   * @returns 图片的远程 URL
   */
  static async uploadImage(fileUri: string): Promise<string> {
    return HttpUtil.upload<string>('/common/upload', fileUri);
  }
}