# 展会翻译 App - API Contract

## 更新记录
- 更新时间：2026-03-21（第三次）
- 修改原因：新增 demandReviewStatus 枚举（2.11）、需求审核相关接口（5.10）、Notification 接口（11.1-11.4）、翻译员机会列表过滤已审核需求。
- 更新时间：2026-03-21（第二次）
- 修改原因：图片发送开放给双方（雇主+翻译员），DEMAND_CARD 发送新增需求状态校验（CLOSED/CANCELLED 返回 REQUEST_CLOSED 错误）。
- 更新时间：2026-03-21
- 修改原因：聊天支持图片消息——新增 IMAGE 消息类型（2.10）、聊天图片上传接口（10.6）、Message 新增 imageUrl 字段。
- 更新时间：2026-03-20（第二次）
- 修改原因：新增 Chat 模块接口（10.1-10.5），支持最小聊天系统；新增 msgType 枚举（2.10）；新增翻译员工作台统计接口（6.14）。
- 更新时间：2026-03-20
- 修改原因：档期管理接口从"后续阶段"提升为已实现，补充 6.8 / 6.9 完整请求/响应合同，TranslatorProfile 新增 restWeekdays 字段。
- 更新时间：2026-03-19（第二次）
- 修改原因：新增评价功能——雇主在订单完成后对翻译员的评价，及翻译员详情页评价展示接口。
- 更新时间：2026-03-19
- 修改原因：在保留 Phase 4 / Phase 5 主链路合同说明的基础上，合并”最小 MVP 验证闭环”新增内容，包括开发环境模拟审核通过、我的需求列表、需求详情到订单追踪。

## 1. 统一约定
### 1.1 Base URL
- `/api/v1`

### 1.2 响应结构
成功：
```json
{
  "success": true,
  "data": {},
  "message": "ok"
}
```

失败：
```json
{
  "success": false,
  "message": "error message",
  "code": "ERROR_CODE",
  "details": {}
}
```

### 1.3 鉴权
- 登录后返回 `accessToken`
- 需要登录的接口使用 `Authorization: Bearer <token>`

### 1.4 当前文档适用范围
- 本文档既约束当前已联调主链路，也约束为完成 MVP 验证闭环所新增的最小补齐能力。
- 未标注“后续阶段”的接口，默认视为当前阶段应可用或应优先补齐。
- 如实现与合同冲突，应先更新本文件，再修改代码。

## 2. 枚举
### 2.1 role
- `EMPLOYER`
- `TRANSLATOR`

### 2.2 auditStatus
- `PENDING_SUBMISSION`
- `UNDER_REVIEW`
- `NEED_SUPPLEMENT`
- `APPROVED`

说明：
- `PENDING_SUBMISSION`：尚未提交完整资料
- `UNDER_REVIEW`：资料已提交，等待平台审核
- `NEED_SUPPLEMENT`：资料不足，需要补充
- `APPROVED`：审核通过，可查看机会、可提交报价

### 2.3 orderStatus
- `PENDING_QUOTE`
- `PENDING_CONFIRM`
- `CONFIRMED`
- `IN_SERVICE`
- `PENDING_EMPLOYER_CONFIRMATION`
- `COMPLETED`
- `CANCELLED`

说明：
- `PENDING_QUOTE` 作为全局订单状态枚举保留，用于产品与列表筛选统一。
- 当前 MVP 实现中，订单在雇主确认报价后创建，初始状态从 `PENDING_CONFIRM` 开始。
- `PENDING_EMPLOYER_CONFIRMATION`：译员已标记服务完成，等待雇主最终确认

### 2.4 availabilityStatus
- `AVAILABLE`
- `OCCUPIED`
- `PENDING_CONFIRM`
- `REST`

### 2.5 quoteType
- `HOURLY`
- `DAILY`
- `PROJECT`

### 2.6 requestStatus
- `OPEN`
- `QUOTING`
- `CLOSED`
- `CANCELLED`

说明：
- `OPEN`：需求已创建，等待报价
- `QUOTING`：已有报价，继续开放中
- `CLOSED`：需求已关闭
- `CANCELLED`：需求已取消

### 2.7 quoteStatus
- `SUBMITTED`
- `ACCEPTED`
- `REJECTED`

说明：
- `SUBMITTED`：报价已提交
- `ACCEPTED`：报价已被雇主选中
- `REJECTED`：报价未被选中或被拒绝

### 2.8 taxType
- `TAX_INCLUDED`
- `TAX_EXCLUDED`

