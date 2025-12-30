# 后端接口文档 (客户端)

> **版本**: 1.8
> **日期**: 2025-12-30
> **作者**: 妮娅 (Nia)

本文档旨在说明 SkyDelivery (苍穹外卖) 项目客户端所需的主要后端接口。

---

## 1. 店铺相关 (`/client/shop`)

### 1.1 获取店铺营业状态 (全局)

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

### 1.2 查询商家列表 (支持地理位置排序)

- **接口地址**: `GET /client/shop/list/{typeId}`
- **功能描述**: 根据分类ID查询商家列表。如果传入坐标，则按距离由近到远排序喵。
- **请求参数 (路径参数)**:
  - `typeId` (Long): 店铺类型ID (如 4 代表美食)
- **请求参数 (Query)**:
  - `longitude` (Double): 用户当前经度
  - `latitude` (Double): 用户当前纬度
  - `page` (int, 默认1): 分页页码
- **返回数据**: `Result<List<ShopVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 1,
        "name": "苍穹外卖总店",
        "avatar": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/shop_logo_1.png?OSSAccessKeyId=...",
        "score": 5.0,
        "monthlySales": 1200,
        "deliveryPrice": 20.00,
        "shippingFee": 5.00,
        "averageDeliveryTime": 35,
        "distance": "1.2km",
        "status": 1
      }
    ]
  }
  ```
- **‼️ 重要备注**:
  - `distance` 字段在传入坐标时才会有值喵。
  - `avatar` 字段是一个临时的 **阿里云 OSS 预签名 URL**，**有效期为 24 小时**喵。
  - 客户端**不应**对此 URL 进行长期缓存喵。

### 1.3 根据ID查询店铺详情

- **接口地址**: `GET /client/shop/{id}`
- **功能描述**: 获取指定店铺的详细信息，包含评分、公告、配送费等。
- **请求参数**:
  - `id` (路径参数): 店铺ID
- **返回数据**: `Result<ShopVO>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "id": 1,
      "name": "苍穹外卖总店",
      "avatar": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/shop_logo_1.png?OSSAccessKeyId=...",
      "score": 5.0,
      "monthlySales": 1200,
      "deliveryPrice": 20.00,
      "shippingFee": 5.00,
      "averageDeliveryTime": 35,
      "description": "官方直营，品质保证喵！",
      "address": "北京市海淀区中关村",
      "distance": null,
      "status": 1
    }
  }
  ```

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
    - 客户端**严禁**对此 URL 进行长期缓存 (如 `localStorage`)。每次启动应用时建议重新获取，以确保链接始终有效。

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
    - 客户端**不应**对此 URL 进行缓存。

---

## 4. 菜品分类 (`/client/category`)

### 4.1 获取指定店铺的所有分类

- **接口地址**: `GET /client/category/all/{shopId}`
- **功能描述**: 获取指定店铺下所有已启用的菜品和套餐分类，用于该商家的菜单展示。
- **请求参数**:
    - `shopId` (Long, 路径参数): 店铺ID。
- **返回数据**: `Result<List<CategoryVO>>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": [
      {
        "id": 100,
        "type": 1,
        "name": "人气汉堡",
        "sort": 1
      }
    ]
  }
  ```

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
        "image": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/xxx.png?..."
      }
    ]
  }
  ```

---

## 6. 地址簿相关 (`/client/addressBook`)

### 6.1 新增地址

- **接口地址**: `POST /client/addressBook`
- **功能描述**: 新增当前登录用户的地址信息。
- **请求参数 (JSON)**:
  - `consignee`: 收货人
  - `sex`: 性别 (0 女, 1 男)
  - `phone`: 手机号
  - `provinceName`: 省级名称
  - `cityName`: 市级名称
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
      }
    ]
  }
  ```

### 6.3 设置默认地址

- **接口地址**: `PUT /client/addressBook/default/{id}`
- **功能描述**: 设置当前登录用户的默认收货地址喵。
- **返回数据**: `Result<String>`

---

## 7. 订单相关 (`/client/order`)

