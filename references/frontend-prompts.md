# 前端优化 Prompt 库

给 **Codex** 使用（PTY=true, --yolo 模式）。按需选用，可组合。

**参考资源**：
- https://uipocket.com/（UI 灵感）
- https://component.gallery/（组件参考）
- 图标库：`lucide-react`（首选）/ `heroicons` / `tabler-icons`

---

## A. 设计风格（选一种作为基调）

### A1. 玻璃拟态风 + 莫兰蒂色系

```
帮我把 [组件/页面] 重新设计为玻璃拟态（Glassmorphism）风格：

设计规范：
- 色系：莫兰迪色（低饱和度、高级感）
  主色：#9E9E9E / 辅色：#B5C4B1 / 强调：#C4A882
- 背景：半透明毛玻璃效果
  backdrop-filter: blur(12px)
  background: rgba(255, 255, 255, 0.08)
  border: 1px solid rgba(255, 255, 255, 0.15)
- 浮窗：Glassmorphism + 叠加一层淡白色噪点纹理（SVG noise filter）
- 圆角：12-16px
- 阴影：0 8px 32px rgba(0,0,0,0.12)
```

### A2. 深色科技感（数据看板类）

```
帮我重新设计 [组件/页面]，采用深色科技感风格：

设计规范：
- 背景色：极简深黑 #0A0B0E
- 品牌色：紫→蓝渐变 #A855F7 → #3B82F6，用于标签和核心图表
- 布局：左右双栏
  左侧：顶部带外发光的渐变圆角标签 + 超大轻量化标题 + 灰色层级描述 + 双按钮（主按钮流光质感，次按钮细边框）
  右侧：悬浮式数据看板卡片，微弱玻璃态渐变背景，超大数值 + 斜纹背景柱状图，峰值柱带霓虹外发光
- 动态背景：Light Pillar 光柱动画
  用 CSS keyframes 实现多条竖向渐变光柱，opacity 和 transform 随机延迟动画
```

### A3. 极简白（企业 B 端）

```
帮我把 [组件/页面] 重新设计为极简企业风格：

设计规范：
- 白色背景，深灰文字 #1A1A1A
- 强调色：#0066FF（蓝）或 #10B981（绿），用于 CTA 和状态指示
- 间距系统：4px 基准，所有间距是 4 的倍数
- 卡片：白色 + 1px #E5E7EB 边框 + 4px 圆角，hover 时 box-shadow 加深
- 数据表格：斑马纹（偶数行 #F9FAFB），表头固定，支持列排序
```

---

## B. 微交互（几乎每个项目必加）

```
给 [项目路径] 的所有可交互元素添加微交互（Micro-interactions）：

1. 可点击元素 hover 效果
   - Scale: transform: scale(1.02)，transition: all 0.15s ease
   - 阴影加深：box-shadow 从 none → 0 4px 12px rgba(0,0,0,0.15)

2. 按钮点击反馈
   - Active 状态：scale(0.97) + brightness(0.9)
   - 加载中：spinner 替换文字（不要 disabled + 灰色，改成 loading 状态）

3. 链接/卡片 hover
   - 卡片整体微微上移：translateY(-2px)
   - 链接下划线从左到右展开（CSS clip-path 动画）

4. 表单 focus 态
   - 边框颜色渐变高亮（0.2s ease）
   - 取消 outline，改用 box-shadow: 0 0 0 3px rgba(品牌色, 0.2)

用 CSS transitions 实现，不引入新动画库。
```

---

## C. Toast 通知（替换 alert）

```
把项目里所有的 alert()、window.confirm() 替换为 Toast 通知系统：

Toast 规范（参考 Vercel 风格）：
- 容器：fixed bottom-right，z-index: 9999，gap: 8px，flex-col-reverse
- 样式：黑底白字 (#0A0A0A bg, #FFFFFF text)，圆角 8px，
  padding: 12px 16px，min-width: 280px，max-width: 420px
  box-shadow: 0 4px 12px rgba(0,0,0,0.3)
- 动画：从右侧 translateX(100%) 滑入，0.2s ease-out
- 消失：opacity 0 + translateY(8px)，2s 后自动
- 类型颜色：
  success: 左侧 3px 实线 #10B981
  error: 左侧 3px 实线 #EF4444
  info: 默认黑底无彩色线
- API: showToast(message, type='info', duration=3000)

同时把所有 window.confirm() 替换为行内确认（inline confirm），
避免浏览器弹窗打断流程。
```