### 2.10 msgType
- `TEXT`
- `DEMAND_CARD`
- `IMAGE`

说明：
- `TEXT`：纯文本消息
- `DEMAND_CARD`：需求卡片消息，content 为 JSON，包含需求摘要
- `IMAGE`：图片消息，imageUrl 存储图片访问地址，content 为 `[图片]`

### 2.11 demandReviewStatus
- `PENDING_REVIEW`
- `APPROVED`
- `REJECTED`

说明：
- `PENDING_REVIEW`：需求已提交，等待平台审核
- `APPROVED`：审核通过，翻译员可见
- `REJECTED`：审核未通过

### 2.12 notificationType
- `REQUEST_SUBMITTED`
- `REQUEST_APPROVED`
- `REQUEST_REJECTED`
- `QUOTE_RECEIVED`
- `QUOTE_CONFIRMED`
- `ORDER_STATUS_CHANGED`

说明：
- 通知由后端在业务节点自动创建，不需要前端主动触发

### 2.9 translatorOrderAction
- `CONFIRM_SCHEDULE`
- `CONFIRM_ARRIVAL`
- `START_SERVICE`
- `COMPLETE_SERVICE`
- `CANCEL_ORDER`

## 3. Auth
### 3.1 登录
`POST /auth/login`

request:
```json
{
  "loginType": "phone_or_email",
  "account": "example@mail.com",
  "password": "123456",
  "role": "EMPLOYER"
}
```

response:
```json
{
  "success": true,
  "data": {
    "accessToken": "token",
    "user": {
      "id": 1,
      "role": "EMPLOYER",
      "phone": "",
      "email": "example@mail.com"
    }
  },
  "message": "ok"
}
```

### 3.2 注册
`POST /auth/register`

request:
```json
{
  "loginType": "phone_or_email",
  "account": "example@mail.com",
  "password": "123456",
  "role": "EMPLOYER"
}
```

response：
- 与登录接口保持同一结构
- 返回 `accessToken` 与 `user`

### 3.3 设置身份
`PUT /auth/role`

request:
```json
{
  "role": "EMPLOYER"
}
```

### 3.4 当前用户
`GET /auth/me`

## 4. Marketplace
### 4.1 翻译员列表
`GET /marketplace/translators`

query:
- city
- venue
- date
- languagePair
- translationType
- industry
- budgetMin
- budgetMax
- expoExperience
- page
- pageSize

说明：
- 当前阶段未联调完成
- 现有前端页面如使用该接口，需以后端实际能力为准补齐筛选参数

### 4.2 翻译员详情
`GET /marketplace/translators/:id`

### 4.3 收藏翻译员
`POST /marketplace/translators/:id/favorite`

鉴权：需登录（雇主）
response:
```json
{ "success": true, "data": { "isFavorited": true } }
```
说明：
- 仅雇主可调用；重复收藏幂等返回成功
- 被收藏的翻译员必须已通过审核（`APPROVED`）

### 4.4 取消收藏
`DELETE /marketplace/translators/:id/favorite`

鉴权：需登录（雇主）
response:
```json
{ "success": true, "data": { "isFavorited": false } }
```
说明：幂等，不存在时也返回成功

### 4.5 收藏列表
`GET /marketplace/favorites`

鉴权：需登录（雇主）
response: 与 4.1 格式一致，所有条目的 `isFavorited` 均为 `true`

说明：
- 翻译员列表接口（4.1）接受可选鉴权；已登录雇主获取的列表中，每个翻译员的 `isFavorited` 字段会根据真实收藏状态返回

## 5. Employer
### 5.1 提交需求
`POST /employer/requests`

request:
```json
{
  "expoName": "Dubai Beauty Expo",
  "city": "Dubai",
  "venue": "Dubai World Trade Centre",
  "dateStart": "2026-03-10",
  "dateEnd": "2026-03-12",
  "languagePairs": ["ZH-EN"],
  "translationType": "Booth",
  "industry": "Beauty",
  "budgetMinAed": 800,
  "budgetMaxAed": 1500,
  "contactName": "陈女士",
  "contactPhone": "13800008888",
  "companyName": "XX科技",
  "invoiceRequired": true,
  "remark": "需要熟悉美容展术语"
}
```

