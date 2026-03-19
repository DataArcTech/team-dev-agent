# team-dev-agent

**用 AI Coding Agent 做出真正可用的产品，而不是 Demo。**

这是一个 [OpenClaw](https://openclaw.ai) Agent Skill，为团队提供完整的 AI 辅助软件开发工作流。把实际项目中踩过的坑、总结的最佳实践、和常用的 Prompt 模板全部沉淀下来，让每个团队成员都能高效地指挥 Claude Code 和 Codex 协作开发真实产品。

---

## 为什么需要这个 Skill？

| 问题 | 表现 |
|------|------|
| **极端解法** | Bug 的解决方案是"把这个功能删掉" |
| **假数据永远不打通** | 所有页面跑起来都是 mock，没有真实数据流 |
| **印度程序员综合症** | 需求做不到，用硬编码绕过，表面正常，实际是 demo |
| **AI 味儿浓** | 到处是 emoji，渐变乱用，不像正经产品 |
| **Agent 无声死亡** | claude/codex 进程崩了，没有任何通知，傻等 |
| **长程任务跑偏** | 任务越来越偏，没有阶段性质量检查 |

---

## 核心分工

```
后端 / DB / API / 测试 / Review  →  Claude Code  (--dangerously-skip-permissions --print)
前端骨架（跑通为主）             →  Claude Code
前端视觉优化（效果更好）         →  Codex        (--yolo, PTY)
交互 / UI 自动化测试             →  Claude Code + Chrome DevTools
```

> Claude Code 擅长逻辑实现，Codex 做前端视觉效果明显更好。两者协同分工是关键。

---

## 调用模板

```bash
# Claude Code（后台长任务，防 SIGHUP 杀进程）
nohup bash -c 'cd /path/to/project && \
  claude --dangerously-skip-permissions --print "
    ## 任务
    [具体描述]

    ## 铁律
    - 禁止 mock 数据/硬编码，所有数据从真实 DB 获取
    - 无法实现请明确说明，不要用假数据绕过
    - 完成后跑测试确认全部通过
  " && openclaw system event --text "Done: [摘要]" --mode now' \
  > /tmp/claude_TASK.log 2>&1 &
echo "PID: $! | tail -f /tmp/claude_TASK.log"

# Codex（前端视觉，需 PTY）
nohup bash -c 'cd /path/to/project && \
  codex --yolo "[优化描述]\n\n禁止用 emoji 做 UI 元素，只改视觉层不改业务逻辑" \
  && openclaw system event --text "Done: 前端优化完成" --mode now' \
  > /tmp/codex_TASK.log 2>&1 &
```

> ⚠️ 禁止用 `claude -p '...' &`（exec session 结束 → SIGHUP 杀进程）  
> ⚠️ 禁止在 prompt 末尾写 "When done run..."（不会真正执行）

---

## 7 阶段开发流程

### 1. 架构设计（先问再动）

写第一行代码前输出 `ARCHITECTURE.md`，包含：功能清单（按优先级）、技术栈选型 + 理由、DB 表草图、P1/P2/P3 分期计划。

### 2. Claude Code 实现

**顺序**：DB schema → API → 业务逻辑 → Auth → 前端骨架 → 联调

关键：前端 API URL 用相对路径，环境变量通过 `.env` 传入，零 hardcode。

```typescript
// next.config.ts — 防止写死 localhost
async rewrites() {
  return [{
    source: '/api/:path*',
    destination: `${process.env.BACKEND_URL || 'http://localhost:8000'}/api/:path*`,
  }]
}
```

### 3. Codex 前端视觉优化

骨架跑通后才进此阶段。**只改视觉层，不动业务逻辑。**

推荐顺序：去 emoji→icon → Toast 替换 alert → 微交互 → 表单实时校验 → 加载/空/错误状态 → 整体风格统一

详细 prompt → [`references/frontend-prompts.md`](references/frontend-prompts.md)

### 4. 质量关卡（2 轮）

**第 1 轮 — Bug Fix**：跑所有测试、修 API 错误处理、修前端异常处理，全部通过后结束。

**第 2 轮 — 去冗余 + 去硬编码**：

```bash
# 先扫描
bash scripts/review_hardcode.sh /path/to/project

# 然后让 Claude Code 处理：
# - 所有 URL/IP/端口 → .env
# - mock/test 数据 → 真实 DB
# - 删除 console.log / print / 未用 import
# - 单函数 ≤ 50 行，合并重复逻辑
```

### 5. 数据打通测试（最重要）

```bash
# 验证数据流是真实的：在 DB 改一条数据，刷新页面，确认变了
sqlite3 data.db "UPDATE users SET name='验证改名' WHERE id=1"
# → 刷新页面 → 确认显示"验证改名"
```

检查清单：
- [ ] 前端展示数据来自真实 DB（不是写死的）
- [ ] 表单提交后 DB 确实有变化
- [ ] 功能间数据联动正确
- [ ] 管理后台改配置 → 业务系统立即生效

### 6. 边界 & 交互测试

每轮一个测试重点：

| 轮次 | 重点 | 典型 case |
|------|------|---------|
| 1 | 输入边界 | 空值、超长字符串、SQL 注入、特殊字符 |
| 2 | 权限边界 | 未登录访问、越权、跨用户数据 |
| 3 | 并发 & 异常 | 快速重复提交、网络断开、500 错误 |
| 4 | 数据边界 | 0 条、1000+ 条、分页首/末页 |

Web 端用 Chrome DevTools 做自动化交互测试（导航 → 点击 → 填表 → 验证 Network 请求 → 检查 Console）。

### 7. 迭代 Review

每次从一个角度 review，不要同时改多个：可维护性 / 可扩展性 / 性能 / 安全。

---

## 前端 UI Prompt 库

[`references/frontend-prompts.md`](references/frontend-prompts.md) 收录 6 大类标准 prompt，直接喂给 Codex：

| 类别 | 效果 |
|------|------|
| **A. 设计风格** | 玻璃拟态+莫兰迪色、深色科技感看板、极简企业白 |
| **B. 微交互** | Hover scale + 阴影加深、Active 反馈、卡片上移 |
| **C. Toast** | Vercel 风格（黑底白字圆角），替换所有 alert() |
| **D. 表单校验** | onBlur 实时内联校验，错误提示字段下方 |
| **E. 去 emoji** | 全部替换为 lucide-react icon，含映射表 |
| **F. 响应式** | Mobile/Tablet/Desktop 断点，表格→卡片列表 |
| **G. 状态处理** | Skeleton 骨架屏、Empty State、错误 + 重试 |

参考资源：[uipocket.com](https://uipocket.com/) · [component.gallery](https://component.gallery/)

---

## 自动化脚本

### `scripts/monitor_agent.sh` — 进程监控

```bash
bash scripts/monitor_agent.sh /tmp/claude_task.log "任务名" $PID [飞书open_id]
```

- 进程存活 → 打印最新进度
- 进程死亡且未完成 → 打印最后 50 行 + 可选飞书通知
- 5 分钟内日志无更新 → 警告可能卡住

### `scripts/review_hardcode.sh` — 硬编码扫描

```bash
bash scripts/review_hardcode.sh /path/to/project
```

按 HIGH / MEDIUM / LOW 三档输出，含文件名和行号：

```
[HIGH] Mock / Fake 数据
  src/api/users.py:42: return {"name": "测试用户", "id": "abc123"}

[HIGH] 硬编码 localhost / IP
  web/src/lib/api.ts:8: const BASE = "http://localhost:8000"

⚠️  发现 2 类硬编码问题，请修复后再提交
```

---

## 技术栈选型

| 场景 | 后端 | 前端 | DB |
|------|------|------|----|
| B 端 Web 管理系统 | FastAPI | Next.js + TypeScript | PostgreSQL |
| 快速原型 | FastAPI | Next.js | SQLite → PostgreSQL |
| Node.js 团队 | Express + Prisma | React + Vite | PostgreSQL |
| 移动端 H5 | FastAPI | Next.js（响应式） | PostgreSQL |
| 微信小程序 | FastAPI | 原生 / Taro | MySQL |

**DB 设计原则**：
- 原型期 SQLite，生产前迁移 PostgreSQL
- 禁止用 JSON 列存复杂结构（无法索引）
- 多租户 B 端：每张业务表加 `tenant_id`，中间件自动注入
- 所有配置通过 pydantic `BaseSettings` 从 `.env` 读取，代码里零 hardcode

---

## 质量门控 Checklist

说"完成"之前，以下条件**全部满足**：

- [ ] 所有测试通过（无跳过、无 mock 依赖）
- [ ] `review_hardcode.sh` 扫描：0 个 HIGH 问题
- [ ] DB 手改数据后前端确认展示变了
- [ ] 表单提交后 DB 确实有变化
- [ ] 无 `console.log` / `print` 调试遗留
- [ ] TypeScript：`tsc --noEmit` 零错误
- [ ] 所有 API 端点有权限校验（未登录返回 401）

---

## Skill 文件结构

```
team-dev-agent/
├── SKILL.md                      # Skill 入口（OpenClaw 自动加载）
├── references/
│   ├── workflow.md               # 7 阶段流程 + 验收标准 + 测试 case
│   ├── agent-ops.md              # 进程监控、并行管理、Prompt 工程、重跑模式
│   ├── frontend-prompts.md       # 前端 UI 优化 Prompt 库（7 大类）
│   ├── quality-gates.md          # 质量门控：硬编码检查、数据打通、安全检查
│   └── architecture.md           # 技术栈选型、项目结构模板、GitHub 协作规范
└── scripts/
    ├── monitor_agent.sh          # 监控 claude/codex 进程，死亡时可飞书通知
    └── review_hardcode.sh        # 扫描硬编码、mock 数据、调试遗留
```

---

## 安装

```bash
# Git Clone（推荐，可跟进更新）
git clone https://github.com/DataArcTech/team-dev-agent ~/.agents/skills/team-dev-agent
```

**依赖**：
- [OpenClaw](https://openclaw.ai)
- Claude Code：`npm install -g @anthropic-ai/claude-code`
- Codex（可选，前端优化用）：`npm install -g @openai/codex`

---

## 核心经验

1. **nohup + && 是铁律**：`claude --print` 不执行 prompt 里的 shell 命令，通知必须用 `&&` 串联
2. **后端先行**：骨架不跑通，前端做得再漂亮也是浪费
3. **Codex 做前端更好看**：Claude Code 逻辑强，Codex 审美强，别搞反
4. **Mock 数据是毒药**：宁可慢，第一天就接真实 DB
5. **任务拆小**：单次 prompt 不超过一个功能模块，长任务必定跑偏
6. **5 分钟监控**：Agent 可能无声死亡，不监控就是在赌
7. **每次改动后跑测试**：不要等"全做完再测"，那时候 bug 叠 bug

---

## License

MIT © [DataArc](https://dataarctech.com)
