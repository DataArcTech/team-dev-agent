# 🛠️ team-dev-agent

**用 AI Coding Agent 做出真正可用的产品，而不是 Demo。**

这是一个 [OpenClaw](https://openclaw.ai) Agent Skill，为团队提供完整的 AI 辅助软件开发工作流。它把我们在实际项目中踩过的坑、总结的最佳实践、和常用的 prompt 模板全部沉淀下来，让每个团队成员都能高效地指挥 Claude Code 和 Codex 协作开发。

---

## 为什么需要这个 Skill？

用 AI coding agent 开发项目时，我们反复遇到这些问题：

| 问题 | 表现 |
|------|------|
| **极端解法** | bug 的解决方案是"把这个功能删掉" |
| **假数据永远不打通** | 所有页面跑起来都是 mock，没有真实数据流 |
| **印度程序员综合症** | 需求做不到，用硬编码绕过，表面正常，实际是 demo |
| **AI 味儿浓** | 到处是 emoji，渐变乱用，不像正经产品 |
| **Agent 无声死亡** | claude/codex 进程崩了，没有任何通知，傻等 |
| **长程任务跑偏** | 任务越来越偏，没有阶段性质量检查 |

这个 Skill 通过标准化工作流、固化 prompt 模板、自动化脚本，系统性解决以上问题。

---

## 核心分工

```
后端 / DB / API / 测试 / Review  →  Claude Code
前端骨架（跑通为主）             →  Claude Code
前端视觉优化（效果更好）         →  Codex
交互/UI 自动化测试               →  Claude Code + Chrome DevTools
```

> **经验**：Claude Code 擅长逻辑实现，但前端审美一般；Codex 做前端视觉效果明显更好。两者协同分工是关键。

---

## Skill 结构

```
team-dev-agent/
├── SKILL.md                      # Skill 入口，OpenClaw 自动加载
├── references/
│   ├── workflow.md               # 7 阶段完整开发流程 + Prompt 模板
│   ├── agent-ops.md              # Agent 调用规范、监控、常见坑
│   ├── frontend-prompts.md       # 前端 UI 优化 Prompt 库（6 大类）
│   ├── quality-gates.md          # 质量门控：去硬编码、数据打通、安全检查
│   └── architecture.md           # 技术栈选型、项目结构、GitHub 协作规范
└── scripts/
    ├── monitor_agent.sh          # 监控 claude/codex 进程，死亡时飞书通知
    └── review_hardcode.sh        # 扫描代码中的硬编码、mock 数据、调试遗留
```

---

## 7 阶段开发工作流

### 阶段 1 — 架构设计（先问再动）

在写第一行代码之前，先明确：功能边界、技术栈选型、DB schema 草图、分期开发计划（P1/P2/P3）。

输出一份 `ARCHITECTURE.md`，所有人对齐后再开工。

### 阶段 2 — Claude Code 实现

后端优先，前后端打通，数据真实流动。核心原则：

```bash
# 正确的后台任务调用姿势（nohup 防止 SIGHUP 杀进程）
nohup bash -c '
  cd /path/to/project
  claude --dangerously-skip-permissions --print "
    ## 任务
    实现用户管理 API（CRUD + JWT Auth）

    ## 铁律
    - 禁止 mock 数据，所有数据从真实 DB 读取
    - 实现不了请明确说明，不要用假数据绕过
    - 完成后跑测试确认全部通过
  " && openclaw system event --text "Done: 后端 API 实现完成" --mode now
' > /tmp/claude_backend.log 2>&1 &
echo "PID: $! | tail -f /tmp/claude_backend.log"
```

> ⚠️ **禁止**：`claude -p '...' &`（exec session 结束 → SIGHUP 杀进程）  
> ⚠️ **禁止**：在 prompt 末尾写 "When done run..."（不会真正执行）

### 阶段 3 — Codex 前端视觉优化

骨架跑通后，交给 Codex 做视觉升级。不改业务逻辑，只改视觉层。

```bash
nohup bash -c '
  cd /path/to/project
  codex --yolo "
    把所有 UI 元素里的 emoji 替换为 lucide-react 图标；
    给所有可点击元素加 hover scale(1.02) + 阴影加深微交互；
    把 alert() 全部替换为 Vercel 风格 Toast（黑底白字圆角）。
    不改业务逻辑，只改视觉层。
  " && openclaw system event --text "Done: 前端视觉优化完成" --mode now
' > /tmp/codex_ui.log 2>&1 &
```

### 阶段 4 — 质量关卡（2 轮 Review）

**第 1 轮 - Bug Fix**：运行测试、检查 API 错误处理、前端异常处理，修复所有 bug。

**第 2 轮 - 去冗余 + 去硬编码**：扫描 hardcode、删除死代码、合并重复逻辑、去掉调试语句。

```bash
# 快速扫描硬编码
bash ~/.agents/skills/team-dev-agent/scripts/review_hardcode.sh /path/to/project
```

### 阶段 5 — 数据打通测试

**这是最重要的阶段**，专门验证"不是 demo"。

- 前端展示的数据来自真实 DB（在 DB 改一条数据，刷新页面确认变了）
- 表单提交后 DB 确实有变化（不只是前端假装成功）
- 不同功能之间的数据联动（A 功能的操作影响 B 功能的数据）
- 业务系统 ↔ 管理后台数据打通

### 阶段 6 — 边界 & 交互测试

每轮一个测试重点，给 Claude Code 明确的 case 清单：

```
第 1 轮 — 输入边界（空值、超长、特殊字符、SQL 注入）
第 2 轮 — 权限边界（未登录、越权、跨用户数据）
第 3 轮 — 并发 & 异常（快速重复提交、网络断开、500 错误）
第 4 轮 — 数据边界（0 条、1000+ 条、分页边界）
```

Web 端可结合 Chrome DevTools 实现自动化交互测试（点击、填表、验证 Network 请求）。

### 阶段 7 — 迭代 Review

每次从一个角度 review，不要同时改太多：

```
可维护性 → 找出耦合度高、难以修改的模块
可扩展性 → 如果要加新功能，改动范围合理吗
性能     → N+1 查询、不必要的重渲染
安全     → SQL 注入、XSS、越权访问
```

---

## 前端 UI Prompt 库（精选）

`references/frontend-prompts.md` 收录了 6 大类常用 UI 设计 prompt，可直接喂给 Codex：

### A. 设计风格基调

**玻璃拟态 + 莫兰迪色系**（适合数据类产品）
```
帮我把页面重新设计为玻璃拟态（Glassmorphism）风格：
- 色系：莫兰迪（低饱和度、高级感）
  主色 #9E9E9E / 辅色 #B5C4B1 / 强调 #C4A882
- 卡片：backdrop-filter: blur(12px) + rgba(255,255,255,0.08) 背景
- 浮窗：Glassmorphism + 叠加淡白色噪点纹理
```

**深色科技感**（适合数据看板）
```
深黑背景 #0A0B0E + 紫→蓝渐变品牌色 #A855F7→#3B82F6
右侧悬浮式数据看板，超大金额数值 + 斜纹背景柱状图
峰值柱体带霓虹外发光效果
Light Pillar 动态背景动画
```

### B. 微交互（几乎每个项目必加）
```
给所有可点击元素添加微交互：
- Hover: transform scale(1.02) + box-shadow 加深，transition 0.15s ease
- Active: scale(0.97) + brightness(0.9)
- 卡片 Hover: translateY(-2px) 微微上移
- 表单 Focus: box-shadow: 0 0 0 3px rgba(品牌色, 0.2)，取消 outline
```

### C. Toast 通知（替换 alert）
```
Vercel 风格 Toast：黑底 #0A0A0A + 白字 + 圆角 8px
从右侧滑入，2秒后淡出；success 左侧绿线，error 左侧红线
API: showToast(message, type='info', duration=3000)
```

### D. 表单实时内联校验
```
onBlur 触发（不是 onChange），错误提示字段下方红色小字
成功状态右侧绿色 ✓，提交时全量校验 + 首个错误自动 focus
```

### E. 去 Emoji，换专业 Icon（必做）
```
扫描所有前端文件，把 UI emoji 全部替换为 lucide-react 图标：
📊→BarChart2, 📝→FileText, 👤→User, ✅→CheckCircle,
⚠️→AlertTriangle, 🔍→Search, ➕→Plus, 🗑️→Trash2
Icon size=16（行内）/ size=20（按钮），颜色继承 currentColor
```

### F. 响应式适配
```
断点：Mobile <768px / Tablet 768-1024px / Desktop >1024px
表格移动端改卡片列表；导航栏移动端 hamburger；
可点击区域最小 44x44px
```

> 参考资源：[uipocket.com](https://uipocket.com/) · [component.gallery](https://component.gallery/)

---

## 自动化脚本

### monitor_agent.sh — 进程监控

```bash
# 每 5 分钟检查一次 claude/codex 进程
bash scripts/monitor_agent.sh /tmp/claude_task.log "后端开发" 12345

# 进程死亡时自动发飞书通知（需配置 open_id）
bash scripts/monitor_agent.sh /tmp/claude_task.log "任务名" 12345 ou_xxx
```

输出示例：
```
[2026-03-19 18:00:00] 任务: 后端开发 | 状态: running
--- 最新进度（最后10行）---
Creating users table...
Adding JWT middleware...
Running tests: 12/12 passed ✅
```

### review_hardcode.sh — 硬编码扫描

```bash
bash scripts/review_hardcode.sh /path/to/project
```

输出示例：
```
[HIGH] Mock / Fake 数据
  src/api/users.py:42: return {"name": "测试用户", "id": "abc123"}

[HIGH] 硬编码 localhost / IP  
  web/src/lib/api.ts:8: const BASE = "http://localhost:8000"

[MEDIUM] TODO / FIXME 遗留
  src/services/payment.py:156: # TODO: 接真实支付接口

⚠️  发现 3 类硬编码问题，请修复后再提交
```

---

## 技术栈选型参考

| 场景 | 后端 | 前端 | DB |
|------|------|------|----|
| B 端 Web 管理系统 | FastAPI | Next.js + TypeScript | PostgreSQL |
| 原型快速验证 | FastAPI | Next.js | SQLite → PostgreSQL |
| Node.js 团队 | Express + Prisma | React + Vite | PostgreSQL |
| 移动端 H5 | FastAPI | Next.js（响应式） | PostgreSQL |
| 微信小程序 | FastAPI / Flask | 原生 / Taro | MySQL |

**DB 设计原则**：
- 原型期用 SQLite（零配置），生产前迁移 PostgreSQL
- 禁止用 JSON 列存复杂结构（无法索引、难以查询）
- 多租户 B 端：每张业务表加 `tenant_id`，中间件自动注入

**环境变量规范**（禁止 hardcode）：
```python
# core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    openrouter_api_key: str = ""

    class Config:
        env_file = ".env"
```

---

## 质量门控

说"完成"之前，以下条件**全部满足**：

- [ ] 所有测试通过（无跳过、无 mock 依赖）
- [ ] `review_hardcode.sh` 扫描结果：0 个 HIGH 问题
- [ ] 前端展示数据来自真实 DB（在 DB 手改一条，刷新确认变了）
- [ ] 表单提交后 DB 确实有变化
- [ ] 无 `console.log` / `print` 调试遗留
- [ ] TypeScript：`tsc --noEmit` 零错误
- [ ] 所有 API 端点有权限校验（未登录返回 401）

---

## 安装

### 方式一：Git Clone

```bash
git clone https://github.com/DataArcTech/team-dev-agent ~/.agents/skills/team-dev-agent
```

### 方式二：下载 .skill 文件

下载 [team-dev-agent.skill](https://github.com/DataArcTech/team-dev-agent/releases) 后，通过 OpenClaw 安装。

### 要求

- [OpenClaw](https://openclaw.ai) Agent 环境
- Claude Code CLI：`npm install -g @anthropic-ai/claude-code`
- Codex CLI：`npm install -g @openai/codex`（可选，前端优化用）

---

## 团队协作

```bash
# 团队成员 Clone 后
cp .env.example .env          # 填入自己的配置
pip install -r requirements.txt  # 或 uv install
npm install                   # 前端依赖

# 分支规范
feat/feature-name   # 新功能
fix/bug-description # bug 修复
refactor/module     # 重构

# Commit 规范
feat: 添加用户权限管理模块
fix: 修复分页在空数据时的崩溃
refactor: 抽取通用 API client，去除重复代码
```

---

## 核心经验总结

> **不要让 AI 做演示，要让 AI 做产品。**

1. **nohup + && 是铁律**：`claude --print` 不执行 prompt 里的 shell 命令，通知必须用 `&&` 串联
2. **后端先行**：骨架不跑通，前端做得再漂亮也是浪费
3. **Codex 做前端更好看**：Claude Code 逻辑强，Codex 审美强，分工别搞反
4. **Mock 数据是毒药**：宁可慢，也要从第一天就接真实 DB
5. **5 分钟监控一次**：Agent 可能无声死亡，不监控就是在赌
6. **每次改动后跑测试**：不要等到"全做完再测"，那时候 bug 叠 bug

---

## License

MIT © [DataArc](https://dataarctech.com)
