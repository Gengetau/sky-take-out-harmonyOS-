# 📩 SkyDelivery 消息中心 (Message Center) 开发规划书

> **版本**: 1.0
> **状态**: 规划中
> **作者**: 妮娅 (Nia)
> **日期**: 2025-12-26

## 1. 项目概述
本模块旨在通过 WebSocket 技术实现实时的系统消息推送与双向沟通交流功能。为了保证用户隐私及离线查看体验，聊天记录将采用 HarmonyOS 本地 RDB (关系型数据库) 进行持久化存储。

---

## 2. 技术架构设计

### 2.1 核心组件
- **WebSocketService**: 负责与后端的长连接维护、心跳检测、消息发送与接收喵。
- **MessageRdb**: 基于 SQLite 的本地数据库，存储所有历史会话和聊天内容，确保隐私喵。
- **MessageManager**: 业务中转层，负责将 WS 接收到的原始消息解析、分类并存入 RDB，同时通知 UI 更新喵。

### 2.2 数据流向
1. **下行消息**: 后端推送 -> `WebSocketService` -> `MessageManager` -> 写入 `MessageRdb` -> 发布事件 -> `MessagePage` 局部刷新。
2. **上行消息**: `ChatPage` 输入 -> `MessageManager` -> 调用 `WebSocketService.send()` -> 异步写入 `MessageRdb` 确认。

---

## 3. 通讯协议定义 (JSON)

### 3.1 基础消息格式
```json
{
  "type": 1,          // 消息类型: 1-系统通知, 2-订单状态, 3-私聊消息
  "msgId": "uuid",    // 消息唯一标识
  "senderId": 0,      // 发送者ID (0代表系统)
  "senderName": "",   // 发送者昵称
  "senderAvatar": "", // 发送者头像
  "content": "",      // 消息正文 (文本或JSON字符串)
  "timestamp": 0,     // 发送时间戳
  "orderId": 0        // 关联订单ID (可选)
}
```

---

## 4. 数据库设计 (MessageRdb)

### 4.1 会话表 (`tb_session`)
用于展示消息中心的列表项。
- `session_id`: 字符串 (唯一标识，如 "chat_user_101")
- `title`: 商家名或"系统通知"
- `avatar`: 头像
- `last_msg`: 最后一条消息内容
- `last_time`: 最后一条消息时间
- `unread_count`: 未读数喵

### 4.2 消息明细表 (`tb_message`)
存储具体的对话内容。
- `id`: 自增主键
- `session_id`: 关联会话
- `sender_id`: 发送者
- `content`: 内容
- `msg_type`: 消息种类 (text/image/voice)
- `create_time`: 时间戳喵

---

## 5. UI/UX 功能拆解

### 5.1 消息中心列表页 (`MessagePage`)
- **功能**: 展示会话列表，支持按时间倒序排列。
- **细节**: 显示未读红点、最后一条消息预览、侧滑删除会话喵。

### 5.2 聊天详情页 (`ChatPage`)
- **功能**: 实现类微信的交互体验。
- **细节**: 
  - 聊天气泡（左侧接收，右侧发送）。
  - 时间分割线（自动判断间隔）。
  - 底部输入栏（文本、表情、图片扩展 - 视情况实现）。
  - 订单卡片快捷发送功能（可选）喵。

---

## 6. 开发计划阶段

- **Phase 1 (基础建设)**: 升级 `WebSocketService` 协议，创建并测试 `MessageRdb`。
- **Phase 2 (会话管理)**: 实现 `MessageManager` 的逻辑，完成收到消息自动入库并弹窗提醒。
- **Phase 3 (UI 开发)**: 完成 `MessagePage` 会话列表开发。
- **Phase 4 (聊天体验)**: 完成 `ChatPage` 核心交互开发。
- **Phase 5 (联调优化)**: 压力测试、断线重连优化及 UI 细节打磨喵。

---

> 🚀 **妮娅注**: Master，让我们一步步把 SkyDelivery 变得更有温度吧！加油喵！