### 7.1 用户下单

- **接口地址**: `POST /client/order/submit`
- **功能描述**: 用户提交订单，包含地址、支付方式、配送信息以及购物车中的商品明细。
- **请求参数 (JSON)**:
  - `shopId` (Long): 店铺ID (‼️ 必填)
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
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "id": 1001,
      "orderNumber": "17349264000001001",
      "orderAmount": 108.00,
      "orderTime": "2025-12-23 11:30:00"
    }
  }
  ```

### 7.2 订单支付 (支付宝当面付)

- **接口地址**: `PUT /client/order/payment`
- **功能描述**: 为指定的订单号生成支付宝扫码支付的二维码。
- **请求参数 (JSON)**:
  - `orderNumber` (String): 订单号
  - `payMethod` (Integer): 付款方式 (1:微信, 2:支付宝)
- **返回数据**: `Result<OrderPaymentVO>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": {
      "qrCode": "https://qr.alipay.com/..."
    }
  }
  ```

### 7.3 历史订单查询

- **接口地址**: `GET /client/order/historyOrders`
- **功能描述**: 分页查询当前登录用户的历史订单，支持按状态过滤。
- **状态常量说明**:
  - **订单状态 (`status`)**: 1:待付款, 2:待接单, 3:已接单, 4:派送中, 5:已完成, 6:已取消
  - **支付状态 (`payStatus`)**: 0:未支付, 1:已支付, 2:已退款 (REFUND)
- **请求参数 (Query)**:
  - `page` (int): 页码
  - `pageSize` (int): 每页记录数
  - `status` (Integer, 可选): 订单状态
- **返回数据**: `Result<Page<OrderVO>>`
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
          "shopId": 1,
          "shopName": "苍穹外卖总店",
          "status": 5,
          "amount": 108.00,
          "orderTime": "2025-12-25 10:00:00",
          "orderDetailList": [
             { "name": "老坛酸菜鱼", "image": "https://...", "number": 1, "amount": 56.00 }
          ]
        }
      ],
      "size": 10,
      "current": 1,
      "pages": 1
    }
  }
  ```

### 7.4 主动查询支付状态 (支付宝)

- **接口地址**: `GET /client/order/checkPayStatus/{orderNumber}`
- **功能描述**: 主动向支付宝查询订单支付状态。如果查询结果为已支付且本地状态未更新，则会自动触发状态修正喵。
- **请求参数 (路径参数)**:
  - `orderNumber` (String): 订单号
- **返回数据**: `Result<String>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": "TRADE_SUCCESS"
  }
  ```
- **备注**:
    - 返回的 `data` 为支付宝原始交易状态（如 `TRADE_SUCCESS`, `WAIT_BUYER_PAY` 等）。
    - 建议在支付页面等待回调超时或用户点击“我已支付”时调用此接口喵。

### 7.5 查询订单详情 (用户端)

- **接口地址**: `GET /client/order/orderDetail/{id}`
- **功能描述**: 获取指定订单的详细信息，包含菜品明细、店铺信息等。
- **请求参数 (路径参数)**:
  - `id` (Long): 订单ID
- **返回数据**: `Result<OrderVO>`

### 7.6 取消订单 (用户端)

- **接口地址**: `PUT /client/order/cancel`
- **功能描述**: 用户主动取消订单。仅在“待付款”或“待接单”状态下允许取消。如果已付款，将自动触发退款喵。
- **请求参数 (JSON)**:
  - `id` (Long): 订单ID
  - `cancelReason` (String, 可选): 取消原因
- **返回数据**: `Result<String>`
- **响应示例**:
  ```json
  {
    "code": 1,
    "msg": null,
    "data": "ok"
  }
  ```

---

## 9. 用户相关 (`/client/user`)
### 9.1 获取个人信息

