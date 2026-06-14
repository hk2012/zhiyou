#!/usr/bin/env bash
set -euo pipefail

# 江湖钓客 App - iOS 真机打包安装脚本
#
# 用途：
#   构建 iOS 真机包，并安装到已连接的 iPhone。
#   适合真机验收，不进入热重载调试会话。
#
# 常用示例：
#   ./scripts/ios_install_device.sh
#   ./scripts/ios_install_device.sh test
#   ./scripts/ios_install_device.sh demo
#   ./scripts/ios_install_device.sh all
#   ./scripts/ios_install_device.sh 00008140-001A38303E02801C
#   API_BASE_URL=http://<Mac局域网IP>:8080 ./scripts/ios_install_device.sh
#
# 参数说明：
#   第 1 个参数：设备别名或设备 ID，默认安装到当前在线 iOS 设备。
#     demo：正式安装 / 展示机，洪宽的iPhone，00008140-001A38303E02801C
#     test：内部测试机，南京赋码爷，00008110-00190C520168401E
#     all：给当前在线的两台测试机都安装。
#   API_BASE_URL：可选后端接口地址，会作为 dart-define 写入构建；
#     未传时自动使用当前 Mac 局域网 IP 的 8080 端口。
#
# 前置条件：
#   1. iPhone 已解锁并信任当前 Mac。
#   2. iPhone 已打开开发者模式。
#   3. Xcode 工程已有可用签名 Team / Bundle Identifier。

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,24p' "$0"
  exit 0
fi

TARGET="${1:-ios}"

detect_lan_ip() {
  # 优先取 Wi-Fi/en0；如果 Mac 当前 Wi-Fi 不是 en0，则从默认路由推断。
  local ip
  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(route get default 2>/dev/null | awk '/interface:/{iface=$2} END{if (iface) print iface}' | xargs -I{} ipconfig getifaddr {} 2>/dev/null || true)"
  fi
  echo "$ip"
}

LAN_IP="$(detect_lan_ip)"
if [[ -z "${API_BASE_URL:-}" ]]; then
  if [[ -n "$LAN_IP" ]]; then
    API_BASE_URL="http://$LAN_IP:8080"
  else
    echo "错误：未检测到 Mac 局域网 IP，请手动指定 API_BASE_URL=http://<Mac局域网IP>:8080" >&2
    exit 1
  fi
fi

DEMO_DEVICE_ID="00008140-001A38303E02801C"
TEST_DEVICE_ID="00008110-00190C520168401E"

case "$TARGET" in
  ios | auto | current)
    DEVICE_IDS=()
    ;;
  demo | display | formal | hongkuan | current | iphone)
    DEVICE_IDS=("$DEMO_DEVICE_ID")
    ;;
  test | internal | nanjing | old)
    DEVICE_IDS=("$TEST_DEVICE_ID")
    ;;
  all)
    DEVICE_IDS=("$DEMO_DEVICE_ID" "$TEST_DEVICE_ID")
    ;;
  *)
    DEVICE_IDS=("$TARGET")
    ;;
esac

cd "$PROJECT_ROOT"

echo "==> 项目目录: $PROJECT_ROOT"
if [[ "${#DEVICE_IDS[@]}" -eq 0 ]]; then
  echo "==> 目标设备: 当前在线 iOS 设备"
else
  echo "==> 目标设备: ${DEVICE_IDS[*]}"
fi
echo "==> 构建模式: release"
echo "==> 接口地址: $API_BASE_URL"

echo "==> 当前 Flutter 识别到的设备："
DEVICE_LIST="$(flutter devices)"
echo "$DEVICE_LIST"

online_device_ids=()
if [[ "${#DEVICE_IDS[@]}" -eq 0 ]]; then
  while IFS= read -r line; do
    if [[ "$line" == *"• ios"* ]]; then
      device_id="$(awk -F '•' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' <<<"$line")"
      [[ -n "$device_id" ]] && online_device_ids+=("$device_id")
    fi
  done <<<"$DEVICE_LIST"
else
  for device_id in "${DEVICE_IDS[@]}"; do
    if grep -Fq "• $device_id •" <<<"$DEVICE_LIST"; then
      online_device_ids+=("$device_id")
    elif [[ "$TARGET" == "all" ]]; then
      echo "==> 跳过离线设备: $device_id"
    else
      echo "错误：目标设备不在线或未被 Flutter 识别: $device_id" >&2
      echo "请确认 iPhone 已解锁、信任当前 Mac，并已打开开发者模式。" >&2
      exit 1
    fi
  done
fi

if [[ "$TARGET" != "all" && "${#online_device_ids[@]}" -gt 1 ]]; then
  echo "错误：当前在线 iOS 设备超过 1 台，请指定设备别名或设备 ID。" >&2
  for device_id in "${online_device_ids[@]}"; do
    echo "  $device_id" >&2
  done
  exit 1
fi

if [[ "${#online_device_ids[@]}" -eq 0 ]]; then
  echo "错误：没有可安装的在线 iOS 测试机。" >&2
  exit 1
fi

build_args=(ios --release --dart-define="API_ENV=device" --dart-define="API_BASE_URL=$API_BASE_URL")

echo "==> 开始构建 iOS 真机 release 包"
flutter build "${build_args[@]}"

APP_BUNDLE="$PROJECT_ROOT/build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
  APP_BUNDLE="$PROJECT_ROOT/build/ios/Release-iphoneos/Runner.app"
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "错误：没有找到 iOS App Bundle，实际产物如下：" >&2
  find "$PROJECT_ROOT/build/ios" -maxdepth 4 -name "*.app" -type d -print >&2 || true
  exit 1
fi

echo "==> App Bundle: $APP_BUNDLE"

for device_id in "${online_device_ids[@]}"; do
  echo "==> 安装到真机: $device_id"
  if xcrun devicectl --version >/dev/null 2>&1; then
    xcrun devicectl device install app --device "$device_id" "$APP_BUNDLE"
  else
    flutter install -d "$device_id" --release
  fi
done

echo "==> 安装完成，可在 iPhone 上打开「江湖钓客」。"
