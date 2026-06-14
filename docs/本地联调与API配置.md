# 江湖钓客本地联调与 API 配置

生成日期：2026-06-14

## 1. 默认端口

| 服务 | 默认地址 | 说明 |
| --- | --- | --- |
| FastAPI 后端 | `http://127.0.0.1:8080` | 接口前缀为 `/api/v1` |
| Flutter Web | `http://127.0.0.1:5124` | Hash 路由，例如 `/#/home` |
| 后端健康检查 | `http://127.0.0.1:8080/api/v1/health` | 只检查 API 进程 |
| 后端就绪检查 | `http://127.0.0.1:8080/api/v1/health/ready` | 检查 API 和数据库 |

## 2. 一键本地启动

```bash
./scripts/dev_start.sh
```

该命令会：

1. 启动后端 FastAPI，默认端口 `8080`。
2. 初始化本地 SQLite 数据库和种子数据。
3. 构建 Flutter Web，默认端口 `5124`。
4. 给 Web 构建写入 `API_ENV=web` 和 `API_BASE_URL=http://127.0.0.1:8080`。

自定义端口：

```bash
./scripts/dev_start.sh 8080 5124
```

跳过 Web 重新构建：

```bash
SKIP_BUILD=1 ./scripts/dev_start.sh
```

## 3. 前端 API 环境变量

前端统一从 `lib/core/network/api_environment.dart` 读取接口地址。

| 变量 | 示例 | 说明 |
| --- | --- | --- |
| `API_ENV` | `web` / `local` / `simulator` / `device` | 标记当前运行环境 |
| `API_BASE_URL` | `http://127.0.0.1:8080` | 显式覆盖后端地址，优先级最高 |

默认规则：

| 场景 | 推荐配置 | 默认行为 |
| --- | --- | --- |
| Web 浏览器 | `API_ENV=web` | `http://127.0.0.1:8080` |
| macOS / iOS 模拟器 | `API_ENV=simulator` | `http://127.0.0.1:8080` |
| Android 模拟器 | `API_ENV=simulator` | `http://10.0.2.2:8080` |
| iOS / Android 真机 | `API_ENV=device API_BASE_URL=http://<Mac局域网IP>:8080` | 必须显式传 `API_BASE_URL` |

## 4. Flutter 常用启动命令

Web 调试：

```bash
API_ENV=web API_BASE_URL=http://127.0.0.1:8080 ./scripts/web_start.sh 5124
```

Android 模拟器：

```bash
flutter run \
  -d android \
  --dart-define=API_ENV=simulator
```

iOS 模拟器：

```bash
flutter run \
  -d ios \
  --dart-define=API_ENV=simulator
```

iOS 真机：

```bash
API_BASE_URL=http://<Mac局域网IP>:8080 ./scripts/ios_debug.sh ios
```

真机不能使用 `127.0.0.1` 访问 Mac 后端，因为 `127.0.0.1` 指向手机自己。

## 5. 后端 CORS

后端配置在 `backend/app/core/config.py`。

开发环境默认允许：

- `localhost`
- `127.0.0.1`
- `0.0.0.0`
- `10.x.x.x`
- `172.16.x.x` 到 `172.31.x.x`
- `192.168.x.x`

生产环境不要使用 `ALLOWED_ORIGINS=*`。应在 `backend/.env` 中配置明确域名：

```env
ENVIRONMENT=production
ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
ALLOWED_ORIGIN_REGEX=
```

## 6. 网络错误处理约定

前端网络错误统一由：

- `lib/core/network/api_environment.dart`
- `lib/core/network/api_exception.dart`
- `lib/core/network/dio_client.dart`

处理内容包括：

- API 地址选择
- Authorization token 注入
- `X-Client-Api-Env` 请求头
- 连接超时、404、401、5xx 等可读错误文案
- 静态资源 URL 安全解析

页面可以继续捕获 `DioException`，但展示文案应优先使用：

```dart
DioClient.friendlyErrorMessage(error)
```

## 7. 快速排查

检查后端：

```bash
curl http://127.0.0.1:8080/api/v1/health
curl http://127.0.0.1:8080/api/v1/health/ready
```

检查前后端状态：

```bash
./scripts/dev_status.sh
```

查看后端日志：

```bash
tail -n 160 .dart_tool/zhiyou_backend_8080.log
```

查看 Web 日志：

```bash
tail -n 160 .dart_tool/zhiyou_web_5124.log
```
