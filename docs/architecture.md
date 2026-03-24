# 展会翻译 App - 轻量 Architecture

## 更新记录
- 更新时间：2026-03-21（第三次）
- 修改原因：新增需求审核状态（review_status）、Notification 实体（4.13）、Notification 模块（3.8）、demandReviewStatus 状态机（5.6）。
- 更新时间：2026-03-21（第二次）
- 修改原因：图片发送开放给双方（雇主+翻译员），DEMAND_CARD 发送新增需求状态校验（CLOSED/CANCELLED 拒绝）。
- 更新时间：2026-03-21
- 修改原因：Message 实体新增 image_url 字段（4.12），msg_type 新增 IMAGE，支持聊天图片消息。
- 更新时间：2026-03-20（第二次）
- 修改原因：新增 Chat 模块（3.7）、Conversation 实体（4.11）、Message 实体（4.12），支持最小聊天系统。
- 更新时间：2026-03-20
- 修改原因：TranslatorProfile 新增 rest_weekdays 字段（4.3），档期管理从后续阶段提升为已实现。
- 更新时间：2026-03-19（第二次）
- 修改原因：新增 Review 实体（4.10），支持雇主在订单完成后对翻译员评价，评价自动更新翻译员 rating_summary。
- 更新时间：2026-03-19
- 修改原因：在保留 Phase 4 / Phase 5 主链路结构说明的基础上，合并”最小 MVP 验证闭环”新增内容，包括开发环境模拟审核通过、我的需求追踪与需求到订单衔接。

## 1. 架构目标
本架构用于约束 AI 开发过程，避免字段漂移、状态混乱、接口不一致。

## 2. 技术建议
### 2.1 前端
- App 形态：iOS 风格移动端前端
- 推荐：React Native + Expo
- 状态管理：Zustand 或 Redux Toolkit
- 数据请求：React Query
- 表单：React Hook Form

说明：
- 当前已有实现可继续沿用 Flutter，只要接口合同、枚举与文档保持一致。
- 本文档约束业务结构与状态，不强制限制具体前端框架。

### 2.2 后端
- 推荐：Node.js + NestJS / Express
- API 风格：REST
- 鉴权：JWT
- 文件上传：对象存储或本地占位

说明：
- 当前已有实现可继续沿用 Python / Flask，只要接口风格、状态机与文档保持一致。

### 2.3 数据库
- 推荐：PostgreSQL
- 原因：
  - 角色关系明确
  - 订单 / 报价 / 档期有强关联
  - 筛选维度多
  - 状态机清晰，适合关系型建模

## 3. 模块划分
### 3.1 Auth 模块
负责：
- 登录 / 注册
- 角色选择
- Token 鉴权
- 当前用户信息

### 3.2 Employer 模块
负责：
- 雇主首页数据
- 收藏翻译员
- 提交需求
- 我的需求列表与需求详情追踪
- 雇主订单

说明：
- 为完成 MVP 验证，Employer 模块不应只让雇主“发布需求”，还必须让其“看见自己发布的需求并追踪进度”。

### 3.3 Translator 模块
负责：
- 入驻资料
- 审核状态
- 工作台
- 报价
- 档期
- 翻译员订单

说明：
- 当前 MVP 需额外补一个开发环境验证入口，用于模拟审核通过，避免只能通过数据库手改完成验证。

### 3.4 Marketplace 模块
负责：
- 找翻译列表
- 筛选
- 翻译员详情

### 3.5 Order 模块
负责：
- 订单创建
- 订单状态流转
- 时间线记录
- 联系人脱敏与解锁

### 3.7 Chat 模块
负责：
- 会话创建与获取
- 消息发送与列表
- 未读消息计数
- 需求卡片消息（雇主发送）
- 客服虚拟会话（user_id=0）

说明：
- 当前为最小聊天系统，支持文本消息、需求卡片消息和图片消息
- 图片消息双方均可发送和查看
- 不含实时推送、已读回执、语音/视频/文件等多媒体
- 客服会话使用保留用户 ID 0，始终置顶
- 会话通过 `(min(id1,id2), max(id1,id2))` 规范化防止重复

