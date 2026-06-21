# 江湖钓客物联设备中心设计规格

## 目标

把现有“设备摘要”升级为可查看、可控制、可追踪、可扩展的物联设备产品。首期完整支持智能钓箱、智能钓伞、智能钓台，并为后续夜钓灯、探鱼器、增氧设备等预留统一能力模型。

## 已批准视觉方向

- 沿用现有浅色水墨、青绿色品牌体系和 Material 图标。
- 页面低文字密度，首屏只突出状态、风险和主要动作。
- 三类设备详情共用“状态 / 控制 / 自动化 / 维护”四个标签。
- 手机单列；平板列表加详情双栏；桌面采用侧栏、设备列表、详情三栏。
- 参考视觉：
  - `device-tackle-box-detail.png`
  - `device-umbrella-detail.png`
  - `device-platform-detail.png`

## 信息架构

- `/devices`：设备驾驶舱，展示健康摘要、异常、重点设备和场景。
- `/devices/:deviceId`：设备详情，提供状态、控制、自动化、维护。
- `/devices/add`：模拟扫码、蓝牙发现和型号选择绑定设备。
- `/device-scenes`：开钓、夜钓、收竿场景及执行记录。
- `/device-alerts`：统一告警列表。
- `/device-commands/:commandId`：命令执行结果和状态时间线。

首页与“我的”页面的设备入口统一跳转到设备中心，不再弹出只读摘要。

## 设备能力

### 智能钓箱

- 温度、目标温度、制冷档位。
- 箱锁、照明、USB 电源。
- 重量、保鲜时长、温度趋势。
- 高温、箱盖、电量告警。
- 固件升级和温度传感器校准。

### 智能钓伞

- 风力、阵风、UV、降雨概率。
- 开伞、长按确认收伞、倾角调节。
- 防风阈值、超限自动收伞。
- 太阳跟随和降雨响应。
- 电池健康、自动化事件、固件维护。

### 智能钓台

- 倾斜角、一键调平、四腿微调。
- 负载分布、稳定性、安全锁。
- 二次确认紧急停止。
- 校准历史、固件和执行器诊断。

## 领域模型

- `DeviceProductModel`：型号、类型、厂商、协议和默认能力。
- `DeviceCapability`：属性或命令的参数约束、单位、危险级别。
- `DeviceCommand`：用户下发的一次命令。
- `CommandReceipt`：命令状态、结果、失败原因和时间线。
- `AutomationScene`：场景名称、动作集合和启用状态。
- `SceneAction`：场景内设备、命令和参数。
- 现有 `SmartDevice`、遥测、告警、固件表继续保留。

首期使用数据库内模拟回执，不接真实 MQTT/BLE。命令状态为：

`awaiting_confirmation -> queued -> sent -> acknowledged -> succeeded`

异常状态为：

`rejected / failed / timed_out / cancelled`

危险命令必须带 `confirmed=true`，否则返回待确认状态，不执行设备属性变更。

## API

- `GET /api/v1/devices/{id}/capabilities`
- `POST /api/v1/devices/bind`
- `DELETE /api/v1/devices/{id}/binding`
- `PATCH /api/v1/devices/{id}/settings`
- `POST /api/v1/devices/{id}/commands`
- `GET /api/v1/device-commands/{id}`
- `POST /api/v1/device-scenes`
- `GET /api/v1/device-scenes`
- `POST /api/v1/device-scenes/{id}/execute`
- `POST /api/v1/devices/{id}/firmware-upgrades`

## 前端架构

新增 `features/devices`，按职责拆分：

- `data`：API DTO、仓库和演示回退数据。
- `application`：Riverpod 控制器、详情状态、命令状态。
- `view`：设备中心、详情、绑定、场景、告警和命令结果页面。
- `view/widgets`：通用设备头部、指标、标签、命令状态、响应式布局。
- `view/device_panels`：钓箱、钓伞、钓台专属控制面板。

设备功能不继续堆入 `home_screen.dart` 或 `profile_screen.dart`。

## 错误与回退

- 列表、详情和命令请求失败时保留最后一次数据，并显示“本地演示数据”来源。
- 离线设备禁用普通控制，仍允许查看历史、维护信息和解除绑定。
- 命令失败、超时必须展示 `command_id`、失败原因和重试入口。
- 危险命令在 UI 和 API 两层确认。

## 测试与验收

- 后端测试覆盖能力、绑定、设置、普通命令、危险确认、命令查询、场景执行和 OTA。
- Flutter 单元/组件测试覆盖模型解析、设备中心、详情标签、危险确认和响应式布局。
- `flutter analyze`、`flutter test`、后端 `pytest`、Flutter Web 构建全部通过。
- 390px、768px、1440px 三种宽度无溢出或畸形。
- 三类设备详情可操作，命令状态可追踪到 `command_id`。

