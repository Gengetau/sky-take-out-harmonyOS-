/**
 * 接收后端响应数据
 */
export interface Result<T> {
  code: number;
  msg: string;
  data: T
}
