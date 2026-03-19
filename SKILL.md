---
name: team-dev-agent
description: >
  AI-driven software development workflow for teams using Claude Code and Codex.
  Use when building or iterating on real products (web, mobile, B2B SaaS): starting
  a new project, implementing features, reviewing code, fixing bugs, or doing full-cycle
  development. Activates on: "帮我开发", "用claude code实现", "用codex做前端", "开始做这个项目",
  "帮我搭一个", "写代码", "开始开发", "build this", "implement", "开发一个".
  NOT for: simple one-liner edits, reading code only.
---

# Team Dev Agent

**核心目标**：做出真正可用的产品，不是 demo，不是 mock，不是写死的假数据。

## Agent 分工

| 任务 | Agent | 模式 |
|------|-------|------|
| 后端 / DB / API / 测试 / Review | Claude Code | `--dangerously-skip-permissions --print`，nohup |
| 前端骨架（跑通为主） | Claude Code | 同上 |
| **前端视觉优化** | **Codex** | `--yolo`，PTY=true，nohup |
| 交互测试（Web） | Claude Code + Chrome DevTools | browser 工具 |

## 调用模板（直接复用）

```bash
# Claude Code
nohup bash -c 'cd /path && claude --dangerously-skip-permissions --print "【任务】\n[描述]\n\n【铁律】\n禁止mock数据/硬编码，无法实现请明说，完成后跑测试" \
  && openclaw system event --text "Done: [摘要]" --mode now' \
  > /tmp/claude_TASK.log 2>&1 & echo "PID:$! log:/tmp/claude_TASK.log"

# Codex（前端视觉，需 PTY）
nohup bash -c 'cd /path && codex --yolo "[优化描述，参考 frontend-prompts.md]\n\n禁止用emoji做UI元素，只改视觉层不改业务逻辑" \
  && openclaw system event --text "Done: [摘要]" --mode now' \
  > /tmp/codex_TASK.log 2>&1 & echo "PID:$! log:/tmp/codex_TASK.log"
```

spawn 后每 5 分钟监控：`bash scripts/monitor_agent.sh /tmp/claude_TASK.log "任务名" $PID`

## 7 阶段流程（按顺序）

1. **架构** — 功能边界、技术栈、DB schema、分期计划 → `references/architecture.md`
2. **实现** — 后端优先，前后端打通，全程真实数据 → `references/workflow.md`
3. **前端优化** — Codex 做视觉升级，用标准 prompt → `references/frontend-prompts.md`
4. **质量关卡** — 第1轮 bug fix，第2轮去冗余+去硬编码 → `references/quality-gates.md`
5. **数据打通** — 前后端、DB、功能间、业务↔管理后台 → `references/quality-gates.md`
6. **边界测试** — 每轮一个重点（输入/权限/并发/数据量）→ `references/workflow.md`
7. **迭代** — 多角度 review（可维护/可扩展/性能/安全）→ `references/workflow.md`

## 快速诊断

| 现象 | 处理 |
|------|------|
| Agent 无声死亡 | `kill -0 $PID` 检查；死了看 log 最后 50 行 |
| 前端数据是假的 | DB 手改一条数据，刷新页面，确认变了 |
| 代码有硬编码 | `bash scripts/review_hardcode.sh /path` |
| 前端 AI 味儿 | 用 `frontend-prompts.md` E 节（去 emoji）+ B 节（微交互） |
| Bug 解法是"删功能" | 打回，要求给 trade-off 分析再改，加铁律 2 |