### 3.8 Notification 模块
负责：
- 站内通知创建与存储
- 通知列表查询（分页、已读/未读过滤）
- 未读通知计数
- 标记已读 / 全部已读

说明：
- 通知由后端在关键业务节点自动创建（需求提交、审核、报价、订单状态变更等）
- 通知关联业务实体（related_type + related_id），支持点击跳转
- 当前为站内通知，不含推送通知

### 3.6 Admin/Platform 占位模块
MVP 不做后台，但保留平台动作抽象：
- 审核译员
- 取消订单
- 通知
- 客服

说明：
- 当前阶段不做正式后台管理台，但允许提供开发环境下的最小审核验证入口。

## 4. 核心实体
### 4.1 User
- id
- role
- phone
- email
- password_hash / otp_login
- status
- created_at

### 4.2 EmployerProfile
- id
- user_id
- company_name
- invoice_title
- tax_no
- contact_name
- contact_phone

### 4.3 TranslatorProfile
- id
- user_id
- real_name
- avatar
- language_pairs          # JSON list，单选，固定选项：中英/中英阿/英阿/中阿
- service_types           # JSON list，多选，固定选项：陪同翻译/商务翻译/会议翻译
- industries              # JSON list，多选，固定选项：美容展/建材展/电子展/食品展/能源展
- service_cities          # JSON list，多选，固定选项：迪拜/阿布扎比/沙迦
- service_venues          # JSON list
- pricing_rules           # JSON obj（保留，向后兼容）
- certificates            # JSON list
- intro
- expo_experience         # String，单选，固定选项：3年以上/5年以上/8年以上/不限
- daily_rate_aed          # Float，数值型日费（AED），用于筛选
- rest_weekdays              # JSON list, 固定休息日 (0=周一..6=周日)
- rating_summary
- audit_status

说明：
- `language_pairs`、`service_types`、`industries`、`service_cities`、`expo_experience` 均使用标准化固定选项，不允许自由输入
- `daily_rate_aed` 独立存储为数值字段，不再依赖 `pricing_rules.daily`
- 筛选时 `language_pairs` 按单值精确匹配，`service_types`/`industries`/`service_cities` 按"包含任一"匹配

说明：
- `audit_status` 决定译员是否可进入主链路机会列表、是否可提交报价。
- 当前阶段允许通过“开发环境模拟审核通过”能力把状态从 `UNDER_REVIEW` 切到 `APPROVED`，仅用于验证流程，不作为正式后台能力替代。

### 4.4 AvailabilitySlot
- id
- translator_id
- date
- status
- city
- venue
- note

### 4.5 TranslationRequest
- id
- employer_id
- expo_name
- city
- venue
- date_start
- date_end
- language_pairs
- translation_type
- industry
- budget_min_aed
- budget_max_aed
- invoice_required
- remark
- request_status
- review_status              # PENDING_REVIEW / APPROVED / REJECTED
- contact_name
- contact_phone
- company_name
- created_at

说明：
- `contact_name`、`contact_phone`、`company_name` 由雇主提交需求时填写。
- 联系人信息在订单确认前对译员侧应脱敏展示。
- `request_status` 用于描述需求本身状态，不等同于订单状态。
- `review_status` 用于描述需求的平台审核状态。提交后为 `PENDING_REVIEW`，仅 `APPROVED` 的需求对翻译员可见。
- `TranslationRequest` 是报价与订单的上游实体，雇主必须能在客户端看到自己创建的 request，并跟踪其从”待报价 / 报价中”到”已生成订单”的进展。

### 4.6 Quote
- id
- request_id
- translator_id
- quote_type
- amount_aed
- service_days
- service_time_slots
- tax_type
- remark
- quote_status
- created_at

说明：
- Quote 直接挂在 TranslationRequest 下。
- 雇主在需求详情页查看并确认报价；不是在“订单生成前”直接从订单列表里做选择。

### 4.7 Order
- id
- request_id
- employer_id
- translator_id
- selected_quote_id
- order_status
- confirmed_at
- started_at
- completed_at
- cancelled_at
- created_at

