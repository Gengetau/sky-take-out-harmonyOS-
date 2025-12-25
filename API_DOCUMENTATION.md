# 后端接口文档 (客户端)

> **版本**: 1.2
> **日期**: 2025-12-25
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
    - **‼️ 重要备注**:
        - `image` 字段是一个临时的 **阿里云 OSS 预签名 URL**，**有效期为 2 小时**。
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

### 6.3 查询默认地址

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

### 6.4 设置默认地址

- **接口地址**: `PUT /client/addressBook/default/{id}`
- **功能描述**: 设置当前登录用户的默认收货地址。
- **请求参数**:
  - `id` (路径参数): 地址ID
- **请求示例**: 无 (参数在URL中)
- **返回数据**: `Result<String>`
- **备注**:
    - 此操作具有排他性：设置某个地址为默认地址后，该用户原有的其他默认地址会自动取消默认状态喵。
    - 后端会自动同步更新 Redis 缓存，保证数据实时性喵。

### 6.5 根据ID查询地址

- **接口地址**: `GET /client/addressBook/{id}`
- **功能描述**: 根据地址ID获取详细的地址信息，用于编辑页面的数据回显喵。
- **请求参数**:
  - `id` (路径参数): 地址ID
- **返回数据**: `Result<AddressBook>`

### 6.6 修改地址

- **接口地址**: `PUT /client/addressBook`
- **功能描述**: 根据地址ID修改详细的地址信息喵。
- **请求参数 (JSON)**:
  - `id`: 地址ID (必填)
  - `consignee`: 收货人
  - `sex`: 性别 (0 女, 1 男)
  - `phone`: 手机号
  - `provinceName`: 省级名称
  - `cityName`: 市级名称
  - `districtName`: 区级名称
  - `detail`: 详细地址
  - `label`: 标签
- **返回数据**: `Result<String>`
- **备注**:
    - 修改操作后，后端会自动清理默认地址缓存喵。

### 6.7 根据ID删除地址

- **接口地址**: `DELETE /client/addressBook`
- **功能描述**: 根据地址ID删除该地址信息喵。
- **请求参数 (Query)**:
  - `id`: 地址ID
- **请求示例**: `/client/addressBook?id=1`
- **返回数据**: `Result<String>`
- **备注**:
    - 删除操作后，后端会自动清理默认地址缓存喵。

---

## 7. 订单相关 (`/client/order`)

### 7.1 用户下单

- **接口地址**: `POST /client/order/submit`
- **功能描述**: 用户提交订单，包含地址、支付方式、配送信息以及购物车中的商品明细。
- **请求参数 (JSON)**:
  - `addressBookId` (Long): 地址簿id
  - `payMethod` (Integer): 付款方式 (1:微信, 2:支付宝)
  - `remark` (String): 备注
  - `estimatedDeliveryTime` (String): 预计送达时间 (格式: yyyy-MM-dd HH:mm:ss)
  - `deliveryStatus` (Integer): 配送状态 (1:立即送出, 0:选择具体时间)
  - `tablewareNumber` (Integer): 餐具数量
  - `tablewareStatus` (Integer): 餐具数量状态 (1:按餐量提供, 0:选择具体数量)
  - `packAmount` (Integer): 打包费
  - `amount` (BigDecimal): 订单总金额
  - `cartItems` (List<CartItem>): 购物车明细列表
    - `dishId` (Long): 菜品id (如果是套餐则为null)
    - `setmealId` (Long): 套餐id (如果是菜品则为null)
    - `dishFlavor` (String): 口味 (如: "不辣")
    - `number` (Integer): 数量
    - `amount` (BigDecimal): 单价或总价
    - `name` (String): 商品名称
    - `image` (String): 商品图片
- **返回数据**: `Result<OrderSubmitVO>`

### 7.2 订单支付 (支付宝当面付)

- **接口地址**: `PUT /client/order/payment`
- **功能描述**: 为指定的订单号生成支付宝扫码支付的二维码。
- **请求参数 (JSON)**:
  - `orderNumber` (String): 订单号
  - `payMethod` (Integer): 付款方式 (1:微信, 2:支付宝)
- **返回数据**: `Result<OrderPaymentVO>`

### 7.3 历史订单查询

- **接口地址**: `GET /client/order/historyOrders`
- **功能描述**: 分页查询当前登录用户的历史订单，支持按状态过滤喵。
- **请求参数 (Query)**:
  - `page` (int): 页码
  - `pageSize` (int): 每页记录数
  - `status` (Integer, 可选): 订单状态 (1:待付款, 2:待接单, 3:已接单, 4:派送中, 5:已完成, 6:已取消)
- **返回数据**: `Result<PageResult<OrderVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "total": 10,
      "records": [
        {
          "id": 100,
          "number": "1734926400000",
          "status": 5,
          "amount": 108.00,
          "orderTime": "2025-12-25 10:00:00",
          "orderDetailList": [
             { "name": "老坛酸菜鱼", "number": 1, "amount": 56.00 },
             { "name": "米饭", "number": 2, "amount": 4.00 }
          ]
        }
      ]
    }
  }
  ```
- **备注**:
  - `records` 中包含了订单详情 `orderDetailList` 喵。
  - 订单按时间倒序排列喵。

---

## 9. 用户相关 (`/client/user`)

### 9.1 获取个人信息

- **接口地址**: `GET /client/user/info`
- **功能描述**: 获取当前登录用户的详细个人信息。
- **请求参数**: 无 (通过请求头中的 Token 识别用户)
- **返回数据**: `Result<User>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "id": 1,
      "openid": "wx123456",
      "name": "妮娅的主人",
      "phone": "13812345678",
      "sex": "1",
      "avatar": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/avatar.png?OSSAccessKeyId=...",
      "createTime": "2025-12-23 15:00:00"
    }
  }
  ```

### 9.2 退出登录

- **接口地址**: `POST /client/user/logout`
- **功能描述**: 退出当前登录状态。
- **返回数据**: `Result<String>`

### 9.3 上传头像

- **接口地址**: `POST /client/user/uploadAvatar`
- **功能描述**: 用户上传个人头像并更新喵。
- **请求参数 (FormData)**: `file`
- **返回数据**: `Result<String>`

### 9.4 修改用户信息

- **接口地址**: `PUT /client/user/edit`
- **功能描述**: 修改当前登录用户的单 অপমান信息喵。
- **请求参数 (JSON)**: `code`, `value`
- **返回数据**: `Result<String>`

### 9.5 注销账号

- **接口地址**: `POST /client/user/cancel`
- **功能描述**: 注销当前登录用户的账号。
- **请求参数**: 无
- **返回数据**: `Result<String>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": "账号已注销，江湖再见喵！"
  }
  ```
- **‼️ 重要备注**:
  - 此操作不可逆喵！
  - 执行注销后，用户的个人信息和地址簿信息会被脱敏处理。
  - 用户会被强制退出登录，Token 失效喵。

---

## 10. 实时通知 (WebSocket)

### 8.1 建立 WebSocket 连接

- **连接地址**: `ws://{host}:{port}/ws/{userId}`
- **功能描述**: 用于接收后端的实时推送消息（如支付成功通知）。
- **参数说明**:
    - `userId` (Long): 当前登录用户的ID。

### 8.2 消息格式 (后端推送)

当支付成功或有其他状态变更时，后端会主动推送 JSON 格式的消息：

- **消息示例**:
  ```json
  {
    "type": 1,
    "orderId": 1001,
    "content": "订单支付成功"
  }
  ```
