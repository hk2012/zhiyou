#!/usr/bin/env bash
set -euo pipefail

# 智友 App - 停止本地 FastAPI 后端服务
#
# 常用示例：
#   ./scripts/backend_stop.sh
#   ./scripts/backend_stop.sh 8080

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,8p' "$0"
  exit 0
fi

BACKEND_PORT="${1:-8080}"
SCREEN_NAME="zhiyou_backend_${BACKEND_PORT}"

if command -v screen >/dev/null 2>&1; then
  screen -S "$SCREEN_NAME" -X quit >/dev/null 2>&1 || true
fi

pids="$(lsof -tiTCP:"$BACKEND_PORT" -sTCP:LISTEN 2>/dev/null || true)"

if [[ -z "$pids" ]]; then
  echo "==> 后端端口 $BACKEND_PORT 没有正在运行的服务"
  exit 0
fi

echo "==> 关闭后端端口 $BACKEND_PORT 上的服务: $pids"
kill $pids 2>/dev/null || true
sleep 1

pids="$(lsof -tiTCP:"$BACKEND_PORT" -sTCP:LISTEN 2>/dev/null || true)"
if [[ -n "$pids" ]]; then
  echo "==> 后端旧服务未退出，强制关闭: $pids"
  kill -9 $pids 2>/dev/null || true
fi

echo "==> 后端已停止"