---

## D. 表单体验（实时内联校验）

```
对 [表单组件] 实施实时内联校验：

规范：
- 触发时机：onBlur（失焦时）触发，不在 onChange 每次按键触发（减少焦虑感）
- 错误提示：字段下方红色小字（#EF4444，12px），
  带 ⚠ 图标，通过 CSS max-height 动画展开（0 → auto）
- 成功状态：输入框右侧绿色 ✓ 图标（不改边框颜色，太吵）
- 提交时：全量校验，第一个错误字段自动 focus
- 禁止：提交后才统一展示所有错误

校验规则参考（按需选）：
- 必填：失焦后空值 → "此项为必填"
- 邮箱：实时格式校验，不要过于严格（允许 a@b.c 格式）
- 手机：11位数字
- 密码：至少8位，含数字和字母，实时显示强度条
```

---

## E. 去 Emoji，换 Icon（必做）

```
扫描 [项目路径] 所有前端文件，把 UI 元素里的 emoji 全部替换为专业图标：

图标库（已在项目中安装或安装 lucide-react）：
- 常用映射：
  📊 → BarChart2 或 TrendingUp
  📝 → FileText 或 Edit3
  👤 → User 或 UserCircle
  ✅ → CheckCircle
  ❌ → XCircle 或 X
  ⚠️ → AlertTriangle
  🔍 → Search
  ➕ → Plus
  🗑️ → Trash2
  ✏️ → Edit2
  💾 → Save
  📤 → Upload
  📥 → Download
  🏠 → Home
  ⚙️ → Settings
  🔔 → Bell
  📅 → Calendar
  💬 → MessageCircle

规范：
- Icon 组件统一 size=16（行内）或 size=20（按钮里）
- 颜色继承父元素（currentColor），不硬编码颜色
- 有 tooltip 的 icon 加 title 属性做无障碍

只改 emoji，不改业务逻辑和数据流。
```

---

## F. 响应式 & 移动端适配

```
对 [项目路径] 进行响应式适配：

断点规范：
- Mobile: < 768px
- Tablet: 768-1024px
- Desktop: > 1024px

重点处理：
1. 导航栏：桌面端横向，移动端 hamburger 菜单（不要用 JS，用 CSS checkbox trick 或 details/summary）
2. 数据表格：移动端改为卡片列表（Table → Card List）
3. 双栏布局：桌面双栏，移动端单栏
4. 字体大小：桌面端 16px 基准，移动端 14px
5. 点击区域：移动端所有可点击元素最小 44x44px

用 Tailwind CSS 实现（如果项目用了的话），或纯 CSS media query。
```

---

## G. 加载态 & 空状态

```
为 [项目路径] 所有异步数据加载添加合适的状态处理：

1. 加载态（Skeleton）
   - 不要 spinner 转圈（除非全屏加载）
   - 用 Skeleton 骨架屏（灰色矩形，pulse 动画）
   - 骨架形状和真实内容一致

2. 空状态（Empty State）
   - 不要显示空白页面或 "No data"
   - 显示：插画（可用 SVG）+ 说明文字 + 操作引导按钮
   - 示例："还没有数据，点击 [创建第一个X] 开始"

3. 错误状态
   - 网络错误：显示重试按钮
   - 权限错误：说明原因，引导去登录或联系管理员
   - 数据错误：友好提示，不要 stack trace

4. 实现方式
   - 封装 AsyncWrapper 组件，props: loading / error / empty / children
   - 所有列表/详情页统一用 AsyncWrapper 包裹
```

---

## 组合使用示例

**新项目标准优化序列**（Codex 分 3 轮跑）：

```
第 1 轮：E（去 emoji）+ B（微交互）+ C（Toast）
第 2 轮：D（表单校验）+ G（加载/空/错误状态）
第 3 轮：A（设计风格统一）+ F（响应式）
```

每轮之间让 Claude Code 跑一遍测试，确认没有引入新 bug。
