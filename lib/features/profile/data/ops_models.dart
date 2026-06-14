class OpsOverview {
  const OpsOverview({
    required this.modules,
    required this.layers,
    required this.capabilityGroups,
    required this.nextBuildOrder,
  });

  final List<OpsModule> modules;
  final List<OpsLayer> layers;
  final List<OpsCapabilityGroup> capabilityGroups;
  final List<String> nextBuildOrder;

  factory OpsOverview.fromJson(Map<String, dynamic> json) {
    return OpsOverview(
      modules: _asList(json['modules'], OpsModule.fromJson),
      layers: _asList(json['layers'], OpsLayer.fromJson),
      capabilityGroups: _asList(
        json['capability_groups'],
        OpsCapabilityGroup.fromJson,
      ),
      nextBuildOrder: _asStringList(json['next_build_order']),
    );
  }

  static OpsOverview fallback() {
    return const OpsOverview(
      modules: [
        OpsModule(
          name: '首页鱼情与钓法',
          status: 'online',
          area: 'frontend+backend',
          description: '首页、钓法方案、低概率挑战和现场二次分析已接入。',
          routePath: '/#/home',
          apiPrefix: '/api/v1/home',
        ),
        OpsModule(
          name: '钓点生态地图',
          status: 'online',
          area: 'frontend+backend',
          description: '发现页图层、钓场摘要和生态资源已接入。',
          routePath: '/#/explore',
          apiPrefix: '/api/v1/explore',
        ),
        OpsModule(
          name: '运营监控',
          status: 'online',
          area: 'backend+middleware',
          description: '健康检查、请求追踪和系统事件已接入。',
          routePath: '/#/profile',
          apiPrefix: '/api/v1/ops',
        ),
      ],
      layers: [
        OpsLayer(
          layerKey: 'frontend',
          name: 'Flutter 前端',
          status: 'running',
          description: '移动端页面和交互入口可用。',
        ),
        OpsLayer(
          layerKey: 'backend',
          name: 'FastAPI 后端',
          status: 'running',
          description: '核心接口按模块挂载。',
        ),
        OpsLayer(
          layerKey: 'database',
          name: '数据库',
          status: 'running',
          description: 'SQLite 本地库可用，生产可切 PostgreSQL。',
        ),
      ],
      capabilityGroups: [
        OpsCapabilityGroup(title: '找钓点', capabilities: ['地图', '收藏', '导航']),
        OpsCapabilityGroup(title: '判断鱼情', capabilities: ['天气', '钓法', '安全']),
        OpsCapabilityGroup(title: '记录复盘', capabilities: ['鱼获', '图鉴', '成就']),
      ],
      nextBuildOrder: ['钓点详情', '完整鱼获日志', '社区内容流', '生产告警'],
    );
  }
}

class OpsModule {
  const OpsModule({
    required this.name,
    required this.status,
    required this.area,
    required this.description,
    required this.routePath,
    required this.apiPrefix,
  });

  final String name;
  final String status;
  final String area;
  final String description;
  final String routePath;
  final String apiPrefix;

  factory OpsModule.fromJson(Map<String, dynamic> json) {
    return OpsModule(
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      routePath: json['route_path']?.toString() ?? '',
      apiPrefix: json['api_prefix']?.toString() ?? '',
    );
  }
}

class OpsLayer {
  const OpsLayer({
    required this.layerKey,
    required this.name,
    required this.status,
    required this.description,
  });

  final String layerKey;
  final String name;
  final String status;
  final String description;

  factory OpsLayer.fromJson(Map<String, dynamic> json) {
    return OpsLayer(
      layerKey: json['layer_key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class OpsCapabilityGroup {
  const OpsCapabilityGroup({required this.title, required this.capabilities});

  final String title;
  final List<String> capabilities;

  factory OpsCapabilityGroup.fromJson(Map<String, dynamic> json) {
    return OpsCapabilityGroup(
      title: json['title']?.toString() ?? '',
      capabilities: _asStringList(json['capabilities']),
    );
  }
}

class OpsMonitoring {
  const OpsMonitoring({
    required this.uptimeSeconds,
    required this.requestSummary,
    required this.metrics,
    required this.services,
    required this.recentRequests,
  });

  final double uptimeSeconds;
  final OpsRequestSummary requestSummary;
  final List<OpsMetric> metrics;
  final List<OpsServiceHealth> services;
  final List<OpsRequestLog> recentRequests;

  factory OpsMonitoring.fromJson(Map<String, dynamic> json) {
    return OpsMonitoring(
      uptimeSeconds: _asDouble(json['uptime_seconds']),
      requestSummary: OpsRequestSummary.fromJson(
        _asMap(json['request_summary']),
      ),
      metrics: _asList(json['metrics'], OpsMetric.fromJson),
      services: _asList(json['services'], OpsServiceHealth.fromJson),
      recentRequests: _asList(json['recent_requests'], OpsRequestLog.fromJson),
    );
  }

  static OpsMonitoring fallback() {
    return const OpsMonitoring(
      uptimeSeconds: 0,
      requestSummary: OpsRequestSummary(
        totalRequests: 0,
        averageLatencyMs: 0,
        lastLatencyMs: 0,
      ),
      metrics: [
        OpsMetric(label: '数据库', value: 'ready', unit: '', status: 'ok'),
        OpsMetric(label: '缓存', value: 'planned', unit: '', status: 'warning'),
        OpsMetric(label: 'AI 分析', value: 'rules', unit: '', status: 'ok'),
      ],
      services: [
        OpsServiceHealth(name: 'API 服务', status: 'ok', detail: '路由已加载'),
        OpsServiceHealth(name: '数据库', status: 'ok', detail: '本地库可用'),
      ],
      recentRequests: [],
    );
  }
}

class OpsRequestSummary {
  const OpsRequestSummary({
    required this.totalRequests,
    required this.averageLatencyMs,
    required this.lastLatencyMs,
  });

  final int totalRequests;
  final double averageLatencyMs;
  final double lastLatencyMs;

  factory OpsRequestSummary.fromJson(Map<String, dynamic> json) {
    return OpsRequestSummary(
      totalRequests: _asInt(json['total_requests']),
      averageLatencyMs: _asDouble(json['average_latency_ms']),
      lastLatencyMs: _asDouble(json['last_latency_ms']),
    );
  }
}

class OpsMetric {
  const OpsMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
  });

  final String label;
  final String value;
  final String unit;
  final String status;

  factory OpsMetric.fromJson(Map<String, dynamic> json) {
    return OpsMetric(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class OpsServiceHealth {
  const OpsServiceHealth({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final String status;
  final String detail;

  factory OpsServiceHealth.fromJson(Map<String, dynamic> json) {
    return OpsServiceHealth(
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class OpsRequestLog {
  const OpsRequestLog({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.durationMs,
  });

  final String method;
  final String path;
  final int statusCode;
  final double durationMs;

  factory OpsRequestLog.fromJson(Map<String, dynamic> json) {
    return OpsRequestLog(
      method: json['method']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      statusCode: _asInt(json['status_code']),
      durationMs: _asDouble(json['duration_ms']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<T> _asList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value.map((item) => fromJson(_asMap(item))).toList();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
