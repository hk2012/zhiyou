#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE_FILE="$PROJECT_ROOT/tool/ui_localization_baseline.txt"

baseline="$(tr -d '[:space:]' < "$BASELINE_FILE")"
current="$(
  cd "$PROJECT_ROOT"
  rg --files lib -g '*.dart' -g '!lib/l10n/generated/**' \
    | xargs rg -o "'[^']*[一-龥][^']*'" \
    | wc -l \
    | tr -d '[:space:]'
)"

if (( current > baseline )); then
  echo "检测到新增中文界面硬编码: $current > $baseline"
  echo "请将新增文案迁移到 lib/l10n/*.arb。"
  exit 1
fi

echo "中文界面硬编码未增加: $current <= $baseline"