说明：
- 订单由雇主确认某条报价后创建。
- 当前 MVP 实现中，订单初始状态从 `PENDING_CONFIRM` 开始。
- Order 是 TranslationRequest 的下游结果，页面与接口应保持“需求 -> 订单”的清晰跳转关系。

### 4.8 OrderTimeline
- id
- order_id
- event_type
- event_text
- operator_role
- created_at

### 4.9 Favorite
- id
- employer_id
- translator_id
- created_at

约束：
- `(employer_id, translator_id)` 唯一
- 仅雇主可收藏翻译员

说明：
- Favorite 属于弱业务实体，不参与当前 MVP 主链路。

### 4.10 Review
- id
- order_id（FK orders.id，UNIQUE — 一个订单只能有一条评价）
- employer_id（FK users.id）
- translator_id（FK users.id）
- rating（Integer 1-5）
- content（Text，可选）
- created_at

约束：
- `order_id` UNIQUE 保证一订单只能评价一次
- 仅雇主可提交评价
- 仅 `COMPLETED` 状态的订单可评价
- 评论对象必须是该订单对应的翻译员

说明：
- 提交评价后自动重新计算并更新 `TranslatorProfile.rating_summary`（所有评价的算术平均分）
- `rating_summary` 在翻译员列表和详情页展示

### 4.11 Conversation
- id
- user_a_id（较小的 user_id）
- user_b_id（较大的 user_id）
- last_message_at
- created_at

约束：
- `(user_a_id, user_b_id)` UNIQUE
- `user_a_id = min(id1, id2)`, `user_b_id = max(id1, id2)` 规范化

### 4.12 Message
- id
- conversation_id（FK conversations.id）
- sender_id（FK users.id）
- msg_type（TEXT / DEMAND_CARD / IMAGE）
- content（文本内容或 JSON）
- image_url（图片消息的访问地址，可选）
- ref_request_id（FK translation_requests.id，可选）
- is_read
- created_at

说明：
- TEXT 类型：content 为纯文本
- DEMAND_CARD 类型：content 为 JSON，包含需求摘要信息（expoName、dateStart、dateEnd、languagePairs、city、venue、budgetMinAed、budgetMaxAed）
- IMAGE 类型：image_url 存储图片相对路径，content 为 `[图片]`
- ref_request_id 用于关联原始需求

### 4.13 Notification
- id
- user_id（FK users.id）
- type（通知类型枚举）
- title
- content
- is_read
- related_type（关联实体类型：request / order）
- related_id（关联实体 ID）
- created_at

说明：
- 通知由后端在业务节点自动创建
- 通知类型：REQUEST_SUBMITTED / REQUEST_APPROVED / REQUEST_REJECTED / QUOTE_RECEIVED / QUOTE_CONFIRMED / ORDER_STATUS_CHANGED
- `related_type` + `related_id` 用于前端点击跳转到对应详情页

## 5. 状态机
### 5.1 翻译员审核状态
- 待提交
- 审核中
- 需补充
- 已通过

规则：
- 已通过才可报价
- 已通过才可查看主链路机会列表

补充说明：
- 当前 MVP 验证阶段允许提供开发环境模拟审核通过入口，用于验证审核前后权限差异。
- 正式版本仍应由平台审核逻辑决定最终审核状态。

### 5.2 档期状态
- 可接单
- 已占用
- 待确认
- 休息

### 5.3 订单状态
- 待报价
- 待确认
- 已确认
- 服务中
- 待完成确认
- 已完成
- 已取消

说明：
- 为了保持产品层统一，`待报价` 仍保留在全局枚举中。
- 当前实现中，正式创建后的订单从 `待确认` 开始，不存在实际落库的 `待报价` 订单。
- `待完成确认`：译员已标记服务完成，等待雇主最终确认；对应枚举值 `PENDING_EMPLOYER_CONFIRMATION`

### 5.4 需求状态
- `OPEN`
- `QUOTING`
- `CLOSED`
- `CANCELLED`

规则：
- 雇主提交需求 -> `OPEN`
- 首次收到报价 -> `QUOTING`
- 雇主确认报价或业务关闭 -> `CLOSED`
- 雇主取消或平台关闭 -> `CANCELLED`

