#!/usr/bin/env bash
set -euo pipefail

# 江湖钓客 App - 一键重启本地前后端服务
#
# 启动前会先显示服务状态，然后停止旧服务，再按顺序启动：
#   1. 后端 FastAPI：提供接口和本地 SQLite 数据。
#   2. 前端 Flutter Web：构建 Web 并托管静态页面。
#
# 常用示例：
#   ./scripts/dev_start.sh
#   ./scripts/dev_start.sh 8080 5124
#   SKIP_BUILD=1 ./scripts/dev_start.sh
#   API_ENV=web API_BASE_URL=http://127.0.0.1:8080 ./scripts/dev_start.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,16p' "$0"
  exit 0
fi

BACKEND_PORT="${1:-8080}"
WEB_PORT="${2:-5124}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:$BACKEND_PORT}"
API_ENV="${API_ENV:-web}"

cd "$PROJECT_ROOT"

echo "==> 启动前状态检查"
"$PROJECT_ROOT/scripts/dev_status.sh" "$BACKEND_PORT" "$WEB_PORT"

echo "==> 按要求重启：先停止旧服务"
"$PROJECT_ROOT/scripts/dev_stop.sh" "$BACKEND_PORT" "$WEB_PORT"

echo "==> 启动顺序 1/2：后端 FastAPI"
"$PROJECT_ROOT/scripts/backend_start.sh" "$BACKEND_PORT"

echo "==> 启动顺序 2/2：前端 Flutter Web"
API_ENV="$API_ENV" API_BASE_URL="$API_BASE_URL" "$PROJECT_ROOT/scripts/web_start.sh" "$WEB_PORT"

echo "==> 启动后状态检查"
"$PROJECT_ROOT/scripts/dev_status.sh" "$BACKEND_PORT" "$WEB_PORT"

echo "==> 可查看效果"
echo "前端首页: http://127.0.0.1:$WEB_PORT/"
echo "后端文档: http://127.0.0.1:$BACKEND_PORT/docs"
echo "首页数据预览: http://127.0.0.1:$BACKEND_PORT/api/v1/home/debug/database-preview"
