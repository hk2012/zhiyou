#!/usr/bin/env bash
set -euo pipefail

# 渔趣 App - 本地 Web 调试启动脚本
#
# 默认用途：
#   构建 Flutter Web 并启动静态 Web 服务，适合用浏览器或手机访问固定端口。
#
# 常用示例：
#   ./scripts/web_debug.sh
#   ./scripts/web_debug.sh 5124
#   ./scripts/web_debug.sh --help
#   API_BASE_URL=http://127.0.0.1:8080 ./scripts/web_debug.sh
#   API_ENV=web API_BASE_URL=http://127.0.0.1:8080 ./scripts/web_debug.sh
#
# 参数说明：
#   第 1 个参数：Web 调试端口，默认 5123。
#   WEB_HOSTNAME：Web 服务绑定地址，默认 0.0.0.0。
#   API_BASE_URL：后端接口地址，默认 http://127.0.0.1:8080。
#   API_ENV：API 环境，默认 web。
#   SKIP_BUILD=1：跳过 flutter build web，直接托管已有 build/web。
#   KEEP_PORT=1：不清理端口上的旧进程；默认会先关闭旧服务。

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,20p' "$0"
  exit 0
fi

WEB_PORT="${1:-5123}"
WEB_HOSTNAME="${WEB_HOSTNAME:-0.0.0.0}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8080}"
API_ENV="${API_ENV:-web}"

cd "$PROJECT_ROOT"

install_browser_probe_files() {
  local build_dir="$PROJECT_ROOT/build/web"

  if [[ ! -d "$build_dir" ]]; then
    return
  fi

  echo "==> 补齐浏览器探测静态文件"
  mkdir -p "$build_dir/.well-known/appspecific"
  cp "$PROJECT_ROOT/web/.well-known/appspecific/com.chrome.devtools.json" \
    "$build_dir/.well-known/appspecific/com.chrome.devtools.json"
  cp "$PROJECT_ROOT/web/flutter.js.map" "$build_dir/flutter.js.map"
}

stop_existing_server() {
  local pids
  pids="$(lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    return
  fi

  echo "==> 关闭 $WEB_PORT 端口上的旧服务: $pids"
  kill $pids 2>/dev/null || true
  sleep 1

  pids="$(lsof -tiTCP:"$WEB_PORT" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    echo "==> 旧服务未退出，强制关闭: $pids"
    kill -9 $pids 2>/dev/null || true
    sleep 1
  fi
}

echo "==> 项目目录: $PROJECT_ROOT"
echo "==> 绑定地址: $WEB_HOSTNAME"
echo "==> Web 端口: $WEB_PORT"
echo "==> 接口地址: $API_BASE_URL"
echo "==> API 环境: $API_ENV"
echo "==> Mac 本机访问: http://localhost:$WEB_PORT/#/login"
echo "==> 手机/局域网访问: http://$(ipconfig getifaddr en0 2>/dev/null || echo '<Mac局域网IP>'):$WEB_PORT/#/login"

if [[ "${KEEP_PORT:-0}" != "1" ]]; then
  stop_existing_server
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> 构建 Flutter Web 产物。"
  flutter build web \
    --release \
    --pwa-strategy=none \
    --no-web-resources-cdn \
    --optimization-level=4 \
    --no-source-maps \
    --dart-define="API_ENV=$API_ENV" \
    --dart-define="API_BASE_URL=$API_BASE_URL"
fi

install_browser_probe_files

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  if [[ "${PRECOMPRESS_WEB:-1}" == "1" ]]; then
    "$PROJECT_ROOT/scripts/web_precompress.sh"
  fi
fi

echo "==> 启动静态 Web 服务，终端中按 Ctrl+C 可退出。"
cd "$PROJECT_ROOT/build/web"
python3 -m http.server "$WEB_PORT" --bind "$WEB_HOSTNAME"
