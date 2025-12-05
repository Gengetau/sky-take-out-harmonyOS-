import { ShopTypeVO } from "../../model/entity/ShopTypeModel";

/**
 * 首页金刚图GridItem组件
 */
export class HomeGridItem {
  type: ShopTypeVO;
  constructor(type:ShopTypeVO) {
    this.type = type;
  }
}