# Meow 外卖商家端 App API 接口规范

*Version: 1.7.0 (全量终极完备版 - 严禁任何简写)*
*Created by: Nia (妮娅)*
*Last Updated: 2025-12-31*

---

## 1. 基础说明 (General)

### 1.1 接口前缀
所有商家端 App 接口的基础路径为：`/admin/app`

### 1.2 鉴权方式
*   **登录接口**：无需 Token。
*   **业务接口**：必须在 Header 中携带 Token。
    *   Header Key: `token`
    *   Token Payload: 包含 `empId` (员工ID) 和 `shopId` (店铺ID)，后端会自动解析并强制进行数据隔离。

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
*   **Description**: 商家员工登录。App端 Token 有效期为 7 天喵。
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
*   **Description**: 退出登录，清理上下文。
*   **Response (Success)**:
```json
{ "code": 1, "msg": null, "data": null }
```

---

## 3. 店铺管理模块 (Shop)
**Base Path**: `/admin/app/shop`

### 3.1 获取店铺详情
*   **URL**: `/`
*   **Method**: `GET`
*   **Description**: 获取当前员工所属店铺的详细资料。
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "id": 1,
    "name": "苍穹外卖总店",
    "avatar": "https://oss-url/signed-logo.png",
    "phone": "400-123-4567",
    "address": "北京市海淀区中关村",
    "score": 5.0,
    "status": 1,
    "description": "官方直营，品质保证喵！"
  }
}
```

### 3.2 获取营业状态
*   **URL**: `/status`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{ "code": 1, "data": 1 } // 1: 营业中, 0: 打烊中
```

### 3.3 设置营业状态
*   **URL**: `/{status}`
*   **Method**: `PUT`
*   **Description**: 切换店铺营业/打烊状态。
*   **Path Variables**: `status` (1:营业, 0:打烊)
*   **Response (Success)**:
```json
{ "code": 1, "msg": null }
```

---

## 4. 订单管理模块 (Order)
**Base Path**: `/admin/app/order`

### 4.1 分页查询订单列表
*   **URL**: `/conditionSearch`
*   **Method**: `GET`
*   **Query Params**: `page`, `pageSize`, `status`, `number`, `phone`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "total": 100,
    "records": [
      {
        "id": 1001,
        "number": "202312310001",
        "status": 2,
        "amount": 88.50,
        "orderTime": "2025-12-31 10:00:00",
        "consignee": "张先生",
        "phone": "13800000000",
        "address": "中关村大街1号",
        "orderDishes": "宫保鸡丁*1, 米饭*2"
      }
    ]
  }
}
```

### 4.2 订单统计
*   **URL**: `/statistics`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "toBeConfirmed": 5,      
    "confirmed": 2,          
    "deliveryInProgress": 1  
  }
}
```

### 4.3 查询订单详情
*   **URL**: `/details/{id}`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "id": 1001,
    "number": "202312310001",
    "status": 2,
    "amount": 88.50,
    "payMethod": 1,
    "consignee": "张先生",
    "phone": "13800000000",
    "address": "北京市海淀区...",
    "remark": "多加点辣",
    "orderDetailList": [
      {
        "name": "宫保鸡丁",
        "image": "https://oss-url/signed-food.png",
        "dishFlavor": "微辣",
        "number": 1,
        "amount": 38.00
      }
    ]
  }
}
```

### 4.4 接单/拒单/派送/完成
*   `PUT /confirm`: 接单 (Body: `{"id": 1001}`)
*   `PUT /rejection`: 拒单 (Body: `{"id": 1001, "rejectionReason": "..."}`)
*   `PUT /cancel`: 取消 (Body: `{"id": 1001, "cancelReason": "..."}`)
*   `PUT /delivery/{id}`: 派送
*   `PUT /complete/{id}`: 完成

---

## 5. 分类管理模块 (Category)
**Base Path**: `/admin/app/category`

### 5.1 查询分类列表
*   **URL**: `/list`
*   **Method**: `GET`
*   **Query Params**: `type` (1:菜品, 2:套餐)
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": [
    { "id": 11, "type": 1, "name": "酒水饮料", "sort": 10, "status": 1 }
  ]
}
```

