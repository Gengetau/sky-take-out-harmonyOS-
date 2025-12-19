# 后端接口文档 (客户端)

> **版本**: 1.0
> **日期**: 2025-12-18
> **作者**: 妮娅 (Nia)

本文档旨在说明 SkyDelivery (苍穹外卖) 项目客户端所需的主要后端接口。

---

## 1. 店铺相关 (`/client/shop`)

### 1.1 获取店铺营业状态

- **接口地址**: `GET /client/shop/status`
- **功能描述**: 用于获取店铺当前的营业状态，以便在客户端展示“营业中”或“休息中”。
- **请求参数**: 无
- **返回数据**: `Result<Integer>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": 1
  }
  ```
- **备注**:
    - `data` 值为 `1` 表示 **营业中**。
    - `data` 值为 `0` 表示 **休息中** (已打烊)。
    - 如果 Redis 未设置状态，接口会默认返回 `0`。

---

## 2. 店铺类型 (`/client/type`)

### 2.1 获取店铺类型列表

- **接口地址**: `GET /client/type/list`
- **功能描述**: 获取所有的店铺类型，用于首页的分类展示。
- **请求参数**: 无
- **返回数据**: `Result<List<ShopTypeVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 1,
        "name": "美食",
        "icon": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/fig1.png?OSSAccessKeyId=...",
        "sort": 1
      },
      {
        "id": 2,
        "name": "甜点饮品",
        "icon": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/fig2.png?OSSAccessKeyId=...",
        "sort": 2
      }
    ]
  }
  ```
- **‼️ 重要备注**:
    - `icon` 字段是一个临时的 **阿里云 OSS 预签名 URL**，**有效期为 24 小时**。
    - 客户端**严禁**对此 URL 进行长期缓存 (如 `localStorage`)。每次启动应用时建议重新获取，以确保链接始终有效。后端已做缓存优化，性能无忧。

---

## 3. 菜品相关 (`/client/dish`)

### 3.1 根据分类查询菜品

- **接口地址**: `GET /client/dish/{categoryId}`
- **功能描述**: 根据指定的分类ID，获取该分类下的所有启用状态的菜品列表。
- **请求参数**:
    - `categoryId` (Integer, 路径参数): 分类ID。
- **返回数据**: `Result<List<DishVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 51,
        "name": "老坛酸菜鱼",
        "categoryId": 20,
        "price": 56.00,
        "image": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/xxx.png?OSSAccessKeyId=...",
        "description": "原料：汤，草鱼，酸菜",
        "status": 1,
        "flavors": [
          { "id": 88, "dishId": 51, "name": "忌口", "value": "[\"不要葱\",\"不要蒜\"]" },
          { "id": 89, "dishId": 51, "name": "辣度", "value": "[\"不辣\",\"微辣\"]" }
        ]
      }
    ]
  }
  ```
- **‼️ 重要备注**:
    - `image` 字段是一个临时的 **阿里云 OSS 预签名 URL**，**有效期为 2 小时**。
    - 客户端**不应**对此 URL 进行缓存。每次请求此接口都会返回最新的有效链接。

---

## 4. 菜品分类 (`/client/category`)

### 4.1 获取所有菜品分类

- **接口地址**: `GET /client/category/all`
- **功能描述**: 获取所有已启用的菜品和套餐分类，用于分类展示。
- **请求参数**: 无
- **返回数据**: `Result<List<CategoryVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 11,
        "type": 1,
        "name": "酒水饮料",
        "sort": 10
      },
      {
        "id": 12,
        "type": 1,
        "name": "传统主食",
        "sort": 9
      }
    ]
  }
  ```
- **备注**:
    - 此接口数据在后端有24小时缓存，性能较高。

---

## 5. 套餐相关 (`/client/setmeal`)

### 5.1 根据分类ID查询套餐

- **接口地址**: `GET /client/setmeal/{categoryId}`
- **功能描述**: 获取指定分类ID下的所有启用状态的套餐列表。
- **请求参数**:
    - `categoryId` (Long, 路径参数): 分类ID。
- **返回数据**: `Result<List<SetMealVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 32,
        "categoryId": 13,
        "name": "健康搭配套餐A",
        "price": 39.90,
        "status": 1,
        "description": "包含米饭和清炒小油菜，健康美味喵！",
        "image": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/setmeal_healthy_a.png?OSSAccessKeyId=..."
      }
    ]
  }
  ```
    - **‼️ 重要备注**:                                                                                           │
        - `image` 字段是一个临时的 **阿里云 OSS 预签名 URL**，**有效期为 2 小时**。 │
        - 此接口在后端有 60 分钟缓存，客户端**不应**对返回的 `image` URL 进行长期缓存。

--- 

## 6. 地址簿相关 (`/client/addressBook`)

### 6.1 新增地址

- **接口地址**: `POST /client/addressBook`
- **功能描述**: 新增当前登录用户的地址信息。
- **请求参数 (JSON)**:
  - `consignee`: 收货人
  - `sex`: 性别 (0 女, 1 男)
  - `phone`: 手机号
  - `provinceCode`: 省级区划编号
  - `provinceName`: 省级名称
  - `cityCode`: 市级区划编号
  - `cityName`: 市级名称
  - `districtCode`: 区级区划编号
  - `districtName`: 区级名称
  - `detail`: 详细地址
  - `label`: 标签 (家, 公司, 学校)
- **请求示例**:
  ```json
  {
    "consignee": "王小明",
    "sex": "1",
    "phone": "13800138000",
    "provinceName": "广东省",
    "cityName": "广州市",
    "districtName": "天河区",
    "detail": "珠江新城花城大道1号",
    "label": "家"
  }
  ```
- **返回数据**: `Result<String>`

### 6.2 查询当前登录用户的所有地址信息

- **接口地址**: `GET /client/addressBook/list`
- **功能描述**: 查询当前登录用户的所有收货地址信息。
- **请求参数**: 无
- **返回数据**: `Result<List<AddressBook>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 1,
        "userId": 1,
        "consignee": "张三",
        "sex": "1",
        "phone": "13812312312",
        "provinceName": "北京市",
        "cityName": "北京市",
        "districtName": "海淀区",
        "detail": "中关村大街1号",
        "label": "公司",
        "isDefault": 1
      },
      {
        "id": 2,
        "userId": 1,
        "consignee": "李四",
        "sex": "0",
        "phone": "13900000000",
        "provinceName": "北京市",
        "cityName": "北京市",
        "districtName": "朝阳区",
        "detail": "建国路88号",
        "label": "家",
        "isDefault": 0
      }
    ]
  }
  ```

### 6.2 查询默认地址

- **接口地址**: `GET /client/addressBook/default`
- **功能描述**: 查询当前登录用户的默认收货地址。
- **请求参数**: 无
- **返回数据**: `Result<AddressBook>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "id": 1,
      "userId": 1,
      "consignee": "张三",
      "sex": "1",
      "phone": "13812312312",
      "provinceName": "北京市",
      "cityName": "北京市",
      "districtName": "海淀区",
      "detail": "中关村大街1号",
      "label": "公司",
      "isDefault": 1
    }
  }
  ```
- **备注**:
    - 如果当前用户没有设置默认地址，`data` 将为 `null`，且返回状态码为 `0` (Error) 喵。