说明：
- 创建成功后，需求初始状态为 `OPEN`，审核状态为 `PENDING_REVIEW`
- `contactName`、`contactPhone`、`companyName` 由雇主在提交需求时填写
- 联系人信息在译员侧默认脱敏展示
- 提交成功后，前端应提供进入“需求详情”或“我的需求”的入口，而不是让需求在流程中消失

### 5.2 我的需求列表
`GET /employer/requests`

query:
- status
- hasOrder
- page
- pageSize

返回字段最少应包含：
- id
- expoName
- city
- venue
- dateRange
- requestStatus
- reviewStatus
- quoteCount
- hasOrder
- orderId

说明：
- 该接口用于补齐雇主侧”查看自己发布的需求并追踪进度”的 MVP 验证闭环
- 雇主应能在该列表中区分”仍在收报价的需求”和”已生成订单的需求”
- 若 `hasOrder=true`，前端应提供明显的”查看订单进度”入口
- `reviewStatus` 用于前端展示审核状态标签（审核中 / 审核未通过）

### 5.3 需求详情
`GET /employer/requests/:id`

返回内容最少应包含：
- 需求基础信息
- 当前 `requestStatus`
- 雇主提交的联系人与企业信息
- 关联报价列表（如有）
- `hasOrder`
- `orderId`（如已生成订单）

说明：
- 雇主侧始终看到完整联系人信息
- 需求详情页是“看报价、确认报价、进入订单追踪”的关键中间页
- 当需求已确认报价并生成订单后，应返回 `hasOrder=true` 和对应 `orderId`，以支持页面跳转到订单详情

### 5.4 雇主订单列表
`GET /employer/orders`

query:
- status
- page
- pageSize

### 5.5 雇主订单详情
`GET /employer/orders/:id`

联系人信息返回规则：
- 雇主侧始终返回完整联系人信息

说明：
- 订单详情页应支持回看来源需求或显示“来源需求”摘要，帮助用户理解“需求”和“订单”的上下游关系

### 5.6 确认报价
`POST /employer/orders/:id/confirm-quote`

request:
```json
{
  "quoteId": 1
}
```

说明：
- 雇主确认报价后：
  - 创建订单
  - 订单初始状态为 `PENDING_CONFIRM`
  - 被选中的报价状态变为 `ACCEPTED`
  - 同需求下其他报价状态变为 `REJECTED`
  - 对应需求状态流转为 `CLOSED`
- 成功响应中建议返回最新订单快照，或至少返回 `orderId`，以支持前端从需求详情直接跳转到订单详情

### 5.7 雇主确认服务完成
`POST /employer/orders/:id/confirm-completion`



request：无请求体

response:
```json
{
  "success": true,
  "data": {
    "orderStatus": "COMPLETED"
  },
  "message": "ok"
}
```

### 5.10 开发环境模拟需求审核通过
`POST /employer/requests/:id/dev-approve`

鉴权：需登录（雇主）

说明：
- 仅用于开发 / 测试环境
- 将指定需求的 `reviewStatus` 置为 `APPROVED`
- 同时生成"需求审核通过"站内通知
- 成功后返回更新后的需求对象

### 5.11 雇主确认服务完成
`POST /employer/orders/:id/confirm-completion`

说明：
- 仅当订单状态为 `PENDING_EMPLOYER_CONFIRMATION` 时可调用
- 成功后订单状态变为 `COMPLETED`
- 在时间线记录"雇主确认服务完成"事件，记录操作者角色为 EMPLOYER
- 非法状态转换返回错误

### 5.8 雇主提交评价
`POST /employer/orders/:id/review`

鉴权：需登录（雇主）

request:
```json
{
  "rating": 5,
  "content": "服务非常专业，沟通顺畅"
}
```

response:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "orderId": 1,
    "rating": 5,
    "content": "服务非常专业，沟通顺畅",
    "employerName": "陈女士",
    "createdAt": 1742000000
  },
  "message": "ok"
}
```

说明：
- 仅雇主可调用
- 仅当订单状态为 `COMPLETED` 时可提交评价
- 一个订单只能评价一次（重复提交返回错误码 `ALREADY_REVIEWED`）
- `rating` 必须是 1-5 之间的整数，`content` 为可选文字评价

### 5.9 雇主订单详情补充字段（评价状态）
`GET /employer/orders/:id` 响应新增字段：
- `hasReview`（boolean）：该订单是否已提交评价
- `review`（object | null）：已提交的评价对象，未评价时为 null

说明：
- 前端据此判断显示"去评价"还是"已评价"入口

### 4.6 翻译员评价列表
`GET /marketplace/translators/:id/reviews`

鉴权：无需登录（公开接口）

query:
- page
- pageSize

response:
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "orderId": 1,
        "rating": 5,
        "content": "专业准时",
        "employerName": "陈女士",
        "createdAt": 1742000000
      }
    ],
    "total": 1
  },
  "message": "ok"
}
```

