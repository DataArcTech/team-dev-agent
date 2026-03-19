# 质量门控

## 铁律：什么时候可以说"完成"

以下条件**全部满足**才算完成，缺一不可：

- [ ] 所有测试通过（无跳过、无 mock 依赖）
- [ ] 没有 hardcoded 数据（跑 `scripts/review_hardcode.sh` 验证）
- [ ] 前端展示的数据来自真实 DB（不是写死的）
- [ ] 表单提交后 DB 确实有变化（手动验证一次）
- [ ] 没有 console.log / print 遗留
- [ ] 没有未处理的 Promise rejection / 异常

---

## 去硬编码检查

**常见硬编码类型**（优先级从高到低）：

| 类型 | 例子 | 正确做法 |
|------|------|---------|
| 用户数据 | `user_id = "abc123"` | 从 session/token 读 |
| API Key | `key = "sk-xxx"` | 环境变量 |
| URL/IP | `"http://localhost:8000"` | 环境变量 / 相对路径 |
| 业务数值 | `quota = 1000` | DB 配置表 |
| Mock 数据 | `return {"name": "测试用户"}` | 真实 DB 查询 |
| 测试账户 | `if user == "admin":` | 角色权限表 |

**扫描命令**（也可运行 `scripts/review_hardcode.sh`）：

```bash
# 扫描常见硬编码
grep -rn "localhost" --include="*.ts" --include="*.tsx" --include="*.py" .
grep -rn "127.0.0.1" --include="*.ts" --include="*.tsx" --include="*.py" .
grep -rn "hardcode\|mock\|fake\|dummy\|test_user\|admin123" --include="*.py" --include="*.ts" . -i
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.py" --include="*.ts" .
```

---

## 数据打通验证清单

每个功能上线前跑一遍：

### 前后端打通

```bash
# 1. 列出所有 API 端点
curl http://localhost:8000/openapi.json | python3 -m json.tool | grep '"path"'

# 2. 对每个端点测试真实数据
curl -X GET http://localhost:8000/api/users \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# 3. 写入测试
curl -X POST http://localhost:8000/api/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "真实测试数据", "value": 42}'
```

### DB 数据流验证

```python
# 验证脚本模板（给 Claude Code 用）
# 1. 通过 API 创建一条数据
# 2. 直接查 DB 确认存在
# 3. 通过 API 删除
# 4. 直接查 DB 确认消失

import sqlite3, requests

BASE = "http://localhost:8000"
# Step 1: 创建
r = requests.post(f"{BASE}/api/items", json={"name": "验证数据"})
item_id = r.json()["id"]

# Step 2: 查 DB
conn = sqlite3.connect("data.db")
row = conn.execute("SELECT * FROM items WHERE id=?", (item_id,)).fetchone()
assert row is not None, "DB 里没有这条数据！"

# Step 3: 删除
requests.delete(f"{BASE}/api/items/{item_id}")

# Step 4: 确认删除
row = conn.execute("SELECT * FROM items WHERE id=?", (item_id,)).fetchone()
assert row is None, "DB 里数据没有被删除！"

print("✅ 数据流验证通过")
```

---

## 代码质量检查

### Python 后端

```bash
# 类型检查
mypy . --ignore-missing-imports

# 格式
black . --check
isort . --check-only

# 安全扫描
pip install bandit && bandit -r . -ll
```

### TypeScript / React 前端

```bash
# 类型检查（必须 0 错误）
npx tsc --noEmit

# Lint
npx eslint . --ext .ts,.tsx

# 测试
npx jest --coverage
```

---

## 可维护性指标

Claude Code review 时检查：

| 指标 | 阈值 | 检查方式 |
|------|------|---------|
| 单函数长度 | ≤ 50 行 | 代码 review |
| 文件长度 | ≤ 300 行 | `wc -l` |
| 循环嵌套 | ≤ 3 层 | 代码 review |
| 重复代码 | 0 块 | `jscpd` 扫描 |
| 魔法数字 | 0 个 | 全提取为常量 |

---

## 安全检查

最低门槛（每个项目必检）：

- [ ] 所有 API 端点有权限校验（未登录返回 401）
- [ ] 用户只能访问自己的数据（不能越权查他人）
- [ ] SQL 查询用参数化（不拼字符串）
- [ ] 敏感字段（密码、token）不出现在 API 响应里
- [ ] 上传文件有类型和大小限制
- [ ] CORS 配置不是 `*`（生产环境）

---

## 常见 AI 代码坑（专项 review）

**给 Claude Code 的 review prompt**：

```
对 [项目路径] 进行 AI 代码坑专项扫描，重点检查：

1. 极端简化
   - 有没有用"删掉功能"来绕过 bug 的情况？
   - 有没有"只在特定条件下工作"的隐藏假设？

2. 假设性实现
   - 有没有函数签名正确但实现是假的（返回固定值）？
   - 有没有 TODO 留在生产代码里没实现？

3. 脆弱逻辑
   - 有没有依赖特定测试数据才能跑通的逻辑？
   - 有没有 hardcoded 的 case（if name == "测试用户"）？

4. 边界忽略
   - 空列表 / null / undefined 有没有处理？
   - 并发操作有没有竞态条件？

发现后直接修复，不只是列出来。
```
