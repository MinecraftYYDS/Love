# 贴贴记录

一个采用孟菲斯设计风格 (Memphis Design) 的情侣互动记录页面。包含恋爱计时、照片墙、留言板、音乐、足迹地图和路人祝福功能。

🔗 **在线预览**: [https://love.qwq.my](https://love.qwq.my)

## ✨ 功能特性

1.  **恋爱计时器 (Countdown)**
    -   实时显示在一起的天数、小时、分钟和秒数。
    -   孟菲斯风格的时间卡片展示。

2.  **路人祝福 & 弹幕 (Blessing & Danmaku)**
    -   访客可以点击 "99 +1" 送上祝福。
    -   **实时弹幕**: 发送祝福语，以横向滚动弹幕形式展示。
    -   **防重叠系统**: 智能轨道分配，确保弹幕互不遮挡。
    -   **管理功能**: 管理员可删除不当留言。
    -   实时同步祝福总数和留言 (Supabase Realtime)。

3.  **碎碎念 (Chat)**
    -   专属于情侣两人的对话空间。
    -   **对话模式**: 未登录时，以对话形式展示 (Person 1 左侧, Person 2 右侧)。
    -   **用户模式**: 登录后，当前用户始终在右侧，对方在左侧。
    -   支持实时消息推送。

4.  **照片墙 (Photo Wall)**
    -   支持上传照片并添加描述。
    -   拍立得 (Polaroid) 风格的照片预览框。
    -   支持编辑和删除已发布的照片。

5.  **音乐盒 (Music Player)**
    -   支持上传 MP3/FLAC 格式音乐。
    -   可视化音频频谱跳动效果。
    -   支持播放列表管理、音量调节和进度控制。

6.  **足迹地图 (Footprint Map)**
    -   交互式中国地图，点亮共同去过的省份。
    -   孟菲斯风格配色，支持悬停查看地名。
    -   登录后可编辑足迹，实时同步点亮状态。

7.  **全局设置 (Settings)**
    -   管理员权限保护。
    -   可配置双方昵称、头像、专属密码和恋爱起始日期。
    -   **模块管理**: 支持自定义开启或关闭各个功能模块 (如暂时隐藏地图或音乐播放器)。

8.  **实时在线状态 (Realtime Presence)**
    -   当双方同时在线且聚焦页面时，显示 "👀 对方也在看" 提示。
    -   基于 Supabase Presence 实现。

9.  **数据库变更通知 (Telegram / Webhook)**
    -   在常用表发生新增、修改或删除后，自动推送通知。
    -   Telegram 发送的是已整理好的直观消息，适合直接发到频道。
    -   Webhook 发送尽量完整的原始数据，方便接收端自行处理。
    -   可在管理员设置中单独配置 Telegram 和 Webhook，并支持“只发 Telegram / 只发 Webhook”。

## 📦 部署前必做

如果你要自己复刻并部署，这些数据库步骤一定要做完：

1. 按顺序执行 `sql/00_schema_setup.sql` 到 `sql/08_additional_setup.sql`
2. 继续执行 `sql/09_notifications_setup.sql`
3. 确认 Supabase Storage 中存在 `photos`、`music`、`avatars` 三个 bucket
4. 确认 `settings` 表至少有一条记录，否则首页第一次加载会出现 406

### 额外修复说明

- `show_milestones` 是成就墙所需字段，`07_create_achievements_table.sql` 只建了表，没有补这个列
- 头像上传使用 `avatars` bucket，必须单独创建
- 照片上传文件名不能包含中文，否则 Supabase Storage 会报 `Invalid key`
- `NEXT_PUBLIC_SETTINGS_PASSWORD` 只是首次默认值，数据库里的 `admin_password` 会优先生效
- Telegram 通知需要填写 `notify_telegram_bot_token` 和 `notify_telegram_chat_id`
- Webhook 通知只需要填写 `notify_webhook_url`，`notify_webhook_secret` 可选
- 如果同时勾选了“只发 Telegram”和“只发 Webhook”，界面会自动保留最新一个开关为准

## 🛠 技术架构

本项目基于现代前端技术栈构建，注重性能和开发体验。

### 核心技术栈

-   **框架**: [Next.js 16](https://nextjs.org/) (App Router)
-   **语言**: [TypeScript](https://www.typescriptlang.org/)
-   **UI 库**: [React 19](https://react.dev/)
-   **样式**: [UnoCSS](https://unocss.dev/) (自定义 Memphis Preset)
-   **后端服务**: [Supabase](https://supabase.com/)
    -   **Database**: PostgreSQL (存储设置、消息、照片元数据、祝福数、歌曲列表、足迹数据)
    -   **Storage**: 存储用户头像、上传的照片和音乐文件
    -   **Realtime**: 实现消息、祝福数和足迹的实时同步
-   **部署**: [Vercel](https://vercel.com/)

### 目录结构

```
.
├── scripts/                # 维护脚本 (数据清理、连接测试)
├── src/
│   ├── app/               # Next.js App Router 页面
│   ├── components/        # UI 组件 (Countdown, PhotoWall, etc.)
│   ├── lib/               # Supabase 客户端配置
│   ├── utils/             # 工具函数 (Cookie 管理等)
│   └── types.ts           # TypeScript 类型定义
├── uno.config.ts          # UnoCSS 配置文件 (主题、快捷方式)
└── ...
```

## 🚀 快速开始

### 1. 环境准备

确保已安装 Node.js (v18+) 和 pnpm。

### 2. 安装依赖

```bash
pnpm install
```

### 3. 配置环境变量

复制 `.env.local.example` (如果有) 或新建 `.env.local`，填入 Supabase 配置：

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_SETTINGS_PASSWORD=your_admin_password
NEXT_PUBLIC_SITE_TITLE=贴贴记录
```

说明：`NEXT_PUBLIC_SETTINGS_PASSWORD` 只会在数据库 `settings.admin_password` 为空时作为兜底值使用。你后续如果改了设置面板里的管理员密码，要以数据库值为准。

### 4. 初始化数据库

进入 Supabase 控制台的 SQL Editor，按顺序执行：

```text
sql/00_schema_setup.sql
sql/01_storage_setup.sql
sql/02_fix_songs_table.sql
sql/03_visited_places_setup.sql
sql/04_add_module_toggles.sql
sql/05_public_messages.sql
sql/06_optimize_blessings.sql
sql/07_create_achievements_table.sql
sql/08_additional_setup.sql
sql/09_notifications_setup.sql
```

### 5. 启动开发服务器

```bash
pnpm dev
```

访问 `http://localhost:3000` 查看效果。

## 🔧 维护脚本

项目内置了一些实用脚本，位于 `scripts/` 目录下：

-   **测试数据库连接**:
    ```bash
    pnpm script:test-connection
    ```
-   **清理测试数据** (慎用，会清空所有远程数据):
    ```bash
    pnpm script:delete-test-data
    ```

## Webhook 接收说明

当数据库发生写入、修改或删除时，系统会向管理员设置里配置的 Webhook URL 发送 `POST` 请求。Webhook 适合做自动化同步、消息转发、日志归档、审查队列、统计报表等。

### 请求方式

- 方法: `POST`
- Content-Type: `application/json`
- 额外请求头: `X-Love-Source: love-app`
- 如果设置了密钥，还会带上: `X-Love-Webhook-Secret: <管理员设置里的 Webhook Secret>`

### 基本 Payload

```json
{
  "source": "love-app",
  "schema": "public",
  "table": "messages",
  "operation": "INSERT",
  "record_id": "123",
  "changed_fields": ["text", "date"],
  "old_row": null,
  "new_row": {
    "id": 123,
    "text": "今天也要开心",
    "date": "2026-05-24T12:00:00.000Z",
    "sender": "name1"
  },
  "occurred_at": "2026-05-24T12:00:00Z"
}
```

### 字段说明

- `source`: 固定为 `love-app`
- `schema`: 数据库 schema，当前是 `public`
- `table`: 触发来源表名
- `operation`: 操作类型，可能是 `INSERT`、`UPDATE`、`DELETE`
- `record_id`: 记录主键，统一以字符串形式发送
- `changed_fields`: 本次变化的字段名数组
- `old_row`: 更新前或删除前的数据，新增时为 `null`
- `new_row`: 新增后或更新后的数据，删除时为 `null`
- `occurred_at`: 触发时间，UTC ISO 格式

### 会触发的表

- `messages`: 情侣留言
- `photos`: 照片墙
- `songs`: 音乐列表
- `public_messages`: 路人祝福弹幕
- `visited_places`: 足迹地图
- `achievements`: 成就墙
- `blessing_stats`: `99 +1` 祝福计数

### 接收端处理建议

1. 先校验 `X-Love-Webhook-Secret`，不匹配直接返回 `401`。
2. 再判断 `table` 和 `operation`，把不同业务表分流到不同处理器。
3. `changed_fields` 适合做增量处理，`new_row` 适合做全量同步。
4. Webhook 接口应尽快返回 `2xx`，耗时任务建议丢进队列异步处理。
5. 如果处理失败，记录完整 payload，方便后续排查和手动重放。

### Node.js/Express 示例

```js
import express from 'express';

const app = express();
app.use(express.json());

app.post('/webhook/love', async (req, res) => {
  const secret = req.header('X-Love-Webhook-Secret');
  if (secret !== process.env.LOVE_WEBHOOK_SECRET) {
    return res.status(401).json({ error: 'invalid secret' });
  }

  const { table, operation, new_row, old_row, changed_fields } = req.body;

  if (table === 'messages' && operation === 'INSERT') {
    console.log('new message:', new_row?.text);
  }

  if (table === 'photos' && operation === 'INSERT') {
    console.log('new photos:', new_row?.image_urls);
  }

  if (table === 'blessing_stats' && operation === 'UPDATE') {
    console.log('blessing count:', old_row?.count, '=>', new_row?.count);
  }

  return res.status(200).json({ ok: true });
});

app.listen(3000);
```

### Next.js Route Handler 示例

```ts
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const secret = req.headers.get('X-Love-Webhook-Secret');
  if (secret !== process.env.LOVE_WEBHOOK_SECRET) {
    return NextResponse.json({ error: 'invalid secret' }, { status: 401 });
  }

  const payload = await req.json();

  switch (payload.table) {
    case 'messages':
      console.log('message changed:', payload.operation, payload.new_row);
      break;
    case 'blessing_stats':
      console.log('99 +1:', payload.old_row?.count, '=>', payload.new_row?.count);
      break;
    default:
      console.log('other change:', payload.table, payload.operation);
  }

  return NextResponse.json({ ok: true });
}
```

### 处理示例

- `messages`: 转发到企业微信、Discord、邮件或自己的后台消息中心
- `photos`: 同步到相册系统，或加入图片压缩/审核任务
- `songs`: 同步歌单，刷新缓存
- `public_messages`: 接入敏感词审查或运营日志
- `visited_places`: 更新地图统计、旅行时间线
- `achievements`: 同步成就时间线
- `blessing_stats`: 记录每次 `99 +1` 的总数变化

## 🐞 常见问题

### 头像上传失败

- 确认 Supabase Storage 存在 `avatars` bucket
- 确认 `storage.objects` 上有 `avatars` 的 INSERT policy

### 照片上传失败

- 确认 `photos` bucket 存在
- 确认 policy 里显式允许 `anon, authenticated` 上传
- 如果文件名包含中文，先用新的上传逻辑或重命名文件

### 页面出现 406

- `settings` 表为空时，首次加载会触发 `.single()` 406
- 执行 `sql/08_additional_setup.sql` 会自动补一条默认记录

### 管理员密码改了没生效

- 数据库里的 `settings.admin_password` 会优先于环境变量
- 去 Supabase 里更新那一列，或者在设置面板里改

## 🎨 设计风格

本项目采用 **Memphis Design** 风格，特点包括：
-   高饱和度的配色 (Pink, Cyan, Yellow, Purple, Orange)
-   粗黑边框 (3px border)
-   几何图形装饰
-   硬阴影 (Hard Shadows)

---

Made with ❤️ by SnowballXueQiu