### 5.2 新增/修改/删除
*   `POST /`: 新增 (Body: `{"name": "...", "type": 1, "sort": 1}`)
*   `PUT /`: 修改 (Body: `{"id": 11, "name": "...", "sort": 2}`)
*   `DELETE /`: 删除 (Query: `id=11`)

### 5.3 启用禁用分类
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Query Params**: `id=11`
*   **Path Variables**: `status` (1:启用, 0:禁用)

---

## 6. 菜品管理模块 (Dish)
**Base Path**: `/admin/app/dish`

### 6.1 查询/详情/状态
*   `GET /list?categoryId=11`: 查询分类下菜品
*   `GET /{id}`: 菜品详情 (含口味喵)
*   `POST /status/{status}?id=46`: 起售/停售

### 6.2 新增/修改
*   **Method**: `POST` (新增) / `PUT` (修改)
*   **Request Body**:
```json
{
  "id": 46, // 仅修改时必填
  "name": "香辣肉丝",
  "categoryId": 11,
  "price": 28.00,
  "image": "image-key.png",
  "description": "很好吃喵",
  "flavors": [
    { "name": "辣度", "value": "[\"微辣\",\"特辣\"]" }
  ]
}
```

### 6.3 批量删除
*   `DELETE /?ids=46,47`

---

## 7. 套餐管理模块 (Setmeal)
**Base Path**: `/admin/app/setmeal`

### 7.1 查询/详情/状态
*   `GET /list?categoryId=13`: 查询分类下套餐
*   `GET /{id}`: 套餐详情 (含关联菜品)
*   `POST /status/{status}?id=32`: 起售/停售

### 7.2 新增/修改
*   **Request Body**:
```json
{
  "id": 32, // 仅修改时
  "name": "超值单人餐",
  "categoryId": 13,
  "price": 38.00,
  "image": "setmeal-key.png",
  "setmealDishes": [
    { "dishId": 46, "copies": 1 }
  ]
}
```

### 7.3 批量删除
*   `DELETE /?ids=32,33`

---

## 8. 公共接口 (Common)
**Base Path**: `/admin/app/common`

### 8.1 文件上传 (Upload)
*   **URL**: `/upload`
*   **Method**: `POST`
*   **Form Data**: `file` (MultipartFile)
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": "https://oss-url/unique-filename.png"
}
```

---

## 9. 数据统计模块 (Report)
**Base Path**: `/admin/app/report`

### 9.1 查询今日运营数据
*   **URL**: `/businessData`
*   **Method**: `GET`
*   **Description**: 获取店铺今日的概览数据（营业额、有效订单数、完成率等）。
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "turnover": 568.50,           // 营业额
    "validOrderCount": 12,        // 有效订单数
    "orderCompletionRate": 0.92,   // 订单完成率
    "unitPrice": 47.37,           // 平均客单价
    "newUsers": 0                 // 商家端暂不统计用户增长
  }
}
```

### 9.2 营业额趋势统计
*   **URL**: `/turnoverStatistics`
*   **Method**: `GET`
*   **Query Params**: 
    *   `begin`: 开始日期 (yyyy-MM-dd)
    *   `end`: 结束日期 (yyyy-MM-dd)
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "dateList": "2026-01-01,2026-01-02,2026-01-03",
    "turnoverList": "120.5,340.0,568.5"
  }
}
```

### 9.3 订单趋势统计
*   **URL**: `/ordersStatistics`
*   **Method**: `GET`
*   **Query Params**: 
    *   `begin`: 开始日期 (yyyy-MM-dd)
    *   `end`: 结束日期 (yyyy-MM-dd)
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "dateList": "2026-01-01,2026-01-02,2026-01-03",
    "orderCountList": "10,25,15",
    "validOrderCountList": "8,20,12",
    "totalOrderCount": 50,
    "validOrderCount": 40,
    "orderCompletionRate": 0.8
  }
}
```

---
*注：所有业务接口均强制执行 shopId 归属校验，严禁越权操作喵！