说明：
- 按 createdAt 倒序返回
- 仅展示已通过评价的内容（当前无审核，即所有已提交评价）

## 6. Translator
### 6.1 提交/更新资料
`PUT /translator/profile`

说明：
- 翻译员提交资料后，`auditStatus` 应进入 `UNDER_REVIEW`
- 未通过审核时，可查看审核状态，但不可进入主链路机会列表、不可提交报价

### 6.2 获取资料
`GET /translator/profile`

说明：
- 返回当前资料内容与当前 `auditStatus`

### 6.3 开发环境模拟审核通过
`POST /translator/profile/dev-approve`

说明：
- 仅用于开发 / 测试环境，不属于正式生产能力
- 作用：将当前翻译员的 `auditStatus` 置为 `APPROVED`
- 目的：完成 MVP 验证闭环，避免通过手改数据库或 terminal 才能验证审核前后权限差异
- 前端只应在开发环境暴露该入口

### 6.4 工作台首页（后续阶段）
`GET /translator/dashboard`

### 6.5 新需求列表
`GET /translator/opportunities`

query:
- date
- city
- languagePair
- industry
- serviceType
- page
- pageSize

说明：
- 当前已联调的最小能力以实际实现为准
- `languagePair`、`serviceType` 等高级筛选可在后续阶段补齐
- 译员侧在该接口中默认只看到脱敏联系人信息
- 仅审核通过的译员可查看机会列表
- 仅 `reviewStatus=APPROVED` 的需求出现在翻译员机会列表中

### 6.6 需求详情
`GET /translator/opportunities/:id`

说明：
- 返回当前译员对该需求的已有报价（如有）
- 联系人信息默认脱敏
- 仅审核通过的译员可查看

### 6.7 提交报价
`POST /translator/quotes`

request:
```json
{
  "requestId": 1,
  "quoteType": "DAILY",
  "amountAed": 1200,
  "serviceDays": 2,
  "serviceTimeSlots": ["09:00-18:00"],
  "taxType": "TAX_EXCLUDED",
  "remark": "熟悉电子展接待"
}
```

说明：
- 成功提交报价后：
  - 当前报价状态为 `SUBMITTED`
  - 若需求原状态为 `OPEN`，则自动流转为 `QUOTING`
- 同一译员对同一需求不可重复提交报价
- 仅审核通过的译员可提交报价

### 6.8 档期列表
`GET /translator/availability`

鉴权：需登录（翻译员）

query:
- year（整数，默认当前年）
- month（整数，默认当前月）

response:
```json
{
  "success": true,
  "data": {
    "slots": {
      "2026-03-01": { "date": "2026-03-01", "status": "AVAILABLE", "city": "", "venue": "", "note": "" },
      "2026-03-02": { "date": "2026-03-02", "status": "REST", "city": "", "venue": "", "note": "固定休息日" }
    },
    "recentOrders": [
      {
        "orderId": 1,
        "expoName": "Dubai Beauty Expo",
        "dateStart": "2026-03-10",
        "dateEnd": "2026-03-12",
        "venue": "Dubai World Trade Centre",
        "city": "Dubai",
        "orderStatus": "CONFIRMED"
      }
    ],
    "profile": {
      "serviceCities": ["迪拜"],
      "serviceVenues": ["Dubai World Trade Centre"],
      "restWeekdays": [4, 5]
    }
  }
}
```

说明：
- `slots` 返回整月每天的档期状态，合并显式记录、固定休息日、活跃订单
- 优先级：活跃订单 > 显式记录 > 固定休息日 > 默认可接单
- `recentOrders` 返回当前及未来的活跃订单（非终态），按开始日期升序，最多 10 条
- `profile` 返回常驻设置（服务城市、展馆、固定休息日）
- `restWeekdays` 使用 0=周一 .. 6=周日 的约定

### 6.9 批量设置档期
`POST /translator/availability/batch`

鉴权：需登录（翻译员）

request:
```json
{
  "dates": ["2026-03-10", "2026-03-11"],
  "status": "AVAILABLE",
  "city": "Dubai",
  "venue": "Dubai World Trade Centre",
  "note": "常驻展馆"
}
```

