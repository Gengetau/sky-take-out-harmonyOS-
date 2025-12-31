# Meow 外卖商家端 App API 接口规范

*Version: 1.4.0*
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
  "msg": null,
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
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null,
  "data": null
}
```

---

## 3. 店铺管理模块 (Shop)
**Base Path**: `/admin/app/shop`

### 3.1 获取店铺详情
*   **URL**: `/`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "id": 1,
    "name": "苍穹外卖总店",
    "avatar": "https://oss-url/logo.png",
    "phone": "400-123-4567",
    "address": "北京市海淀区中关村",
    "score": 5.0,
    "status": 1,
    "description": "官方直营，品质保证"
  }
}
```

### 3.2 获取营业状态
*   **URL**: `/status`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": 1  // 1: 营业中, 0: 打烊中
}
```

### 3.3 设置营业状态
*   **URL**: `/{status}`
*   **Method**: `PUT`
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null,
  "data": null
}
```

---

## 4. 订单管理模块 (Order)
**Base Path**: `/admin/app/order`

### 4.1 分页查询订单列表
*   **URL**: `/conditionSearch`
*   **Method**: `GET`
*   **Query Params**: `page`, `pageSize`, `status`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "total": 50,
    "records": [
      {
        "id": 1001,
        "number": "202312310001",
        "status": 2,
        "amount": 88.50,
        "orderTime": "2025-12-31 10:00:00",
        "payStatus": 1,
        "userName": "张三",
        "phone": "13800000000",
        "address": "北京市海淀区...",
        "consignee": "张先生",
        "orderDetailList": [
          {
            "name": "宫保鸡丁",
            "number": 1,
            "amount": 38.00
          }
        ]
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
    "toBeConfirmed": 5,      // 待接单
    "confirmed": 2,          // 待派送
    "deliveryInProgress": 1  // 派送中
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
    "orderTime": "2025-12-31 10:00:00",
    "checkoutTime": "2025-12-31 10:05:00",
    "payMethod": 1, // 1微信 2支付宝
    "payStatus": 1, // 1已支付
    "userName": "张三",
    "phone": "13800000000",
    "address": "北京市海淀区...",
    "consignee": "张先生",
    "sex": "1", // 1先生 2女士
    "remark": "少放辣",
    "packAmount": 2.00,
    "tablewareNumber": 2,
    "shopId": 1,
    "orderDetailList": [
      {
        "id": 501,
        "name": "宫保鸡丁",
        "image": "https://oss-url/food.png",
        "orderId": 1001,
        "dishId": 10,
        "dishFlavor": "微辣",
        "number": 1,
        "amount": 38.00
      }
    ]
  }
}
```

### 4.4 接单 (Confirm)
*   **URL**: `/confirm`
*   **Method**: `PUT`
*   **Request Body**: `{"id": 1001}`
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

### 4.5 拒单 (Reject)
*   **URL**: `/rejection`
*   **Method**: `PUT`
*   **Request Body**: `{"id": 1001, "rejectionReason": "食材不足"}`
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

### 4.6 派送订单 (Delivery)
*   **URL**: `/delivery/{id}`
*   **Method**: `PUT`
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

### 4.7 完成订单 (Complete)
*   **URL**: `/complete/{id}`
*   **Method**: `PUT`
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

---

## 5. 分类管理模块 (Category)
**Base Path**: `/admin/app/category`

### 5.1 根据类型查询分类
*   **URL**: `/list`
*   **Method**: `GET`
*   **Query Parameters**:
    *   `type`: 1 (菜品分类) 或 2 (套餐分类)
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
      "status": 1,
      "createTime": "2022-06-09 22:09:18",
      "updateTime": "2022-06-09 22:09:18",
      "createUser": 1,
      "updateUser": 1
    },
    {
      "id": 12,
      "type": 1,
      "name": "传统主食",
      "sort": 11,
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
      "image": "https://oss-url/drink.png",
      "description": "凉茶",
      "status": 1,
      "categoryName": "酒水饮料",
      "flavors": []
    },
    {
      "id": 47,
      "name": "北冰洋",
      "categoryId": 11,
      "price": 5.00,
      "image": "https://oss-url/drink2.png",
      "status": 0,
      "categoryName": "酒水饮料"
    }
  ]
}
```

### 6.2 根据ID查询菜品详情
*   **URL**: `/{id}`
*   **Method**: `GET`
*   **Response (Success)**:
```json
{
  "code": 1,
  "data": {
    "id": 46,
    "name": "招牌酸菜鱼",
    "categoryId": 12,
    "price": 88.00,
    "image": "https://oss-url/fish.png",
    "description": "酸辣爽口",
    "status": 1,
    "categoryName": "热销菜品",
    "flavors": [
      {
        "id": 1,
        "dishId": 46,
        "name": "辣度",
        "value": "[\"微辣\",\"中辣\",\"特辣\"]"
      },
      {
        "id": 2,
        "dishId": 46,
        "name": "忌口",
        "value": "[\"不要葱\",\"不要蒜\"]"
      }
    ]
  }
}
```

### 6.3 菜品起售/停售
*   **URL**: `/status/{status}`
*   **Method**: `POST`
*   **Path Variables**: `status` (1起售, 0停售)
*   **Query Parameters**: `id` (菜品ID)
*   **Response (Success)**:
```json
{
  "code": 1,
  "msg": null
}
```

---
*End of Document*
