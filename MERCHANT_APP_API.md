# Meow 外卖商家端 App API 接口规范

*Version: 1.1.0*
*Created by: Nia (妮娅)*
*Last Updated: 2025-12-31*

## 1. 基础说明 (General)

### 1.1 接口前缀
所有商家端 App 接口的基础路径为：`/admin/app`

### 1.2 鉴权方式
*   **登录接口**：无需 Token。
*   **业务接口**：必须在 HTTP Header 中携带 JWT Token。
    *   Header Key: `token`
    *   Token Value: 登录接口返回的 token 字符串。
    *   Token Payload 中包含 `empId` (员工ID) 和 `shopId` (店铺ID)，后端会自动解析并进行数据隔离。

### 1.3 统一响应格式
```json
{
  "code": 1,          // 1: 成功, 0: 失败
  "msg": "success",   // 错误信息或提示信息
  "data": { ... }     // 业务数据
}
```

---

## 2. 员工/认证模块 (Employee & Auth)
**Base Path**: `/admin/app/employee`

### 2.1 登录 (Login)
*   **URL**: `/login`
*   **Method**: `POST`
*   **Description**: 商家员工登录，获取 Token 和店铺信息。
*   **Request Body**:
```json
{
  "username": "admin",
  "password": "123456"
}
```
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "id": 1,
    "userName": "admin",
    "name": "管理员",
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "shopId": 1
  }
}
```

### 2.2 退出 (Logout)
*   **URL**: `/logout`
*   **Method**: `POST`
*   **Description**: 退出登录。

---

## 3. 店铺管理模块 (Shop)
**Base Path**: `/admin/app/shop`

### 3.1 获取营业状态
*   **URL**: `/status`
*   **Method**: `GET`
*   **Description**: 获取当前店铺的营业状态。
*   **Response**: `{"code": 1, "data": 1}` (1:营业, 0:打烊)

### 3.2 设置营业状态
*   **URL**: `/{status}`
*   **Method**: `PUT`
*   **Description**: 切换店铺营业/打烊状态。
*   **Path Variables**: `status` (1或0)

---

## 4. 订单管理模块 (Order)
**Base Path**: `/admin/app/order`

### 4.1 分页查询订单列表
*   **URL**: `/conditionSearch`
*   **Method**: `GET`
*   **Description**: 分页查询当前店铺的订单。
*   **Query Params**: `page`, `pageSize`, `status`, `number`, `phone`, `beginTime`, `endTime`

### 4.2 订单统计
*   **URL**: `/statistics`
*   **Method**: `GET`
*   **Description**: 获取当前店铺待接单、待派送、派送中订单的数量。

### 4.3 查询订单详情
*   **URL**: `/details/{id}`
*   **Method**: `GET`
*   **Description**: 获取单个订单的详细信息。

### 4.4 接单 (Confirm)
*   **URL**: `/confirm`
*   **Method**: `PUT`
*   **Request Body**: `{"id": 1}`

### 4.5 拒单 (Reject)
*   **URL**: `/rejection`
*   **Method**: `PUT`
*   **Request Body**: `{"id": 1, "rejectionReason": "..."}`

### 4.6 派送订单 (Delivery)
*   **URL**: `/delivery/{id}`
*   **Method**: `PUT`

### 4.7 完成订单 (Complete)
*   **URL**: `/complete/{id}`
*   **Method**: `PUT`

---

## 5. 分类管理模块 (Category)
**Base Path**: `/admin/app/category`

### 5.1 根据类型查询分类
*   **URL**: `/list`
*   **Method**: `GET`
*   **Description**: 查询当前店铺的菜品分类或套餐分类。
*   **Query Parameters**:
    *   `type`: 分类类型 (1:菜品分类, 2:套餐分类)
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": [
    {
      "id": 11,
      "type": 1,
      "name": "酒水饮料",
      "sort": 10,
      "status": 1
    }
  ]
}
```

---

## 6. 菜品管理模块 (Dish)
**Base Path**: `/admin/app/dish`

### 6.1 根据分类查询菜品列表
*   **URL**: `/list`
*   **Method**: `GET`
*   **Description**: 获取指定分类下的所有菜品信息。
*   **Query Parameters**:
    *   `categoryId`: 分类ID
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": [
    {
      "id": 46,
      "name": "王老吉",
      "categoryId": 11,
      "price": 6.00,
      "image": "http://...",
      "description": "",
      "status": 1,
      "categoryName": "酒水饮料"
    }
  ]
}
```

### 6.2 根据ID查询菜品详情
*   **URL**: `/{id}`
*   **Method**: `GET`
*   **Description**: 获取菜品详情，包括口味列表。
*   **Path Variables**:
    *   `id`: 菜品ID

### 6.3 菜品起售/停售
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Description**: 启用或禁用某个菜品。
*   **Path Variables**:
    *   `status`: 1 (起售), 0 (停售)
*   **Query Parameters**:
    *   `id`: 菜品ID
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

---
*注：所有业务接口均会自动检查数据所属权，确保商家只能操作其名下的店铺、分类和菜品喵！*