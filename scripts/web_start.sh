#!/usr/bin/env bash
set -euo pipefail

# 渔趣 App - 后台重启 Web 服务
#
# 默认用途：
#   先关闭旧服务，再在前台构建 Web，构建成功后把静态服务挂到后台。
#   适合日常开发后刷新浏览器访问，不会因为当前终端结束而断开。
#
# 常用示例：
#   ./scripts/web_start.sh
#   ./scripts/web_start.sh 5124
#   SKIP_BUILD=1 ./scripts/web_start.sh 5124
#   API_BASE_URL=http://127.0.0.1:8080 ./scripts/web_start.sh 5124

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,14p' "$0"
  exit 0
fi

WEB_PORT="${1:-5124}"
LOG_FILE="$PROJECT_ROOT/.dart_tool/zhiyou_web_${WEB_PORT}.log"
PID_FILE="$PROJECT_ROOT/.dart_tool/zhiyou_web_${WEB_PORT}.pid"
WEB_HOSTNAME="${WEB_HOSTNAME:-0.0.0.0}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8080}"
SCREEN_NAME="zhiyou_web_${WEB_PORT}"

cd "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT/.dart_tool"

echo "==> 后台重启 Web 服务，端口: $WEB_PORT"
echo "==> 日志文件: $LOG_FILE"

echo "==> 关闭旧服务"
if command -v screen >/dev/null 2>&1; then
  screen -S "$SCREEN_NAME" -X quit >/dev/null 2>&1 || true
fi
"$PROJECT_ROOT/scripts/web_stop.sh" "$WEB_PORT"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> 构建 Flutter Web 产物"
  flutter build web --pwa-strategy=none --dart-define="API_BASE_URL=$API_BASE_URL"
fi

echo "==> 启动后台静态服务"
if command -v screen >/dev/null 2>&1; then
  screen -dmS "$SCREEN_NAME" bash -lc \
    "cd '$PROJECT_ROOT/build/web' && exec python3 -u -m http.server '$WEB_PORT' --bind '$WEB_HOSTNAME' >> '$LOG_FILE' 2>&1"
  echo "$SCREEN_NAME" > "$PID_FILE"
else
  (
    cd "$PROJECT_ROOT/build/web"
    exec setsid python3 -u -m http.server "$WEB_PORT" --bind "$WEB_HOSTNAME"
  ) > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
fi

for _ in {1..10}; do
  if lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "==> 启动成功"
  echo "==> Mac 本机访问: http://localhost:$WEB_PORT/#/login"
  echo "==> 手机/局域网访问: http://$(ipconfig getifaddr en0 2>/dev/null || echo '<Mac局域网IP>'):$WEB_PORT/#/login"
else
  echo "==> 服务还在启动或启动失败，最近日志如下："
  sed -n '1,160p' "$LOG_FILE" || true
fi
