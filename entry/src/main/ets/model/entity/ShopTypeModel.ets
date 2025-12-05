/**
 * 店铺类型模型
 */
export class ShopTypeVO{
  id: number;
  name:string;
  icon:string;
  sort:number;

  constructor(id:number,name:string,icon:string,sort:number) {
    this.id= id;
    this.name = name;
    this.icon = icon;
    this.sort = sort;
  }

}