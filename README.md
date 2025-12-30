# SkyDelivery - 鸿蒙分布式外卖全栈平台 (Meow 外卖) 🐱🚀

[![HarmonyOS](https://img.shields.io/badge/OS-HarmonyOS%20NEXT-blue.svg)](https://developer.huawei.com/)
[![Spring Boot](https://img.shields.io/badge/Backend-Spring%20Boot%202.7-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)

> **全栈闭环实践**：基于 HarmonyOS NEXT (前端) + Spring Boot (后端) 开发的现代化、全场景外卖点餐系统。

---

## 🧭 导航菜单 (快速切换)

| [📱 鸿蒙客户端 (ArkTS)](#-客户端---harmonyos-next) | [⚙️ 后端服务 (Spring Boot)](#-后端服务---spring-boot) | [🚀 快速部署](#-快速开始) |
|:------------------------------------------:|:---------------------------------------------:|:-----------------:|

---

## 📖 项目简介

**SkyDelivery** (Meow外卖) 是一个完整的全栈外卖解决方案。

- **前端**：深入实践鸿蒙 **元服务** 与 **分布式** 理念，提供沉浸式点餐、地图选点及实时聊天体验。
- **后端**：采用多商家平台架构，基于 **WebSocket** 构建高性能消息中枢，集成 **支付宝** 支付与自动化退款链路。

---

## 📱 客户端 - HarmonyOS NEXT

### ✨ 核心特性

* **🛍️ 多商家联动**：动态分类、基于 GeoHash 的附近商家智能排序。
* **📍 智能地址**：集成 `LocationKit` 自动定位与 `MapKit` 手动选点，支持逆地理编码。
* **💬 实时消息中心**：全双工 WebSocket 通信 + 本地 RDB 关系型数据库持久化存储聊天记录。
* **📦 订单全生命周期**：从下单、模拟支付到 WebSocket 实时驱动的状态追踪。
* **🎨 原生视觉**：基于 ArkUI 的响应式布局与高性能动画。

### 🏗️ 客户端技术栈

* **语言**: ArkTS (TypeScript Extended)
* **框架**: ArkUI (Declarative)
* **Kit**: LocationKit, MapKit, NetworkKit, ArkData, NotificationKit (规划中)

---

## ⚙️ 后端服务 - Spring Boot

### ✨ 核心特性

* **🏢 多商家平台架构**：支持数据层级的商家隔离，具备灵活的店铺状态管理与 GEO 地理位置查询能力。
* **📨 实时消息中枢 (Message Center)**：
    * **智能分发**：自研 `MessageDispatcher`，支持“用户/商家/系统”多角色身份识别。
    * **自动签名**：集成阿里云 OSS，通过 WebSocket 推送的头像均由后端实时生成带签名的安全 URL。
    * **双重通知**：支持系统状态通知与商家温馨私聊的并发推送。
* **💳 支付与售后闭环**：
    * **支付宝集成**：对接支付宝当面付，支持预下单、主动查单及状态修正。
    * **自动化退款**：用户取消或商家拒单时，系统自动识别支付状态并执行**原路全额退款**。
* **稳定性保障**：完善的拦截器链路（JWT 验证、WebSocket 握手校验）及全链路日志监控体系。

### 🏗️ 后端技术栈

* **核心框架**: Spring Boot 2.7+ / Spring MVC
* **持久层**: MyBatis Plus / MySQL 8.0
* **中间件**: Redis (缓存 + GEO 排序)
* **通信**: Spring WebSocket (基于 Handler 模式)
* **第三方服务**: 阿里云 OSS (预签名存储), 支付宝 SDK (支付/退款)
* **工具**: Hutool (数据处理), Lombok, FastJSON

---

## 📂 目录结构预览

<details>
<summary><b>点击展开：项目目录树</b></summary>

```text
SkyDelivery/
├── SkyDelivery-Frontend/ (HarmonyOS)
│   └── entry/src/main/ets/
│       ├── manager/        # 消息中心逻辑
│       ├── pages/          # UI 页面
│       └── service/        # 业务逻辑桥接
└── SkyDelivery-Backend/ (Spring Boot)
    ├── sky-server/         # 核心业务模块
    │   ├── handler/        # WebSocket 处理器
    │   ├── interceptor/    # 握手/权限拦截器
    │   └── websocket/      # 消息分发中枢
    ├── sky-pojo/           # DTO/VO/Entity
    └── sky-common/         # 常量与工具类
```

</details>

---

## 🚀 快速开始

### 1. 启动后端

1. 修改 `sky-server/src/main/resources/application.yml` 中的 MySQL、Redis、OSS 及 支付宝 配置。
2. 运行 `SkyApplication`。默认端口 `8080`。

### 2. 启动前端

1. 使用 DevEco Studio 打开前端工程。
2. 在 `Constants.ets` 中修改 `BASE_URL` 为您的服务器 IP。
3. 点击 **Run 'entry'**。

---

## 🤝 贡献与反馈

欢迎提交 Issue 或 Pull Request！如果您喜欢这个项目，请给它一个 ⭐️ Star 吧！

**Maintainer**: Gengetsu && Nia (妮娅) 🐱
**License**: Apache-2.0