# Agent 操作规范（深度参考）

> 调用模板在 SKILL.md 里。本文件覆盖：监控、并行管理、Prompt 工程、常见坑。

## 进程监控

```bash
# 单个任务监控（5分钟一次）
bash scripts/monitor_agent.sh /tmp/claude_TASK.log "任务名" $PID

# 批量查所有任务
ls /tmp/claude_*.log /tmp/codex_*.log 2>/dev/null | while read f; do
  echo "=== $f ===" && tail -3 "$f"
done

# 手动判断进程存活
kill -0 $PID 2>/dev/null && echo "running" || echo "dead"
```

进程死亡 → 读最后 100 行 log 判断：正常结束（有 Done/✅）还是崩溃（有 Error/Traceback）。

## 并行任务管理

多任务并行时，log 命名要能看出任务内容：

```
/tmp/claude_backend_api.log     # 后端 API
/tmp/claude_db_migration.log    # DB 迁移
/tmp/codex_frontend_polish.log  # 前端视觉
/tmp/claude_review_hardcode.log # 代码 review
```

> 并行上限建议 3 个。超过后 context 容易互相干扰，而且一旦出错难以定位。

## Prompt 工程：必须包含的禁令

每个给 Claude Code / Codex 的 prompt，末尾加：

```
## 铁律（不可违反）
1. 禁止 mock/假数据/hardcode 数值，所有数据从真实 DB 或 API 获取
2. 禁止极端简化（删功能来绕过 bug）——要真正修复，给出 trade-off 分析
3. 无法实现请明确说"无法实现，原因是XXX"，不要扭曲实现
4. 禁止 console.log/print 调试语句遗留
5. commit 前跑一遍现有测试，不能引入新失败
```

## Prompt 工程：完成标准要可验证

模糊完成标准（❌）：
```
实现用户管理功能
```

好的完成标准（✅）：
```
## 完成标准（全部满足才算完成）
- [ ] GET /api/users 返回真实 DB 数据（curl 测试）
- [ ] POST /api/users 创建后 DB 确实有新记录
- [ ] 未登录访问返回 401
- [ ] tsc --noEmit 零错误
- [ ] 所有现有测试通过
```

## 常见坑 & 对策

| 坑 | 现象 | 对策 |
|----|------|------|
| 极端思维 | "删掉这个功能"来修 bug | 铁律 2；要求给 trade-off 再改 |
| 印度程序员综合症 | 需求做不到，用假数据/硬编码绕过 | 铁律 1+3；事后跑 `review_hardcode.sh` |
| Agent 无声死亡 | 进程挂了没通知 | monitor_agent.sh 轮询 + 飞书通知 |
| Mock 永远不打通 | 演示正常，真实场景全崩 | 阶段 5 专项，手动验 DB 数据流 |
| 前端 AI 味儿 | emoji 遍地，渐变乱用 | Codex + frontend-prompts.md E+B 节 |
| 长程任务跑偏 | 100行后已经在做别的事 | 任务拆小（每次不超过 1 个功能模块）；中间检查点 |
| 引入新 bug | 改 A 坏了 B | 每次修改后跑完整测试；修改范围写在 prompt 里 |

## 任务拆分原则

长任务（超过 2 小时）必须拆：

```
❌ 一个 prompt："实现完整的用户权限管理系统"

✅ 拆成 4 个：
  1. "实现 User / Role / Permission 三张表 + seed 数据"
  2. "实现 JWT 登录/登出 API + 鉴权中间件"
  3. "实现用户 CRUD API（带权限校验）"
  4. "实现前端登录页 + 路由守卫"
```

每个子任务完成后验收，再开下一个。

## 重跑失败任务

```bash
# 查看失败原因
tail -100 /tmp/claude_TASK.log | grep -i "error\|exception\|failed"

# 重跑时加上下文
nohup bash -c 'cd /path && claude --dangerously-skip-permissions --print "
  上次任务失败了，错误信息：[从 log 里复制]
  请从失败点继续，不要重新开始整个任务。
  具体要继续做的是：[剩余任务]
  [铁律]
" && openclaw system event --text "Done: 重跑完成" --mode now' \
> /tmp/claude_TASK_retry.log 2>&1 & echo "PID:$!"
```
