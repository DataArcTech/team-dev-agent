# Agent 操作规范

## Claude Code vs Codex 选择逻辑

```
后端逻辑 / DB / API / 测试 / review → Claude Code
前端视觉 / 动效 / UI 美化         → Codex（效果明显更好）
前端骨架（跑通为主）              → Claude Code（快）
交互测试（Web）                   → Claude Code + browser/chrome-devtools
```

## 标准调用模板

### Claude Code（后台长任务）

```bash
nohup bash -c '
  cd /path/to/project
  claude --dangerously-skip-permissions --print "
    ## 任务
    [具体任务描述]

    ## 约束
    - 禁止 mock 数据，所有数据必须从真实 DB 读取
    - 禁止硬编码配置（API key、URL、用户数据）
    - 实现不了请明确说明，不要用假数据绕过
    - 完成后运行测试确认功能正常

    ## 完成标准
    [具体可验证的完成标准]
  " && openclaw system event --text "Done: [任务摘要]" --mode now
' > /tmp/claude_TASKNAME.log 2>&1 &
echo "PID: $! | log: /tmp/claude_TASKNAME.log"
```

### Codex（前端优化，需 PTY）

```bash
nohup bash -c '
  cd /path/to/project
  codex --yolo "
    ## 前端优化任务
    [具体描述，参考 frontend-prompts.md 里的标准 prompt]

    ## 约束
    - 禁止用 emoji 做 UI 元素，统一用 SVG/lucide/heroicons
    - 不改业务逻辑，只改视觉层
    - 不引入新的依赖（除非非常必要，先问）
  " && openclaw system event --text "Done: 前端优化完成" --mode now
' > /tmp/codex_TASKNAME.log 2>&1 &
echo "PID: $! | log: /tmp/codex_TASKNAME.log"
```

## 进程监控

**每 5 分钟检查一次**，用 `scripts/monitor_agent.sh`：

```bash
bash ~/.agents/skills/team-dev-agent/scripts/monitor_agent.sh /tmp/claude_TASKNAME.log TASKNAME
```

手动检查：
```bash
# 查看进度
tail -50 /tmp/claude_TASKNAME.log

# 查 PID 还在不在
kill -0 <PID> && echo "running" || echo "dead"

# 进程死了但 log 存在 → 读最后输出判断是正常结束还是崩溃
tail -100 /tmp/claude_TASKNAME.log
```

## Prompt 必须包含的禁令

每次给 Claude Code / Codex 的 prompt，末尾必须加：

```
## 铁律（不可违反）
1. 禁止 mock 数据 / 假数据 / hardcode 数值，所有数据从真实 DB 或 API 获取
2. 禁止极端简化（比如"删掉这个功能"来绕过 bug，要真正修复）
3. 如果某个需求无法实现，明确说"无法实现，原因是XXX"，不要扭曲实现
4. 禁止 console.log / print 调试语句遗留在生产代码里
5. 每次 commit 前跑一遍现有测试，不能引入新的失败
```

## 常见坑 & 对策

| 坑 | 现象 | 对策 |
|----|------|------|
| 极端思维 | bug 解法是"删掉这个功能" | prompt 里明确禁止，要求给 trade-off 分析再改 |
| 印度程序员综合症 | 需求做不到，用假数据绕 | 加铁律 3，同时 review 时跑 `scripts/review_hardcode.sh` |
| Agent 被 kill 无感知 | 进程挂了没人知道 | monitor_agent.sh 5分钟轮询 + 飞书通知 |
| Mock 数据永远不打通 | 跑起来没问题，真实场景全崩 | 阶段 5 专门做数据打通测试 |
| 前端 AI 味儿 | 到处是 emoji，渐变乱用 | Codex 优化阶段专用 prompt 强制去 |

## 并行任务管理

多个任务并行跑时，给每个任务起不同的 log 名称：

```bash
/tmp/claude_backend_api.log
/tmp/claude_db_migration.log
/tmp/codex_frontend_ui.log
```

批量查所有任务状态：
```bash
ls /tmp/claude_*.log /tmp/codex_*.log 2>/dev/null | while read f; do
  echo "=== $f ==="
  tail -3 "$f"
done
```
