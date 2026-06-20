#!/usr/bin/env bash
set -euo pipefail

# 江湖钓客演示前快速检查
#
# 用法：
#   ./scripts/demo_smoke.sh
#   ./scripts/demo_smoke.sh http://127.0.0.1:5124 http://127.0.0.1:8080
#   ./scripts/demo_smoke.sh http://115.190.5.90 http://115.190.5.90

WEB_URL="${1:-http://127.0.0.1:5124}"
API_URL="${2:-http://127.0.0.1:8080}"

trim_slash() {
  printf '%s' "${1%/}"
}

WEB_URL="$(trim_slash "$WEB_URL")"
API_URL="$(trim_slash "$API_URL")"

check_url() {
  local label="$1"
  local url="$2"
  if curl -fsS --max-time 8 "$url" >/dev/null; then
    echo "OK  $label: $url"
  else
    echo "ERR $label: $url" >&2
    return 1
  fi
}

echo "==> 江湖钓客演示 smoke"
echo "WEB: $WEB_URL"
echo "API: $API_URL"

check_url "Web 首页" "$WEB_URL/"
check_url "API 健康检查" "$API_URL/api/v1/health"

echo "==> 浏览器必看路径"
echo "$WEB_URL/#/home"
echo "$WEB_URL/#/explore?entry=home&intent=route&fish=%E7%BF%98%E5%98%B4&method=%E8%B7%AF%E4%BA%9A%E4%BA%AE%E7%89%87&window=05%3A30-08%3A30&hint=%E8%83%8C%E9%A3%8E%E6%B5%85%E6%BB%A9"
echo "$WEB_URL/#/mall?entry=home&intent=gear&fish=%E7%BF%98%E5%98%B4&method=%E8%B7%AF%E4%BA%9A%E4%BA%AE%E7%89%87&window=05%3A30-08%3A30&query=%E7%BF%98%E5%98%B4"
echo "$WEB_URL/#/create?entry=home&intent=catch&spot=%E5%8D%83%E5%B2%9B%E6%B9%96%20%C2%B7%20%E4%B8%9C%E5%8D%97%E6%B9%96%E5%8C%BA&fish=%E7%BF%98%E5%98%B4&method=%E8%B7%AF%E4%BA%9A%E4%BA%AE%E7%89%87&window=05%3A30-08%3A30&hint=%E8%83%8C%E9%A3%8E%E6%B5%85%E6%BB%A9"
echo "$WEB_URL/#/profile"
