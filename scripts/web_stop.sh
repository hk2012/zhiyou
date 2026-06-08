#!/usr/bin/env bash
set -euo pipefail

# 渔趣 App - 停止指定端口的 Web 服务
#
# 常用示例：
#   ./scripts/web_stop.sh
#   ./scripts/web_stop.sh 5124

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,8p' "$0"
  exit 0
fi

WEB_PORT="${1:-5124}"
SCREEN_NAME="zhiyou_web_${WEB_PORT}"

if command -v screen >/dev/null 2>&1; then
  screen -S "$SCREEN_NAME" -X quit >/dev/null 2>&1 || true
fi

pids="$(lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN 2>/dev/null || true)"

if [[ -z "$pids" ]]; then
  echo "==> $WEB_PORT 端口没有正在运行的服务"
  exit 0
fi

echo "==> 关闭 $WEB_PORT 端口上的服务: $pids"
kill $pids 2>/dev/null || true
sleep 1

pids="$(lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN 2>/dev/null || true)"
if [[ -n "$pids" ]]; then
  echo "==> 强制关闭残留服务: $pids"
  kill -9 $pids 2>/dev/null || true
fi

echo "==> 已停止"
