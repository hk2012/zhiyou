#!/usr/bin/env bash
set -euo pipefail

# 智友 App - 本地前后端服务状态检查
#
# 常用示例：
#   ./scripts/dev_status.sh
#   ./scripts/dev_status.sh 8080 5124

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,8p' "$0"
  exit 0
fi

BACKEND_PORT="${1:-8080}"
WEB_PORT="${2:-5124}"

print_port_status() {
  local name="$1"
  local port="$2"
  local pids
  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    echo "未启动: ${name}，端口 ${port} 没有监听进程"
  else
    echo "已启动: ${name}，端口 ${port}，进程 ${pids}"
  fi
}

echo "==> 本地服务状态"
print_port_status "后端 FastAPI" "$BACKEND_PORT"
print_port_status "前端 Flutter Web" "$WEB_PORT"

if curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1; then
  echo "可访问: 后端健康检查 http://127.0.0.1:$BACKEND_PORT/api/v1/health"
else
  echo "不可访问: 后端健康检查 http://127.0.0.1:$BACKEND_PORT/api/v1/health"
fi

if curl -fsSI "http://127.0.0.1:$WEB_PORT/" >/dev/null 2>&1; then
  echo "可访问: 前端页面 http://127.0.0.1:$WEB_PORT/"
else
  echo "不可访问: 前端页面 http://127.0.0.1:$WEB_PORT/"
fi

if [[ -f "$PROJECT_ROOT/backend/zhiyou_dev.db" ]]; then
  echo "已存在: 本地数据库 backend/zhiyou_dev.db"
else
  echo "未创建: 本地数据库 backend/zhiyou_dev.db"
fi
