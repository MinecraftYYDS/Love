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
