/**
 * 选中的位置信息
 */
export interface LocationInfo {
  latitude: number;
  longitude: number;
  address: string; // 详细地址描述
  province: string;
  city: string;
  district: string;
  name: string; // POI名称 (如：天安门)
}
