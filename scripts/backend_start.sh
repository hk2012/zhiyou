#!/usr/bin/env bash
set -euo pipefail

# 江湖钓客 App - 后台重启本地 FastAPI 后端服务
#
# 启动顺序：
#   1. 关闭指定端口上的旧后端服务。
#   2. 准备 Python 虚拟环境和依赖。
#   3. 初始化本地 SQLite 数据库和基础种子数据。
#   4. 后台启动 FastAPI。
#
# 常用示例：
#   ./scripts/backend_start.sh
#   ./scripts/backend_start.sh 8080
#   DATABASE_URL=postgresql+psycopg://user:pass@host:5432/db ./scripts/backend_start.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '4,18p' "$0"
  exit 0
fi

BACKEND_PORT="${1:-8080}"
BACKEND_HOST="${BACKEND_HOST:-0.0.0.0}"
LOG_FILE="$PROJECT_ROOT/.dart_tool/zhiyou_backend_${BACKEND_PORT}.log"
PID_FILE="$PROJECT_ROOT/.dart_tool/zhiyou_backend_${BACKEND_PORT}.pid"
SCREEN_NAME="zhiyou_backend_${BACKEND_PORT}"

cd "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT/.dart_tool"

echo "==> 后台重启后端服务，端口: $BACKEND_PORT"
echo "==> 后端日志: $LOG_FILE"

"$PROJECT_ROOT/scripts/backend_stop.sh" "$BACKEND_PORT"

cd "$BACKEND_DIR"

if [[ ! -d ".venv" ]]; then
  echo "==> 创建 Python 虚拟环境"
  python3 -m venv .venv
fi

source .venv/bin/activate

if ! python - <<'PY' >/dev/null 2>&1
import fastapi
import sqlalchemy
import uvicorn
PY
then
  echo "==> 安装后端依赖"
  pip install -r requirements.txt
fi

echo "==> 初始化本地数据库和基础种子数据"
python -m app.scripts.init_db

echo "==> 启动 FastAPI 后端"
if command -v screen >/dev/null 2>&1; then
  screen -dmS "$SCREEN_NAME" bash -lc \
    "cd '$BACKEND_DIR' && source .venv/bin/activate && exec uvicorn app.main:app --host '$BACKEND_HOST' --port '$BACKEND_PORT' >> '$LOG_FILE' 2>&1"
  echo "$SCREEN_NAME" > "$PID_FILE"
else
  (
    cd "$BACKEND_DIR"
    source .venv/bin/activate
    exec uvicorn app.main:app --host "$BACKEND_HOST" --port "$BACKEND_PORT"
  ) > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
fi

for _ in {1..20}; do
  if curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1; then
  echo "==> 后端启动成功"
  echo "==> 健康检查: http://127.0.0.1:$BACKEND_PORT/api/v1/health"
  echo "==> 接口文档: http://127.0.0.1:$BACKEND_PORT/docs"
else
  echo "==> 后端启动失败或仍在启动，最近日志如下："
  sed -n '1,160p' "$LOG_FILE" || true
  exit 1
fi
