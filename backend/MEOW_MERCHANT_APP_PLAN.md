# Meow 外卖商家 App 后端开发计划

## 1. 项目背景与目标
本计划旨在为 "Meow 外卖" 开发商家端 App 的后端接口。
**核心原则**：
1.  **零侵入/低侵入**：严禁删除或修改现有的 Web 端管理接口（位于 `/admin` 下），确保现有 Web 管理后台功能正常运行。
2.  **多商家支持**：所有 App 端接口必须支持 `shopId`（店铺ID），实现数据隔离。
3.  **接口规范**：新接口仍需部署在 `/admin/*` 路径下，但需通过命名或包结构进行逻辑区分。

## 2. 核心架构策略

### 2.1 接口隔离策略
由于要求新接口也在 `/admin/*` 下，为了避免与现有 Web 接口冲突，我们将采用以下命名规范：
- **原有 Web 接口**：保持不变，例如 `/admin/employee/login`。
- **新 App 接口**：
    - **方案 A (推荐)**：在路径中明确区分，例如 `/admin/app/employee/login` 或 `/admin/shop/employee/login`。
    - **方案 B (复用路径)**：如果必须完全复用 `/admin/employee/login`，则需通过 Header (`Client-Type: app`) 或特定参数在 Controller 层或 Gateway 层做分流（**风险较高，建议优先方案 A**）。
    - **当前决策**：暂定新接口 Controller 放置在 `com.sky.controller.admin.app` 包下（需新建），路径前缀统一追加 `/app` 或保持 `/admin` 但方法名/参数不同。

### 2.2 多商家上下文 (Context)
- **ThreadLocal 增强**：现有的 `BaseContext` 可能仅存储了 `currentId` (用户ID)。
- **改造计划**：
    - 扩展 `BaseContext`，增加 `currentShopId` 的 ThreadLocal 存储。
    - 在 App 端的拦截器中，解析 Token 获取 `shopId` 并存入 ThreadLocal。
    - 在 Service 层和 Mapper 层，通过 `BaseContext.getCurrentShopId()` 获取当前店铺 ID，用于 SQL 过滤。

## 3. 数据库改造分析 (Database)
为了支持 `shopId`，需要检查并修改以下核心业务表（需先确认表结构）：
1.  **Employee (员工表)**：需关联 `shop_id`，确定员工属于哪个店铺。
2.  **Category (分类表)**：需关联 `shop_id`。
3.  **Dish (菜品表)**：需关联 `shop_id`。
4.  **Setmeal (套餐表)**：需关联 `shop_id`。
5.  **Orders (订单表)**：需关联 `shop_id`。
6.  **Shop (店铺表)**：如果尚无此表，需要新建，用于存储店铺基本信息。

## 4. 开发任务清单

### Phase 1: 基础设施与数据模型 (Infrastructure & Model)
- [ ] **DB 调研**：检查 `sky.sql`，确认是否已存在 `shop` 相关表及字段。
- [ ] **DB 变更**：编写 SQL 脚本，为核心业务表添加 `shop_id` 字段（如果缺失）。
- [ ] **Entity/DTO/VO 更新**：更新 Java 实体类，增加 `shopId` 属性。
- [ ] **Context 升级**：修改 `BaseContext.java`，添加 `shopId` 支持。

### Phase 2: 登录与拦截器 (Auth & Interceptor)
- [ ] **App 登录接口**：实现 `/admin/app/employee/login`，登录成功后 JWT Token 需包含 `shopId` 信息。
- [ ] **App 拦截器**：新增 `JwtTokenAppAdminInterceptor`，用于解析 App 端的 Token，并将 `empId` 和 `shopId` 存入 `BaseContext`。
- [ ] **WebMvc 配置**：注册新的拦截器，匹配 `/admin/app/**` 路径。

### Phase 3: 核心业务功能迁移 (Business Logic)
*注意：所有查询 SQL 必须显式增加 `shop_id = #{shopId}` 过滤条件。*
- [ ] **店铺状态管理**：营业/打烊接口。
- [ ] **订单管理 (Order)**：接单、拒单、取消、派送、完成。
- [ ] **菜品管理 (Dish)**：查询（仅当前店铺）、修改状态（起售/停售）。
- [ ] **报表统计 (Report)**：基于 `shopId` 的数据统计接口。

## 5. 风险控制
- **回归测试**：每次修改公共模块（如 `BaseContext`）后，必须测试原有 Web 端接口是否正常。
- **数据隔离**：严防 SQL 漏写 `shop_id` 条件，导致商家看到其他店铺的数据。

---
*Created by Nia (妮娅) - 2025-12-31*
