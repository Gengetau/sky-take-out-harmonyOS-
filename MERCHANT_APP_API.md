# Meow 外卖商家端 App API 接口规范

*Version: 1.7.0 (全量完备版 - 补齐状态切换接口)*
*Created by: Nia (妮娅)*
*Last Updated: 2025-12-31*

---

## 1. 基础说明 (General)
*(接口基础路径: /admin/app, 鉴权 Header: token, 包含 shopId 隔离)*

---

## 2. 员工/认证模块 (Employee & Auth)
**Base Path**: `/admin/app/employee`
*   `POST /login`: 登录 (7天有效期)
*   `POST /logout`: 退出

---

## 3. 店铺管理模块 (Shop)
**Base Path**: `/admin/app/shop`
*   `GET /`: 获取店铺详情
*   `GET /status`: 获取营业状态
*   `PUT /{status}`: 设置营业状态 (1:营业, 0:打烊)

---

## 4. 订单管理模块 (Order)
**Base Path**: `/admin/app/order`
*   `GET /conditionSearch`: 分页查询订单
*   `GET /statistics`: 订单状态统计
*   `GET /details/{id}`: 查询订单详情
*   `PUT /confirm`: 接单
*   `PUT /rejection`: 拒单
*   `PUT /cancel`: 取消订单
*   `PUT /delivery/{id}`: 派送订单
*   `PUT /complete/{id}`: 完成订单

---

## 5. 分类管理模块 (Category)
**Base Path**: `/admin/app/category`

### 5.1 查询分类列表
*   `GET /list?type=1`: 根据类型查询 (1:菜品, 2:套餐)

### 5.2 新增/修改/删除
*   `POST /`: 新增分类
*   `PUT /`: 修改分类
*   `DELETE /?id=...`: 删除分类

### 5.3 启用/禁用分类 (New! ✨)
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Description**: 启用或禁用分类。
*   **Path Variables**: `status` (1:启用, 0:禁用)
*   **Query Parameters**: `id` (分类ID)
*   **Response**: `{ "code": 1, "msg": null }`

---

## 6. 菜品管理模块 (Dish)
**Base Path**: `/admin/app/dish`

### 6.1 查询/详情
*   `GET /list?categoryId=...`: 按分类查菜品
*   `GET /{id}`: 菜品详情

### 6.2 启用/禁用菜品 (Start/Stop)
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Description**: 起售或停售菜品。停售前会自动检查套餐关联喵。
*   **Path Variables**: `status` (1:起售, 0:停售)
*   **Query Parameters**: `id` (菜品ID)

### 6.3 新增/修改/删除
*   `POST /`: 新增菜品 (包含口味列表)
*   `PUT /`: 修改菜品 (包含口味列表)
*   `DELETE /?ids=1,2`: 批量删除菜品

---

## 7. 套餐管理模块 (Setmeal)
**Base Path**: `/admin/app/setmeal`

### 7.1 查询/详情
*   `GET /list?categoryId=...`: 按分类查套餐
*   `GET /{id}`: 套餐详情

### 7.2 启用/禁用套餐 (Start/Stop)
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Description**: 起售或停售套餐。起售前会自动检查内部菜品状态喵。
*   **Path Variables**: `status` (1:起售, 0:停售)
*   **Query Parameters**: `id` (套餐ID)

### 7.3 新增/修改/删除
*   `POST /`: 新增套餐
*   `PUT /`: 修改套餐
*   `DELETE /?ids=1,2`: 批量删除套餐

---

## 8. 公共接口 (Common)
**Base Path**: `/admin/app/common`
*   `POST /upload`: 文件上传 (返回签名后的访问 URL)

---
*注：所有业务接口均强制检查 shopId 隔离喵！*