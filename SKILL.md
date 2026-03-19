---
name: team-dev-agent
description: >
  AI-driven software development workflow for teams. Use when building or iterating on real products
  (web, mobile, B2B SaaS) using Claude Code and Codex as coding agents. Covers full lifecycle:
  architecture → implementation → frontend polish → quality gates → data integration testing →
  iterative review. Activates on phrases like "帮我开发", "用claude code实现", "用codex做前端",
  "开始做这个项目", "帮我搭一个", "写代码", "开始开发", "code up", "build this", "implement".
  NOT for simple one-liner edits or reading code.
---

# Team Dev Agent

**目标**：用 AI coding agent 做出真正可用的产品，不是 demo，不是假数据，不是写死的 mock。

## 核心分工

| 任务 | Agent | 调用模式 |
|------|-------|---------|
| 后端 / DB schema / API | Claude Code | `--dangerously-skip-permissions --print` |
| 前端骨架实现 | Claude Code | 同上 |
| **前端视觉优化** | **Codex** | `--yolo`，PTY=true |
| Bug fix / 去冗余 review | Claude Code | 同上 |
| 交互测试（Web端）| Claude Code + Chrome DevTools | browser 工具辅助 |

## 标准开发流程

按顺序执行，每阶段完成后才进入下一阶段。详见 `references/workflow.md`。

**阶段 1 — 架构设计**
先问清楚，再动手。包括功能拆解、技术栈选型、DB schema 草图、分期开发计划。
→ 详见 `references/architecture.md`

**阶段 2 — Claude Code 实现**
后端优先，前后端打通，数据真实流动。禁止 mock 数据。
→ 详见 `references/workflow.md`

**阶段 3 — Codex 前端优化**
骨架跑通后，交给 Codex 做视觉升级。
→ 直接用 `references/frontend-prompts.md` 里的标准 prompt

**阶段 4 — 质量关卡（2轮）**
第1轮：bug fix；第2轮：去冗余、去硬编码。
→ 详见 `references/quality-gates.md`

**阶段 5 — 数据打通测试**
前后端连通、DB真实数据、功能间联动、业务+管理后台打通。
→ 详见 `references/quality-gates.md`

**阶段 6 — 边界/交互测试**
每轮一个测试重点，Chrome DevTools 辅助交互自动化。

**阶段 7 — 迭代**
多角度 review（可维护性 / 可扩展性 / 性能 / 安全）。

## Agent 调用铁律（必读）

```bash
# Claude Code 正确姿势（nohup 防 SIGHUP，&& 串联完成通知）
nohup bash -c 'cd /path/to/project && \
  claude --dangerously-skip-permissions --print "任务描述..." \
  && openclaw system event --text "Done: 任务摘要" --mode now' \
  > /tmp/claude_task.log 2>&1 &
echo "PID: $! | log: /tmp/claude_task.log"

# Codex 正确姿势
nohup bash -c 'cd /path/to/project && \
  codex --yolo "任务描述..." \
  && openclaw system event --text "Done: 任务摘要" --mode now' \
  > /tmp/codex_task.log 2>&1 &
echo "PID: $! | log: /tmp/codex_task.log"
```

**禁止**：
- `claude -p '...' &`（exec session 结束 → SIGHUP 杀进程）
- 在 prompt 末尾写 "When done run openclaw..."（不会真正执行）
- Claude Code 用 PTY 模式（用 `--print` 替代）

**监控**：spawn 后每 5 分钟检查一次进程状态。用 `scripts/monitor_agent.sh`。

## 快速参考

- **Agent 调用详解** → `references/agent-ops.md`
- **完整工作流** → `references/workflow.md`
- **前端优化 prompt** → `references/frontend-prompts.md`
- **质量门控** → `references/quality-gates.md`
- **架构决策** → `references/architecture.md`
