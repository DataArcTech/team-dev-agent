#!/usr/bin/env bash
# review_hardcode.sh — 扫描代码里的硬编码/mock数据
# 用法：bash review_hardcode.sh [项目路径]
#
# 示例：
#   bash review_hardcode.sh /Users/eric_jiang/my-project

PROJECT_DIR="${1:-.}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 扫描项目: $PROJECT_DIR"
echo "=================================="

FOUND=0

# 排除的目录
EXCLUDE="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=__pycache__ --exclude-dir=.venv --exclude-dir=venv --exclude-dir=dist --exclude-dir=build"

check_pattern() {
  local label="$1"
  local severity="$2"  # high / medium / low
  shift 2
  local patterns=("$@")

  local results=""
  for pattern in "${patterns[@]}"; do
    local found
    found=$(grep -rn $EXCLUDE "$pattern" "$PROJECT_DIR" 2>/dev/null | \
      grep -v "\.example\|\.sample\|\.template\|test_\|_test\.\|spec\.\|\.md\|# " | \
      grep -v "^Binary" | head -20)
    if [[ -n "$found" ]]; then
      results+="$found"$'\n'
    fi
  done

  if [[ -n "$results" ]]; then
    FOUND=$((FOUND + 1))
    case "$severity" in
      "high")   echo -e "\n${RED}[HIGH] $label${NC}" ;;
      "medium") echo -e "\n${YELLOW}[MEDIUM] $label${NC}" ;;
      "low")    echo -e "\n[LOW] $label" ;;
    esac
    echo "$results" | head -20
  fi
}

# === 高危：安全相关 ===
check_pattern "API Key / Token 硬编码" "high" \
  '-E "(api_key|secret_key|access_token|password)\s*=\s*[\"'"'"'][^\"'"'"']{8,}"' \
  '-E "sk-[a-zA-Z0-9]{20,}"' \
  '-E "Bearer [a-zA-Z0-9._-]{20,}"'

check_pattern "硬编码密码" "high" \
  '-iE "(password|passwd|pwd)\s*=\s*[\"'"'"'][^\"'"'"']+[\"'"'"']"'

# === 高危：数据相关 ===
check_pattern "Mock / Fake 数据" "high" \
  '-iE "mock|fake|dummy|stub"' \
  '-E "\"name\":\s*\"测试|\"name\":\s*\"test|\"name\":\s*\"admin\""' \
  '-iE "return \{.*\"name\".*\"test'

check_pattern "Hardcode 用户 ID / 业务 ID" "high" \
  '-iE "user_id\s*=\s*[\"'"'"'][a-z0-9_-]{4,}[\"'"'"']"' \
  '-iE "tenant_id\s*=\s*[\"'"'"'][^\"'"'"']+[\"'"'"']"'

# === 中危：配置相关 ===
check_pattern "硬编码 localhost / IP" "medium" \
  '-E "http://localhost:[0-9]+"' \
  '-E "http://127\.0\.0\.1"' \
  '-E "http://0\.0\.0\.0"' \
  '-iE "(host|url|endpoint)\s*=\s*[\"'"'"']http://(localhost|127\.0\.0\.1)"'

check_pattern "硬编码端口号" "medium" \
  '-E ":8000|:3000|:5000|:4000" --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js"'

check_pattern "硬编码 DB 路径" "medium" \
  '-iE "(database|db)_url\s*=\s*[\"'"'"'][^\"'"'"']+"' \
  '-iE "sqlite:///[^\"'"'"'\$]+"'

# === 中危：代码质量 ===
check_pattern "TODO / FIXME / HACK 遗留" "medium" \
  '-iE "TODO|FIXME|HACK|XXX" --include="*.py" --include="*.ts" --include="*.tsx"'

check_pattern "调试语句遗留" "medium" \
  '-E "console\.log\(" --include="*.ts" --include="*.tsx" --include="*.js"' \
  '-E "^[[:space:]]*print\(" --include="*.py"' \
  '-E "pdb\.set_trace|breakpoint\(\)" --include="*.py"'

# === 低危：代码规范 ===
check_pattern "魔法数字（business logic 里）" "low" \
  '-E "[^0-9][2-9][0-9]{3,}[^0-9]" --include="*.py" --include="*.ts"'

# === 结果汇总 ===
echo ""
echo "=================================="
if [[ $FOUND -eq 0 ]]; then
  echo -e "${GREEN}✅ 未发现明显硬编码问题${NC}"
else
  echo -e "${RED}⚠️  发现 $FOUND 类硬编码问题，请修复后再提交${NC}"
  echo ""
  echo "修复建议："
  echo "  - API Key → 移到 .env，用环境变量读取"
  echo "  - localhost URL → 用相对路径或环境变量"
  echo "  - Mock 数据 → 连接真实 DB"
  echo "  - TODO → 实现或创建 issue 跟踪"
fi
echo ""
