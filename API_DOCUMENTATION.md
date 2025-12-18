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