### 5.5 推荐流转
- 雇主提交需求 -> 需求 `OPEN`
- 翻译员提交报价 -> 需求进入 `QUOTING`
- 雇主选择报价 -> 创建订单，订单进入 `PENDING_CONFIRM`，需求进入 `CLOSED`
- 翻译员确认档期 -> 订单 `CONFIRMED`
- 翻译员确认到场 -> 写入时间线，不改变主状态（只能执行一次，后续"开始服务"的前置条件）
- 服务开始 -> `IN_SERVICE`（前置条件：必须先"确认到场"）
- 译员标记完成 -> 订单进入 `PENDING_EMPLOYER_CONFIRMATION`
- 雇主确认完成 -> 订单进入 `COMPLETED`
- 任一非终态被取消 -> `CANCELLED`

### 5.6 需求审核状态（demandReviewStatus）
- `PENDING_REVIEW`
- `APPROVED`
- `REJECTED`

规则：
- 雇主提交需求 -> `PENDING_REVIEW`
- 平台审核通过 -> `APPROVED`（当前阶段通过开发环境入口模拟）
- 平台审核拒绝 -> `REJECTED`
- 仅 `APPROVED` 的需求出现在翻译员机会列表中

## 6. 权限规则
### 6.1 未登录用户
可：浏览首页、列表、详情
不可：收藏、提交需求、提交报价、管理订单

### 6.2 雇主
可：
- 提交需求
- 收藏翻译员
- 查看并确认报价
- 查看自己发布的需求列表与需求详情
- 查看订单

不可：
- 管理译员档期
- 提交译员报价

### 6.3 翻译员（未通过审核）
可：
- 完善资料
- 查看审核状态
- 使用开发环境审核验证入口（仅开发环境）
- 联系客服

不可：
- 报价
- 接单
- 查看主链路机会列表

### 6.4 翻译员（已通过审核）
可：
- 设置档期
- 查看需求
- 提交报价
- 履约

## 7. 数据一致性规则
- 所有金额统一 AED
- 所有日期使用 ISO 格式存储
- 所有枚举值集中定义在 constants 或 shared schema
- 订单状态变更必须写入 timeline
- 同一译员对同一需求不可重复报价

### 7.1 联系人信息可见性规则
- 在订单未达到 `CONFIRMED` 前，译员侧查看机会列表、机会详情、订单详情时，联系人信息应脱敏展示。
- 在订单达到 `CONFIRMED` 后，译员侧可查看完整联系人信息。
- 雇主侧始终可查看自己提交的完整联系人信息。

### 7.2 需求与订单的边界
- `TranslationRequest` 用于承载雇主原始需求，是报价聚合容器。
- `Order` 用于承载雇主确认报价后的履约过程。
- 页面与接口不应混淆两者语义：
  - 看报价、确认报价，发生在需求详情页
  - 跟踪履约，发生在订单详情页

## 8. API 设计原则
- 前端只消费统一 REST API
- 列表接口返回 summary 字段，详情接口返回 full 字段
- 枚举值由后端统一输出
- 所有写操作返回最新对象快照
- 所有错误返回统一结构：code / message / details
- 不得为了兼容旧前端而修改后端字段命名

## 9. 开发顺序建议
1. 先落表结构与枚举
2. 再实现认证、用户、资料、需求、报价、订单主链路
3. 前端先接 mock 数据跑页面
4. API 稳定后切真实接口
5. 每完成一个模块，更新 README、API 文档、状态流转

补充：
- 当前阶段在进入非主链路扩展前，应优先保证“审核通过 -> 可报价”“提交需求 -> 我的需求 -> 看报价 -> 生成订单 -> 跟踪进度”两条闭环都可通过 UI 验证完成。

## 10. AI 开发约束
- 任何新增字段，必须先写入 PRD 和 API 合同
- 任何新增状态，必须先写入 architecture 状态机
- 任何改名，必须全项目同步
- 不允许前端本地私自定义与后端不一致的枚举值
- 当前阶段优先保证主链路稳定，不扩展非主链路功能
- 当前阶段允许使用开发环境可见的最小验证入口，但必须在文档中明确标注其用途与边界
