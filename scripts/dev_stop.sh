#!/usr/bin/env bash
set -euo pipefail

# 智友 App - 停止本地前后端服务
#
# 常用示例：
#   ./scripts/dev_stop.sh
#   ./scripts/dev_stop.sh 8080 5124

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,8p' "$0"
  exit 0
fi

BACKEND_PORT="${1:-8080}"
WEB_PORT="${2:-5124}"

"$PROJECT_ROOT/scripts/web_stop.sh" "$WEB_PORT"
"$PROJECT_ROOT/scripts/backend_stop.sh" "$BACKEND_PORT"

echo "==> 本地前后端服务已停止"
