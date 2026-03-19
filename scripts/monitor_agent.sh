#!/usr/bin/env bash
# monitor_agent.sh — 监控 Claude Code / Codex 后台任务
# 用法：bash monitor_agent.sh <log_file> <task_name> [pid] [feishu_open_id]
#
# 示例：
#   bash monitor_agent.sh /tmp/claude_backend.log "后端API开发" 12345 ou_029382aa35f7ef90867450a4ea8c9494

LOG_FILE="${1:-}"
TASK_NAME="${2:-Unknown Task}"
PID="${3:-}"
FEISHU_OPEN_ID="${4:-}"

if [[ -z "$LOG_FILE" ]]; then
  echo "用法: $0 <log_file> <task_name> [pid] [feishu_open_id]"
  exit 1
fi

# 检查 PID 是否存活
check_pid() {
  if [[ -n "$PID" ]]; then
    if kill -0 "$PID" 2>/dev/null; then
      echo "running"
    else
      echo "dead"
    fi
  else
    # 没有 PID，通过 log 最后修改时间判断
    if [[ -f "$LOG_FILE" ]]; then
      LAST_MOD=$(date -r "$LOG_FILE" +%s 2>/dev/null || stat -c %Y "$LOG_FILE" 2>/dev/null)
      NOW=$(date +%s)
      DIFF=$((NOW - LAST_MOD))
      if [[ $DIFF -lt 300 ]]; then
        echo "running"
      else
        echo "stale"
      fi
    else
      echo "no_log"
    fi
  fi
}

# 发飞书通知（需要 openclaw 已配置）
notify_feishu() {
  local msg="$1"
  if [[ -n "$FEISHU_OPEN_ID" ]]; then
    openclaw send --channel feishu --to "$FEISHU_OPEN_ID" --message "$msg" 2>/dev/null || true
  fi
}

# 获取日志最后 N 行
get_last_lines() {
  local n="${1:-20}"
  if [[ -f "$LOG_FILE" ]]; then
    tail -"$n" "$LOG_FILE"
  else
    echo "[log 文件不存在: $LOG_FILE]"
  fi
}

# 检测任务是否完成（通过关键词）
is_completed() {
  if [[ -f "$LOG_FILE" ]]; then
    grep -q "Done:\|任务完成\|All tests passed\|Build successful\|✅" "$LOG_FILE" 2>/dev/null
  else
    return 1
  fi
}

# 检测是否有错误
has_error() {
  if [[ -f "$LOG_FILE" ]]; then
    tail -50 "$LOG_FILE" | grep -qi "error\|exception\|traceback\|failed\|❌" 2>/dev/null
  else
    return 1
  fi
}

# 单次检查
STATUS=$(check_pid)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] 任务: $TASK_NAME | 状态: $STATUS"

case "$STATUS" in
  "running")
    echo "--- 最新进度（最后10行）---"
    get_last_lines 10
    if has_error; then
      MSG="⚠️ [$TASK_NAME] 进程运行中，但检测到错误信息，请检查日志：$LOG_FILE"
      echo "$MSG"
      notify_feishu "$MSG"
    fi
    ;;
  "dead")
    if is_completed; then
      MSG="✅ [$TASK_NAME] 任务已完成（PID $PID）"
      echo "$MSG"
      notify_feishu "$MSG"
      echo "--- 最后输出 ---"
      get_last_lines 20
    else
      MSG="❌ [$TASK_NAME] 进程已死（PID $PID），可能崩溃！请检查：$LOG_FILE"
      echo "$MSG"
      notify_feishu "$MSG"
      echo "--- 最后50行 ---"
      get_last_lines 50
    fi
    ;;
  "stale")
    MSG="⚠️ [$TASK_NAME] 日志5分钟内未更新，可能卡住或已完成。日志：$LOG_FILE"
    echo "$MSG"
    notify_feishu "$MSG"
    get_last_lines 20
    ;;
  "no_log")
    echo "❓ [$TASK_NAME] 日志文件不存在：$LOG_FILE"
    ;;
esac