response:
```json
{
  "success": true,
  "data": { "updated": 2 }
}
```

说明：
- `status` 必须为 `AVAILABLE` / `OCCUPIED` / `PENDING_CONFIRM` / `REST`
- 对每个日期执行 upsert：已有记录则更新，无记录则新建
- `city`、`venue`、`note` 为可选字段

### 6.10 翻译员订单列表
`GET /translator/orders`

### 6.11 翻译员订单详情
`GET /translator/orders/:id`

联系人信息返回规则：
- `CONFIRMED` 前返回脱敏联系人信息
- `CONFIRMED` 及之后返回完整联系人信息

### 6.12 订单履约动作
`POST /translator/orders/:id/action`

request:
```json
{
  "action": "START_SERVICE"
}
```

允许 action：
- `CONFIRM_SCHEDULE`
- `CONFIRM_ARRIVAL`
- `START_SERVICE`
- `COMPLETE_SERVICE`
- `CANCEL_ORDER`

状态流转规则：
- `PENDING_CONFIRM -> CONFIRMED`：`CONFIRM_SCHEDULE`
- `CONFIRMED -> CONFIRMED`：`CONFIRM_ARRIVAL`（记录到场确认事件，不改变主状态）
- `CONFIRMED -> IN_SERVICE`：`START_SERVICE`（前置条件：已执行过 `CONFIRM_ARRIVAL`）
- `IN_SERVICE -> PENDING_EMPLOYER_CONFIRMATION`：`COMPLETE_SERVICE`
- `PENDING_CONFIRM / CONFIRMED / IN_SERVICE -> CANCELLED`：`CANCEL_ORDER`

说明：
- `CONFIRM_ARRIVAL` 是一次性事件，只能执行一次，防止重复确认
- `START_SERVICE` 必须先执行 `CONFIRM_ARRIVAL`，否则返回错误 `ARRIVAL_REQUIRED`
- 非法状态转换必须返回错误
- 成功动作必须写入订单时间线

### 6.13 翻译员评价中心
`GET /translator/reviews`

鉴权：需登录（翻译员）

query:
- page
- pageSize

response:
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "orderId": 1,
        "rating": 5,
        "content": "专业准时",
        "employerName": "陈女士",
        "expoName": "Dubai Beauty Expo",
        "createdAt": 1742000000
      }
    ],
    "total": 1,
    "avgRating": 5.0
  },
  "message": "ok"
}
```

说明：
- 翻译员查看自己收到的所有评价
- 返回平均评分 `avgRating` 用于展示
- 每条评价附带来源展会名 `expoName`

### 6.14 翻译员工作台统计
`GET /translator/dashboard/stats`

鉴权：需登录（翻译员，已审核通过）

response:
```json
{
  "success": true,
  "data": {
    "pendingQuote": 3,
    "pendingConfirm": 1,
    "todayService": 0,
    "weekOrders": 2
  }
}
```

说明：
- `pendingQuote`：OPEN/QUOTING 状态且该翻译员尚未报价的需求数
- `pendingConfirm`：PENDING_CONFIRM 状态的订单数
- `todayService`：CONFIRMED/IN_SERVICE 且今日在服务日期范围内的订单数
- `weekOrders`：本周（周一-周日）内有重叠的非终态订单数

## 10. Chat
### 10.1 获取或创建会话
`POST /chat/conversations`

鉴权：需登录

request:
```json
{
  "otherUserId": 2
}
```

response:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "otherUserId": 2,
    "otherUserName": "张翻译"
  }
}
```

说明：
- `otherUserId=0` 用于客服会话
- 会话通过 `(min(id1,id2), max(id1,id2))` 规范化，防止重复创建

### 10.2 会话列表
`GET /chat/conversations`

鉴权：需登录

query:
- page
- pageSize

response:
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "otherUserId": 2,
        "otherUserName": "张翻译",
        "lastMessage": "你好",
        "lastMessageAt": 1742000000,
        "unreadCount": 2,
        "isCustomerService": false
      }
    ],
    "total": 1
  }
}
```

说明：
- 客服会话始终置顶
- 若用户无客服会话，列表首位添加虚拟客服条目（id=0）

### 10.3 消息列表
`GET /chat/conversations/:id/messages`

鉴权：需登录

query:
- page
- pageSize

response:
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "senderId": 1,
        "msgType": "TEXT",
        "content": "你好",
        "createdAt": 1742000000
      }
    ],
    "total": 1
  }
}
```

