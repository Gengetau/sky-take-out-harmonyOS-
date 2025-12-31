/**
 * 分类模型
 */
export interface CategoryVO {
  id: number;
  type: number; // 1:菜品分类, 2:套餐分类
  name: string;
  sort: number;
  status: number; // 1:启用, 0:禁用
}

/**
 * 修改分类状态 DTO
 */
export class CategoryStatusDTO {
  id: number;
  status: number;

  constructor(id: number, status: number) {
    this.id = id;
    this.status = status;
  }
}
