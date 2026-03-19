# 完整开发工作流

## 阶段 1：架构设计

**在写第一行代码前确认**（输出 `ARCHITECTURE.md`）：

```
功能层面
- 核心功能 & MVP 边界
- 用户角色 & 操作路径
- 权限隔离需求

技术层面
- 平台：Web / 移动端 / 小程序
- 后端：FastAPI / Express / Django（基于需求选，不固定）
- 前端：Next.js / React / Vue / 微信原生
- DB：SQLite（原型）→ PostgreSQL（生产）
- 外部 API / 第三方服务

工程层面
- 单体 vs 微服务（原型期统一单体）
- 是否需要管理后台
- 部署目标：本地 / 服务器 / 云
```

`ARCHITECTURE.md` 包含：功能清单（按优先级）、技术栈 + 理由、DB 表草图、P1/P2/P3 分期计划。

> 详细技术栈选型矩阵和项目结构 → `architecture.md`

---

## 阶段 2：Claude Code 实现

**顺序**：DB schema → API → 业务逻辑 → Auth → 前端骨架 → 联调

**后端验收**：curl 测通所有端点、DB 有接近真实场景的 seed 数据、错误处理完善

**前端骨架验收**：每个页面展示真实 DB 数据、表单提交写入 DB、页面跳转正常

**联调重点检查**：

```
- 前端 API URL 是相对路径（/api/xxx），不是写死的 http://localhost:8000
- WebSocket 地址动态读取 NEXT_PUBLIC_API_URL，不硬编码
- 所有配置（API key、DB 路径、域名）通过 .env 传入
```

Next.js 防硬编码配置（`next.config.ts`）：

```typescript
async rewrites() {
  return [{
    source: '/api/:path*',
    destination: `${process.env.BACKEND_URL || 'http://localhost:8000'}/api/:path*`,
  }]
}
```

---

## 阶段 3：Codex 前端视觉优化

骨架跑通后才进这个阶段。**只改视觉层，不动业务逻辑**。

推荐顺序：
1. E（去 emoji → icon）+ C（Toast 替换 alert）
2. B（微交互）+ D（表单实时校验）
3. G（加载/空/错误状态）+ A（设计风格统一）

各类 prompt → `frontend-prompts.md`

---

## 阶段 4：质量关卡（2 轮）

**第 1 轮 — Bug Fix**

```
对 [项目路径] 进行全面 bug review：
1. 运行所有测试，列出失败项并修复
2. 检查 API 错误处理（空值、类型错误、权限边界）
3. 检查前端异常处理（网络失败、空数据、加载态）
修复完成后再跑一遍测试，全部通过才结束。
```

**第 2 轮 — 去冗余 + 去硬编码**

```
对 [项目路径] 进行代码质量 review：

1. 去硬编码（用 scripts/review_hardcode.sh 先扫一遍）
   - 所有 URL/IP/端口 → .env
   - 所有 mock/test 数据 → 真实 DB 或参数化
   - 所有密码/key → 环境变量

2. 去冗余
   - 删除未使用的 import、变量、函数
   - 合并重复逻辑（DRY）
   - 删除 console.log / print

3. 可维护性
   - 单函数 ≤ 50 行，单文件 ≤ 300 行
   - 关键逻辑加注释，常量提取

commit message: refactor: remove hardcodes + dead code + improve maintainability
```

---

## 阶段 5：数据打通测试

**这是最重要的阶段**，每项都要手动验一遍。

**前后端连通**：
```bash
# 在 DB 里改一条数据，刷新页面，确认展示变了
sqlite3 data.db "UPDATE users SET name='验证改名' WHERE id=1"
# → 刷新页面确认显示"验证改名"

# 通过前端表单新增，确认 DB 里出现
# 通过前端删除，确认 DB 里消失
```

**功能间联动**：A 功能操作是否正确影响 B 功能数据显示？

**业务 ↔ 管理后台**：管理后台改配置/数据 → 业务系统立即生效？业务操作 → 管理后台日志/统计更新？

---

## 阶段 6：边界 & 交互测试

每轮一个测试重点，给 Claude Code 明确 case 清单：

```
第 1 轮 — 输入边界
  空字符串/null、超长字符串（10000字）、特殊字符（<script>/SQL注入/Unicode）、负数/超大数

第 2 轮 — 权限边界
  未登录访问受保护页面、低权限用户访问高权限接口、跨用户访问他人数据

第 3 轮 — 并发 & 异常
  快速重复提交表单、网络断开时的操作、后端返回 500 时前端表现、超时处理

第 4 轮 — 数据边界
  0 条数据、1000+ 条、分页边界（首页/末页/超出总页数）
```

**Web 端交互自动化**（Chrome DevTools）：

```
用 Chrome DevTools MCP 对 [URL] 进行交互测试：
1. 导航到主页，截图确认加载正常
2. 点击 [按钮]，等待响应，截图
3. 填写表单，提交，确认 Toast 成功提示出现
4. 检查 Network 面板，确认 API 调用返回 200（不是 mock）
5. 检查 Console，确认没有 JS 错误
发现问题自动修复，修复后重新测试。
```

---

## 阶段 7：迭代 Review

每次从**一个角度** review，不要同时改多个：

```
可维护性："找出耦合度高、难以修改的模块，提出重构方案并实现"
可扩展性："如果要加 [新功能X]，改动范围合理吗？给出改进方案"
性能：    "找出 N+1 查询、大量 DOM 操作、不必要的重渲染"
安全：    "扫描 SQL 注入、XSS、敏感数据暴露、权限绕过"
```