说明：
- 获取消息时自动将对方发送的未读消息标记为已读

### 10.4 发送消息
`POST /chat/conversations/:id/messages`

鉴权：需登录

request:
```json
{
  "msgType": "TEXT",
  "content": "你好",
  "refRequestId": null,
  "imageUrl": null
}
```

说明：
- `msgType` 为 `DEMAND_CARD` 时，`refRequestId` 必填，后端自动填充需求摘要到 content；若需求状态为 `CLOSED` 或 `CANCELLED`，返回错误码 `REQUEST_CLOSED`
- `msgType` 为 `TEXT` 时，`content` 必填
- `msgType` 为 `IMAGE` 时，`imageUrl` 必填（通过 10.6 接口上传获得），content 默认为 `[图片]`；双方均可发送

### 10.6 上传聊天图片
`POST /chat/upload-image`

鉴权：需登录

request：`multipart/form-data`
- `image`：图片文件（支持 png/jpg/jpeg/gif/webp，最大 10MB）

response:
```json
{
  "success": true,
  "data": {
    "imageUrl": "/uploads/chat_images/1742000000_abc12345.jpg"
  }
}
```

说明：
- 返回的 `imageUrl` 为相对路径，前端拼接后端 host 即可访问
- 当前仅用于聊天图片，不是通用上传接口
- 双方（雇主和翻译员）均可上传和发送图片

### 10.5 未读消息总数
`GET /chat/unread-count`

鉴权：需登录

response:
```json
{
  "success": true,
  "data": {
    "count": 5
  }
}
```

## 11. Notification
### 11.1 通知列表
`GET /notifications`

鉴权：需登录

query:
- isRead（可选，true/false）
- page
- pageSize

response:
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "type": "QUOTE_RECEIVED",
        "title": "收到新报价",
        "content": "翻译员张三对您的需求「Dubai Beauty Expo」提交了报价",
        "isRead": false,
        "relatedType": "request",
        "relatedId": 1,
        "createdAt": 1742000000
      }
    ],
    "total": 1
  }
}
```

### 11.2 未读通知数
`GET /notifications/unread-count`

鉴权：需登录

response:
```json
{
  "success": true,
  "data": {
    "count": 3
  }
}
```

### 11.3 标记单条已读
`PUT /notifications/:id/read`

鉴权：需登录

说明：
- 仅可标记自己的通知

### 11.4 全部标记已读
`POST /notifications/read-all`

鉴权：需登录

说明：
- 将当前用户所有未读通知标记为已读

## 7. Common（后续阶段）
### 7.1 枚举接口
`GET /common/enums`

### 7.2 上传接口
`POST /common/upload`

### 7.3 客服入口配置
`GET /common/support`

## 8. 返回字段最小要求
### 8.1 翻译员卡片 summary
- id
- avatar
- name
- languagePairs
- city
- basePriceAed
- rating
- expoTags
- isAvailable
- isFavorited

### 8.2 我的需求卡片 summary
- id
- expoName
- city
- venue
- dateRange
- requestStatus
- quoteCount
- hasOrder
- orderId

### 8.3 订单卡片 summary
- id
- orderNo
- expoName
- city
- venue
- dateRange
- counterpartName
- quoteSummary
- status

### 8.4 时间线 item
- eventType
- eventText
- createdAt
- operatorRole

## 9. 当前阶段说明
- 当前已联调完成的 MVP 主链路：登录/注册/身份选择、提交需求、查看机会、提交报价、确认报价、订单履约。
- 为补齐可验证闭环，当前阶段同时应支持：开发环境模拟审核通过、我的需求列表、需求详情到订单详情的追踪跳转。
- 最小聊天系统（10.1-10.6）已实现，支持文本消息、需求卡片消息和图片消息（双方均可发送）。发送 DEMAND_CARD 时会校验需求状态，已关闭/已取消的需求拒绝发送。聊天中需求卡片点击可跳转到对应详情页。
- 翻译员工作台统计（6.14）已实现。
- 需求审核状态（demandReviewStatus）已实现，翻译员仅可见已审核通过的需求。
- 站内通知系统（11.1-11.4）已实现，支持通知列表、未读计数、标记已读、全部已读。
- Marketplace、收藏仍属于后续完善阶段；档期管理（6.8 / 6.9）已实现。Common 接口仍属于后续阶段。
- 前后端联调以本文件为唯一合同；如实现与合同冲突，应先更新本文件再改代码。