- **接口地址**: `GET /client/user/info`
- **功能描述**: 获取当前登录用户的详细个人信息。
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
      "avatar": "https://<your-bucket>.oss-cn-beijing.aliyuncs.com/avatar.png?..."
    }
  }
  ```

### 9.2 退出登录

- **接口地址**: `POST /client/user/logout`
- **功能描述**: 退出当前登录状态，清理服务器端 Token 喵。
- **返回数据**: `Result<String>`

### 9.3 上传头像

- **接口地址**: `POST /client/user/uploadAvatar`
- **功能描述**: 用户上传个人头像并同步更新数据库喵。
- **返回数据**: `Result<String>` (预签名 URL)

### 9.4 修改用户信息

- **接口地址**: `PUT /client/user/edit`
- **功能描述**: 修改当前登录用户的单个人信息。
- **参数**: `code` (字段名: name, sex, profile, idNumber, phone), `value` (新值)
- **返回数据**: `Result<String>`

### 9.5 注销账号

- **接口地址**: `POST /client/user/cancel`
- **功能描述**: 注销当前登录用户的账号喵。
- **‼️ 重要备注**:
  - 此操作不可逆喵！
  - 执行注销后，用户的个人信息和地址簿信息会被脱敏处理。
  - 用户会被强制退出登录，Token 失效喵。

---

## 10. 实时通知 (WebSocket)

### 10.1 建立 WebSocket 连接

- **连接地址**: `ws://{host}:{port}/ws/{userId}`
- **功能描述**: 建立长连接，用于接收系统的实时推送消息（如订单状态变更、支付成功通知等）。
- **参数说明**:
  - `userId`: 当前登录用户的 ID。**注意：商家端连接时，路径最后的 {userId} 需携带 `S_` 前缀（如 `ws://.../ws/S_1`）喵。**

### 10.2 消息协议结构 (MessageDTO)

系统推送及私聊消息将统一采用以下 JSON 结构：

| 字段名         | 类型    | 说明                                            |
|:------------|:------|:----------------------------------------------|
| `type`      | Integer | 消息类型 (1:系统通知, 2:订单状态, 3:私聊消息)             |
| `msgId`     | String  | 消息唯一ID (UUID)                                 |
| `senderId`  | Long    | 发送者ID (0 代表系统)                               |
| `senderRole`| Integer | **发送者身份** (0:用户, 1:商家, 2:系统)               |
| `receiverId`| Long    | 接收者ID                                        |
| `receiverRole`| Integer| **接收者身份** (0:用户, 1:商家)                      |
| `senderName`| String  | 发送者显示名称                                     |
| `senderAvatar`| String| 发送者头像 (带签名的有效URL)                        |
| `content`   | String  | 消息正文                                        |
| `timestamp` | Long    | 发送时间戳                                       |
| `orderId`   | Long    | 关联的订单ID (可选)                                |

### 10.3 消息类型定义

- **1 (系统通知)**: 支付成功通知、退款通知。
- **2 (订单状态)**: 商家接单、派送中、订单送达（由系统名义发出）。
- **3 (私聊消息)**: 商家私信（如送达时的温馨提示）、用户与商家对话。

### 10.4 特殊业务逻辑说明 (重要 ‼️)

#### 10.4.1 订单送达通知
当订单送达时，后端会同时推送 **两条** 消息：
1. **Type 2**: 系统发出的状态通知（"订单已送达"）。
2. **Type 3**: 商家发出的私聊消息（"订单已送达，祝您用餐愉快喵"），此消息会存入用户的私聊会话列表中。

### 10.5 消息示例

#### 10.5.1 订单完成时的双重通知示例

**消息 1 (系统通知 - Type 2):**
```json
{
  "type": 2,
  "msgId": "uuid-1",
  "senderId": 0,
  "senderRole": 2,
  "senderName": "Meow外卖",
  "content": "订单已送达，祝您用餐愉快喵",
  "orderId": 202512290001
}
```

**消息 2 (商家私聊 - Type 3):**
```json
{
  "type": 3,
  "msgId": "uuid-2",
  "senderId": 1,
  "senderRole": 1,
  "senderName": "肯德基宅急送",
  "senderAvatar": "https://oss.../kfc.png?...",
  "content": "订单已送达，祝您用餐愉快喵",
  "orderId": 202512290001
}
```
