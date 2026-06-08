#!/usr/bin/env bash
set -euo pipefail

# 江湖钓客 App - iOS 真机调试启动脚本
#
# 前置条件：
#   1. 已安装完整 Xcode.app，并配置好签名 Team / Bundle Identifier。
#   2. iPhone 已解锁、信任当前 Mac，并打开开发者模式。
#   3. 如用数据线调试，请保持 USB 连接；如用无线调试，请确保手机和 Mac 在同一局域网。
#   4. 真机访问 Mac 本机后端时，不能使用 127.0.0.1，要使用 Mac 的局域网 IP。
#
# 常用示例：
#   ./scripts/ios_debug.sh
#   ./scripts/ios_debug.sh --help
#   ./scripts/ios_debug.sh 00008110-00190C520168401E http://192.168.1.10:8080
#   API_BASE_URL=http://192.168.1.10:8080 ./scripts/ios_debug.sh ios
#
# 参数说明：
#   第 1 个参数：设备 ID，默认 ios。可先执行 flutter devices 查看真实设备 ID。
#   第 2 个参数：后端接口地址，默认从 API_BASE_URL 读取；否则自动猜测 Mac 局域网 IP 的 8080 端口。
#
# Flutter 真机调试按键：
#   r  热加载，仅 Dart/UI 小改动常用。
#   R  热重启，重建 Dart 状态。
#   q  退出调试会话。

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,25p' "$0"
  exit 0
fi

DEVICE_ID="${1:-ios}"

detect_lan_ip() {
  # 优先取 Wi-Fi/en0 的局域网 IP；失败时再从路由表推断当前出口 IP。
  local ip
  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(route get default 2>/dev/null | awk '/interface:/{iface=$2} END{if (iface) print iface}' | xargs -I{} ipconfig getifaddr {} 2>/dev/null || true)"
  fi
  echo "$ip"
}

LAN_IP="$(detect_lan_ip)"
DEFAULT_API_BASE_URL="http://${LAN_IP:-192.168.1.10}:8080"
API_BASE_URL="${2:-${API_BASE_URL:-$DEFAULT_API_BASE_URL}}"

cd "$PROJECT_ROOT"

echo "==> 项目目录: $PROJECT_ROOT"
echo "==> 目标设备: $DEVICE_ID"
echo "==> 接口地址: $API_BASE_URL"
echo "==> 先列出当前可用设备，确认 iPhone 已被 Flutter 识别。"
flutter devices

echo "==> 启动 iOS 真机调试，终端中按 r 热加载、R 热重启、q 退出。"
flutter run \
  -d "$DEVICE_ID" \
  --dart-define="API_BASE_URL=$API_BASE_URL"
