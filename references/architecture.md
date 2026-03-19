# 架构设计参考

## 技术栈选型矩阵

### 后端

| 场景 | 推荐 | 理由 |
|------|------|------|
| B 端 API + 管理后台 | **FastAPI** | async 性能好，OpenAPI 自动生成，Python 生态 |
| 轻量原型 | Flask / FastAPI | 快 |
| Node.js 团队 | Express + Prisma | 统一语言 |
| 实时功能多 | FastAPI + WebSocket | 原生支持 |

**FastAPI 标准项目结构**：

```
backend/
├── api/
│   ├── routers/       # 路由按功能分组
│   └── server.py      # FastAPI app + 挂载路由
├── core/
│   ├── db.py          # DB engine + session
│   ├── auth.py        # JWT 验证
│   └── config.py      # 环境变量读取（pydantic BaseSettings）
├── models/            # SQLAlchemy models
├── schemas/           # Pydantic request/response schemas
├── services/          # 业务逻辑（不放在 router 里）
├── scripts/
│   └── seed.py        # 真实场景的 seed 数据
├── tests/
├── .env.example       # 环境变量模板
└── requirements.txt
```

### 前端

| 场景 | 推荐 | 理由 |
|------|------|------|
| B 端 Web 管理系统 | **Next.js + TypeScript** | SEO 可选，SSR/CSR 灵活，生态最全 |
| 纯 SPA（无 SEO 需求）| Vite + React + TypeScript | 更轻 |
| 微信小程序 | 原生 or Taro | 按复杂度选 |
| 移动端 H5 | Next.js（响应式）| 统一代码库 |

**Next.js 标准结构**：

```
web/
├── src/
│   ├── app/           # Next.js App Router
│   ├── components/
│   │   ├── ui/        # 通用 UI 组件（Button, Input, Toast...）
│   │   └── [feature]/ # 功能组件
│   ├── hooks/         # 自定义 hooks
│   ├── lib/           # API client, utils
│   ├── types/         # TypeScript 类型
│   └── constants/     # 常量（API URL, 枚举值等）
├── public/
├── next.config.ts     # API rewrite（代理到后端）
├── .env.local.example
└── package.json
```

**next.config.ts 必备配置**（解决前端写死 localhost 问题）：

```typescript
const nextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.BACKEND_URL || 'http://localhost:8000'}/api/:path*`,
      },
    ];
  },
};
```

### DB

| 阶段 | 推荐 | 说明 |
|------|------|------|
| 原型期 | SQLite | 零配置，文件即数据库 |
| 生产（小规模）| PostgreSQL | 稳定，免费 |
| 生产（高并发）| PostgreSQL + Redis | Redis 做缓存/队列 |

**SQLAlchemy 2.0 async 标准写法**：

```python
# core/db.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import DeclarativeBase, sessionmaker

engine = create_async_engine("sqlite+aiosqlite:///data/app.db")
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

---

## 架构决策原则

### 1. 单体优先（原型期）

不要一开始就微服务。单体先跑通，需求稳定后再拆。

**拆分信号**：某个模块的部署频率/团队明显不同，才考虑拆。

### 2. DB 设计原则

- **避免 JSON 列存复杂结构**（查询困难，不可索引）；JSON 只用于真正不需要查询的配置/日志
- **宽表 vs 多表**：频繁 JOIN 同一组表 → 考虑宽表合并
- **外键约束**：开发期 ON，避免孤儿数据
- **枚举值**：用 DB Enum 或整数，不要存中文字符串（"已完成" → 1）
- **时间字段**：统一存 UTC，前端展示时转换时区

### 3. 权限隔离

```
# 多租户隔离模式（B 端必备）
每张业务表加 tenant_id 列
所有查询自动带 WHERE tenant_id = current_tenant_id
中间件注入 current_tenant_id，不依赖前端传参
```

### 4. 配置管理

```python
# core/config.py（pydantic BaseSettings）
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "sqlite+aiosqlite:///data/app.db"
    secret_key: str
    openrouter_api_key: str = ""
    backend_url: str = "http://localhost:8000"

    class Config:
        env_file = ".env"

settings = Settings()
```

所有配置从 `.env` 读取，代码里**零 hardcode**。

---

## 分期开发计划模板

**P1（MVP，1-2周）**
- 核心业务流程端到端跑通
- 真实 DB + 真实数据
- 基础 Auth
- 能给客户演示

**P2（可用，2-4周）**
- 权限体系完善
- 管理后台
- 异常处理完善
- 性能基准测试

**P3（生产就绪，4周+）**
- 多租户隔离
- 监控 & 告警
- 数据备份
- 文档完善

---

## GitHub 协作规范

```bash
# 初始化
git init
git add .
git commit -m "feat: initial project setup"

# Branch 命名
feat/feature-name   # 新功能
fix/bug-description # bug 修复
refactor/module     # 重构

# Commit 格式
feat: [功能描述]
fix: [bug描述]
refactor: [重构内容]
docs: [文档更新]
test: [测试相关]

# .gitignore 必须包含
.env
.env.local
data/db/
__pycache__/
node_modules/
.next/
*.pyc
```

**分享给团队**：

```bash
# 首次上传
git remote add origin https://github.com/DataArcTech/REPO_NAME.git
git push -u origin main

# 团队成员克隆后
cp .env.example .env  # 填入自己的配置
pip install -r requirements.txt  # 或 uv install
npm install  # 前端
```
