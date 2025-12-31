# 📋 Meow外卖商家版开发计划书 (SkyDelivery_Admin)

## 1. 项目概述 🐱
**目标**：构建一个高效、美观的 HarmonyOS 商家端应用，帮助餐饮商家管理订单、菜品和店铺状态。
**技术栈**：ArkTS, ArkUI (API 11+), RCP Network, AppStorage/LocalStorage.

## 2. 资源复用策略 ♻️
为了提高开发效率，我们将从用户端 (`SkyDelivery`) 复用以下核心资产：
*   **网络层**: `HttpUtil.ets` (RCP 封装, 含 Token 拦截器).
*   **基础模型**: `ResultModel.ets` (统一后端响应结构).
*   **UI 风格**: 品牌色 (`color.json`), 基础字符串资源.

## 3. 开发路线图 🗺️

### ✅ Phase 0: 项目初始化 (已完成)
- [x] 创建工程结构 (`model`, `view`, `service`, `manager`, `common`).
- [x] 配置品牌色 (`color.json`).

### 🏗️ Phase 1: 基础设施搭建 (当前重点)
- [ ] **移植网络工具**: 复制 `HttpUtil.ets` 到商家端，并配置 Base URL。
- [ ] **通用模型**: 复制 `ResultModel.ets`。
- [ ] **本地存储**: 实现 `PreferencesUtil` 用于存储 Token 和商家信息。

### 🔐 Phase 2: 商家登录与认证
- [ ] **数据模型**: 定义 `EmployeeLoginDTO` (账号密码登录) 和 `EmployeeLoginVO`。
- [ ] **登录页面**: 实现 `Login.ets`，包含账号密码输入框和登录按钮。
- [ ] **认证服务**: 实现 `AuthService.ets`，对接 `/admin/employee/login` 接口。

### 🥡 Phase 3: 订单管理工作台 (核心功能)
- [ ] **主页框架**: 实现 `MainTabs`，包含“待处理”、“进行中”、“已完成”等状态。
- [ ] **订单模型**: 定义 `Orders` 实体类 (复用部分用户端逻辑，但侧重商家视角)。
- [ ] **接单/拒单**: 实现接单、拒单、取消订单的交互逻辑。

### 🥗 Phase 4: 菜品与店铺管理
- [ ] **菜品管理**: 列表展示、新建菜品、修改库存/价格、上下架状态。
- [ ] **套餐管理**: 套餐的增删改查。
- [ ] **店铺设置**: 营业状态切换 (营业中/打烊)，店铺基础信息修改。

### 📊 Phase 5: 数据概览 (可选/后期)
- [ ] **经营报表**: 当日营业额、订单量统计图表。

---

## 4. 关键接口预测 (用于 Mock/开发)
*   `POST /admin/employee/login`: 员工登录
*   `GET /admin/shop/status`: 获取营业状态
*   `PUT /admin/shop/status/{status}`: 设置营业状态
*   `GET /admin/order/conditionSearch`: 订单搜索/列表
*   `PUT /admin/order/confirm`: 接单
*   `PUT /admin/order/rejection`: 拒单

---
**妮娅 (Nia) 备注**: 开发过程中，遇到任何 API 不确定的地方，我会先做好 Mock 数据，保证 UI 开发不阻塞喵！🐾
