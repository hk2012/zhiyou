import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialContent = 0});

  final int initialContent;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late int _selectedLayer;
  int _selectedSpot = 0;
  int _zoomLevel = 2;
  bool _refreshing = false;
  bool _routeShared = false;
  String _location = '杭州西湖区';
  String? _lastSearch;
  Set<String> _filters = {'水情更新', '可停车', '钓友实况'};
  final Set<String> _favorites = {};

  final _layers = const [
    (Icons.set_meal_rounded, '鱼情'),
    (Icons.place_rounded, '钓点'),
    (Icons.event_available_rounded, '活动'),
    (Icons.sensors_rounded, '设备'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLayer = widget.initialContent.clamp(0, _layers.length - 1);
  }

  _MapSpot get _spot => _spots[_selectedSpot];

  List<_MapSpot> get _visibleSpots {
    final list = _spots.where((spot) {
      if (_filters.contains('可停车') && !spot.hasParking) return false;
      if (_filters.contains('设备在线') && !spot.deviceOnline) return false;
      if (_filters.contains('钓友实况') && !spot.live) return false;
      if (_filters.contains('安全优先') && spot.riskLevel == '高') return false;
      if (_filters.contains('路亚适配') && !spot.lureFriendly) return false;
      return true;
    }).toList();
    return list.isEmpty ? _spots : list;
  }

  Future<void> _refreshSpots() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    final visible = _visibleSpots;
    setState(() {
      _selectedSpot = _spots.indexOf(
        visible[(_selectedSpot + 1) % visible.length],
      );
      _refreshing = false;
    });
    AppFeedback.showMessage(context, '钓点已按最新鱼情重新排序');
  }

  void _changeLayer(int index) {
    if (_selectedLayer == index) return;
    setState(() => _selectedLayer = index);
    AppFeedback.showMessage(context, '已切换到${_layers[index].$2}图层');
  }

  void _zoomBy(int delta) {
    setState(() => _zoomLevel = (_zoomLevel + delta).clamp(1, 4));
    AppFeedback.showMessage(context, '地图缩放 ${_zoomLevel}x');
  }

  void _selectSpot(_MapSpot spot, {String? searchText}) {
    setState(() {
      _selectedSpot = _spots.indexOf(spot);
      _lastSearch = searchText;
    });
  }

  void _applyFilters(Set<String> filters) {
    final nextFilters = Set<String>.of(filters);
    final selected = _firstSpotForFilters(nextFilters);
    setState(() {
      _filters = nextFilters;
      _selectedSpot = _spots.indexOf(selected);
    });
    AppFeedback.showMessage(context, '已应用 ${nextFilters.length} 项筛选');
  }

  _MapSpot _firstSpotForFilters(Set<String> filters) {
    for (final spot in _spots) {
      if (filters.contains('可停车') && !spot.hasParking) continue;
      if (filters.contains('设备在线') && !spot.deviceOnline) continue;
      if (filters.contains('钓友实况') && !spot.live) continue;
      if (filters.contains('安全优先') && spot.riskLevel == '高') continue;
      if (filters.contains('路亚适配') && !spot.lureFriendly) continue;
      return spot;
    }
    return _spots.first;
  }

  void _toggleFavorite(_MapSpot spot) {
    setState(() {
      if (_favorites.contains(spot.name)) {
        _favorites.remove(spot.name);
      } else {
        _favorites.add(spot.name);
      }
    });
    AppFeedback.showMessage(
      context,
      _favorites.contains(spot.name)
          ? '${spot.name} 已收藏'
          : '${spot.name} 已取消收藏',
    );
  }

  void _showLocationSheet() {
    showInkActionSheet(
      context,
      title: '定位已同步',
      subtitle: '当前位置用于附近钓点、天气和路线规划',
      icon: Icons.my_location_rounded,
      color: InkPalette.lake,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: _location,
                label: '当前位置',
                icon: Icons.place_rounded,
                color: InkPalette.pine,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: '${_visibleSpots.length}个',
                label: '附近推荐',
                icon: Icons.radar_rounded,
                color: InkPalette.lake,
              ),
            ),
          ],
        ),
      ],
      actions: [
        for (final spot in _spots)
          InkSheetAction(
            icon: Icons.water_rounded,
            title: spot.name,
            subtitle: '${spot.distance} · ${spot.meta} · ${spot.score}分',
            color: spot.color,
            onTap: () {
              setState(() {
                _location = spot.area;
                _selectedSpot = _spots.indexOf(spot);
              });
              AppFeedback.showMessage(context, '已定位到 ${spot.area}');
            },
          ),
      ],
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _MapSearchSheet(
        spots: _spots,
        onSelect: (spot, label) {
          Navigator.of(context).pop();
          _selectSpot(spot, searchText: label);
          AppFeedback.showMessage(context, '已定位搜索结果：${spot.name}');
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _MapFilterSheet(
        initialFilters: _filters,
        onApply: (filters) {
          Navigator.of(context).pop();
          _applyFilters(filters);
        },
      ),
    );
  }

  void _showSpotSheet(_MapSpot spot) {
    showInkActionSheet(
      context,
      title: spot.name,
      subtitle: '${spot.distance} · ${spot.meta} · 推荐分 ${spot.score}',
      icon: Icons.place_rounded,
      color: spot.color,
      showLandscape: true,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: '${spot.score}%',
                label: '中鱼率',
                icon: Icons.auto_graph_rounded,
                color: spot.color,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: spot.riskLevel,
                label: '岸边风险',
                icon: spot.riskLevel == '高'
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                color: spot.riskLevel == '高'
                    ? InkPalette.cinnabar
                    : InkPalette.moss,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _SpotInsightCard(spot: spot),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.near_me_rounded,
          title: '开始导航',
          subtitle: '同步停车点与岸边路线',
          color: InkPalette.pine,
          onTap: () => _showRouteSheet(spot),
        ),
        InkSheetAction(
          icon: _favorites.contains(spot.name)
              ? Icons.bookmark_added_rounded
              : Icons.bookmark_add_rounded,
          title: _favorites.contains(spot.name) ? '取消收藏' : '收藏钓点',
          subtitle: _favorites.contains(spot.name) ? '从我的收藏移除' : '保存到我的收藏',
          color: InkPalette.moss,
          onTap: () => _toggleFavorite(spot),
        ),
        InkSheetAction(
          icon: Icons.warning_amber_rounded,
          title: '查看风险',
          subtitle: '水位、天气和岸边安全提醒',
          color: InkPalette.cinnabar,
          onTap: () => _showRiskSheet(spot),
        ),
        InkSheetAction(
          icon: Icons.add_photo_alternate_rounded,
          title: '记录鱼获',
          subtitle: '带入当前钓点生成鱼获档案',
          color: InkPalette.lake,
          onTap: () => context.push(AppRouteNames.creationModal),
        ),
      ],
    );
  }

  void _showRiskSheet(_MapSpot spot) {
    showInkActionSheet(
      context,
      title: '${spot.name} · 风险提醒',
      subtitle: spot.riskText,
      icon: Icons.warning_amber_rounded,
      color: spot.riskLevel == '高' ? InkPalette.cinnabar : InkPalette.reed,
      children: [
        InkSafetyAlertCard(
          icon: Icons.warning_amber_rounded,
          title: '${spot.name} · ${spot.riskLevel}风险',
          subtitle: spot.riskText,
          color: spot.riskLevel == '高' ? InkPalette.cinnabar : InkPalette.reed,
          onTap: () => AppFeedback.showMessage(context, '已阅读风险提醒'),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: spot.riskLevel,
                label: '风险等级',
                icon: Icons.security_rounded,
                color: spot.riskLevel == '高'
                    ? InkPalette.cinnabar
                    : InkPalette.reed,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: spot.window,
                label: '建议窗口',
                icon: Icons.schedule_rounded,
                color: spot.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _RiskChecklist(spot: spot),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.route_rounded,
          title: '避险路线',
          subtitle: '${spot.parking} · 岸边路线已避开湿滑区',
          color: spot.color,
          onTap: () => _showRouteSheet(spot),
        ),
        InkSheetAction(
          icon: Icons.notifications_active_rounded,
          title: '保留风险提醒',
          subtitle: '到点前提醒水位、风浪和撤离路线',
          color: InkPalette.moss,
          onTap: () => AppFeedback.showMessage(context, '已保留该钓点风险提醒'),
        ),
      ],
    );
  }

  void _showFishDistributionSheet(_MapSpot spot) {
    showInkActionSheet(
      context,
      title: '${spot.name} · 鱼群分布',
      subtitle: '整合设备探测、钓友实况和历史鱼获形成热区判断',
      icon: Icons.set_meal_rounded,
      color: InkPalette.reed,
      children: [
        _FishDistributionBars(stats: spot.fishStats),
        SizedBox(height: 10.h),
        _SpotInsightCard(spot: spot),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.sensors_rounded,
          title: '同步设备探测',
          subtitle: spot.deviceOnline ? '设备在线，可刷新水情' : '附近无在线设备，使用历史估算',
          color: InkPalette.pine,
          onTap: () => _showSpotSyncSheet(spot),
        ),
        InkSheetAction(
          icon: Icons.auto_awesome_rounded,
          title: '生成钓法建议',
          subtitle: spot.methodHint,
          color: InkPalette.lake,
          onTap: () =>
              AppFeedback.showMessage(context, '已按 ${spot.mainFish} 生成钓法建议'),
        ),
      ],
    );
  }

  void _showRouteSheet(_MapSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _RoutePlanSheet(
        spot: spot,
        shared: _routeShared,
        onNavigate: () {
          Navigator.of(context).pop();
          AppFeedback.showMessage(context, '已开始导航到 ${spot.name}');
        },
        onShare: () {
          setState(() => _routeShared = true);
          Navigator.of(context).pop();
          AppFeedback.showMessage(context, '行程已分享给钓友');
        },
        onSave: () {
          Navigator.of(context).pop();
          AppFeedback.showMessage(context, '出钓计划已保存');
        },
      ),
    );
  }

  void _showSpotSyncSheet(_MapSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _SpotSyncSheet(spot: spot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSpots = _visibleSpots;
    final spot = _spot;

    return InkPage(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 116.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkTopBar(
              title: '钓点',
              subtitle: '山水地图 · 鱼情热区 · 服务承接',
              leading: Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: InkPalette.mist,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: InkPalette.pine,
                  size: 22.w,
                ),
              ),
              actions: [
                InkRoundButton(
                  icon: Icons.my_location_rounded,
                  onTap: _showLocationSheet,
                ),
                InkRoundButton(
                  icon: Icons.tune_rounded,
                  onTap: _showFilterSheet,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
              child: InkSearchBox(
                hint: _lastSearch == null
                    ? '搜索钓点、鱼种、活动或装备'
                    : '$_lastSearch · 已定位',
                onTap: _showSearchSheet,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                itemCount: _layers.length,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final layer = _layers[index];
                  return InkChip(
                    icon: layer.$1,
                    label: layer.$2,
                    active: _selectedLayer == index,
                    color: _colorForLayer(index),
                    onTap: () => _changeLayer(index),
                  );
                },
              ),
            ),
            if (_refreshing)
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                child: _MapRefreshingBanner(layer: _layers[_selectedLayer].$2),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: Stack(
                children: [
                  InkMiniMap(height: 386, selectedIndex: _selectedSpot),
                  Positioned(
                    left: 14.w,
                    top: 14.h,
                    child: InkChip(
                      icon: Icons.water_rounded,
                      label: '$_location · ${_zoomLevel}x',
                      active: true,
                      color: InkPalette.pine,
                    ),
                  ),
                  Positioned(
                    right: 14.w,
                    top: 14.h,
                    child: Column(
                      children: [
                        InkRoundButton(
                          icon: Icons.add_rounded,
                          onTap: () => _zoomBy(1),
                        ),
                        SizedBox(height: 8.h),
                        InkRoundButton(
                          icon: Icons.remove_rounded,
                          onTap: () => _zoomBy(-1),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12.w,
                    right: 12.w,
                    bottom: 12.h,
                    child: _MapSpotOverlay(
                      spot: spot,
                      layer: _layers[_selectedLayer].$2,
                      favorite: _favorites.contains(spot.name),
                      onTap: () => _showSpotSheet(spot),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: _MapDataStrip(
                spot: spot,
                layer: _layers[_selectedLayer].$2,
              ),
            ),
            InkSectionHeader(
              title: '推荐钓点',
              subtitle: '根据鱼情、距离和安全状态排序',
              action: '刷新',
              onAction: _refreshSpots,
            ),
            SizedBox(
              height: 190.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                physics: const BouncingScrollPhysics(),
                itemCount: visibleSpots.length,
                separatorBuilder: (_, _) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final item = visibleSpots[index];
                  final sourceIndex = _spots.indexOf(item);
                  return _SpotPreviewCard(
                    spot: item,
                    selected: _selectedSpot == sourceIndex,
                    favorite: _favorites.contains(item.name),
                    onTap: () {
                      if (_selectedSpot == sourceIndex) {
                        _showSpotSheet(item);
                        return;
                      }
                      setState(() => _selectedSpot = sourceIndex);
                    },
                  );
                },
              ),
            ),
            const InkSectionHeader(title: '路线与安全', subtitle: '出发前确认天气、水位和撤离路线'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  _RoutePlanCard(
                    spot: spot,
                    onPlan: () => _showRouteSheet(spot),
                    onRisk: () => _showRiskSheet(spot),
                  ),
                  SizedBox(height: 12.h),
                  _FishDistributionCard(
                    spot: spot,
                    onTap: () => _showFishDistributionSheet(spot),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForLayer(int index) {
    return switch (index) {
      0 => InkPalette.pine,
      1 => InkPalette.lake,
      2 => InkPalette.reed,
      _ => InkPalette.moss,
    };
  }
}

class _MapSpotOverlay extends StatelessWidget {
  const _MapSpotOverlay({
    required this.spot,
    required this.layer,
    required this.favorite,
    required this.onTap,
  });

  final _MapSpot spot;
  final String layer;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkGlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (favorite) ...[
                Icon(
                  Icons.bookmark_rounded,
                  color: InkPalette.reed,
                  size: 17.w,
                ),
                SizedBox(width: 5.w),
              ],
              InkChip(label: '${spot.score}分', active: true, color: spot.color),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            '$layer图层 · ${spot.distance} · ${spot.meta} · ${spot.liveUpdate}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final tag in spot.tags)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: spot.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: spot.color,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapDataStrip extends StatelessWidget {
  const _MapDataStrip({super.key, required this.spot, required this.layer});

  final _MapSpot spot;
  final String layer;

  @override
  Widget build(BuildContext context) {
    final third = switch (layer) {
      '活动' => (
        '${spot.routeMinutes + 12}分',
        '活动距离',
        Icons.event_available_rounded,
        InkPalette.reed,
      ),
      '设备' => (
        spot.deviceOnline ? '在线' : '离线',
        '设备',
        Icons.sensors_rounded,
        InkPalette.moss,
      ),
      '钓点' => (
        spot.parking,
        '停车',
        Icons.local_parking_rounded,
        InkPalette.pine,
      ),
      _ => (spot.fishActivity, '鱼群', Icons.set_meal_rounded, InkPalette.reed),
    };

    return Row(
      children: [
        Expanded(
          child: InkMetric(
            value: spot.waterTemp,
            label: '实时水温',
            icon: Icons.water_drop_rounded,
            color: InkPalette.lake,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: InkMetric(
            value: spot.depth,
            label: '水深',
            icon: Icons.straighten_rounded,
            color: InkPalette.pine,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: InkMetric(
            value: third.$1,
            label: third.$2,
            icon: third.$3,
            color: third.$4,
          ),
        ),
      ],
    );
  }
}

class _MapRefreshingBanner extends StatelessWidget {
  const _MapRefreshingBanner({required this.layer});

  final String layer;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color: InkPalette.pine.withValues(alpha: 0.10),
      borderColor: InkPalette.pine.withValues(alpha: 0.14),
      child: Row(
        children: [
          const InkTaijiLoader(size: 28, label: ''),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '正在刷新$layer图层与附近鱼情',
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotPreviewCard extends StatelessWidget {
  const _SpotPreviewCard({
    required this.spot,
    required this.selected,
    required this.favorite,
    required this.onTap,
  });

  final _MapSpot spot;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 254.w,
      child: InkCard(
        padding: EdgeInsets.all(11.r),
        borderColor: selected ? spot.color : InkPalette.line,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spot.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (favorite)
                  Icon(
                    Icons.bookmark_rounded,
                    color: InkPalette.reed,
                    size: 16.w,
                  ),
                if (favorite) SizedBox(width: 5.w),
                InkChip(
                  label: '${spot.score}分',
                  active: true,
                  color: selected ? spot.color : InkPalette.lake,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '${spot.distance} · ${spot.meta}',
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: InkLandscapeHero(
                    height: 66,
                    bright: true,
                    title: '',
                    subtitle: '',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: InkLandscapeHero(
                    height: 66,
                    bright: false,
                    title: '',
                    subtitle: '',
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                for (final tag in spot.tags.take(3))
                  Text(
                    '#$tag',
                    style: TextStyle(
                      color: spot.color,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FishDistributionCard extends StatelessWidget {
  const _FishDistributionCard({required this.spot, required this.onTap});

  final _MapSpot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      onTap: onTap,
      child: Column(
        children: [
          InkInfoRow(
            icon: Icons.radar_rounded,
            title: '鱼群分布与设备水情',
            subtitle: '${spot.mainFish}热区 · ${spot.methodHint}',
            trailing: '详情',
            color: InkPalette.reed,
          ),
          SizedBox(height: 12.h),
          _FishDistributionBars(stats: spot.fishStats),
        ],
      ),
    );
  }
}

class _FishDistributionBars extends StatelessWidget {
  const _FishDistributionBars({required this.stats});

  final List<_FishStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _FishBar(stat: stats[i])),
          if (i != stats.length - 1) SizedBox(width: 10.w),
        ],
      ],
    );
  }
}

class _FishBar extends StatelessWidget {
  const _FishBar({required this.stat});

  final _FishStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          style: TextStyle(
            color: InkPalette.text,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: stat.value,
            minHeight: 8.h,
            color: stat.color,
            backgroundColor: InkPalette.line.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _RoutePlanCard extends StatelessWidget {
  const _RoutePlanCard({
    required this.spot,
    required this.onPlan,
    required this.onRisk,
  });

  final _MapSpot spot;
  final VoidCallback onPlan;
  final VoidCallback onRisk;

  @override
  Widget build(BuildContext context) {
    return InkGlassCard(
      child: Column(
        children: [
          InkInfoRow(
            icon: Icons.route_rounded,
            title: '前往 ${spot.name}',
            subtitle: '预计 ${spot.routeMinutes} 分钟到达，${spot.parking}',
            trailing: '导航',
            color: InkPalette.pine,
          ),
          SizedBox(height: 12.h),
          InkSafetyAlertCard(
            icon: Icons.warning_amber_rounded,
            title: '安全提醒 · ${spot.riskLevel}',
            subtitle: spot.riskText,
            color: spot.riskLevel == '高'
                ? InkPalette.cinnabar
                : InkPalette.reed,
            onTap: onRisk,
          ),
          SizedBox(height: 12.h),
          InkPrimaryButton(
            label: '生成出钓计划',
            icon: Icons.event_note_rounded,
            color: spot.color,
            onTap: onPlan,
          ),
        ],
      ),
    );
  }
}

class _SpotInsightCard extends StatelessWidget {
  const _SpotInsightCard({required this.spot});

  final _MapSpot spot;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.schedule_rounded, '窗口', spot.window, spot.color),
      (Icons.set_meal_rounded, '主攻', spot.mainFish, InkPalette.lake),
      (Icons.inventory_2_rounded, '钓法', spot.methodHint, InkPalette.reed),
    ];

    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.84),
      borderColor: spot.color.withValues(alpha: 0.16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                Icon(rows[i].$1, color: rows[i].$4, size: 16.w),
                SizedBox(width: 7.w),
                SizedBox(
                  width: 42.w,
                  child: Text(
                    rows[i].$2,
                    style: TextStyle(
                      color: InkPalette.muted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (i != rows.length - 1) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

class _RiskChecklist extends StatelessWidget {
  const _RiskChecklist({required this.spot});

  final _MapSpot spot;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.water_rounded, '水位', spot.riskText),
      (Icons.local_parking_rounded, '停车', spot.parking),
      (Icons.block_rounded, '避开', spot.avoid),
    ];

    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.84),
      borderColor: InkPalette.cinnabar.withValues(alpha: 0.16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(items[i].$1, color: InkPalette.cinnabar, size: 16.w),
                SizedBox(width: 7.w),
                SizedBox(
                  width: 42.w,
                  child: Text(
                    items[i].$2,
                    style: TextStyle(
                      color: InkPalette.muted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i].$3,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 12.sp,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

class _MapSearchSheet extends StatelessWidget {
  const _MapSearchSheet({required this.spots, required this.onSelect});

  final List<_MapSpot> spots;
  final void Function(_MapSpot spot, String label) onSelect;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      _SearchSuggestion(
        icon: Icons.set_meal_rounded,
        title: '翘嘴 · 路亚',
        subtitle: '优先看清晨窗口和路亚适配点',
        spot: spots[1],
        color: InkPalette.lake,
      ),
      _SearchSuggestion(
        icon: Icons.place_rounded,
        title: '免费钓点',
        subtitle: '过滤收费钓场与限制水域',
        spot: spots[0],
        color: InkPalette.moss,
      ),
      _SearchSuggestion(
        icon: Icons.sensors_rounded,
        title: '设备在线',
        subtitle: '查看有实时水情的钓点',
        spot: spots.firstWhere((spot) => spot.deviceOnline),
        color: InkPalette.reed,
      ),
      _SearchSuggestion(
        icon: Icons.warning_amber_rounded,
        title: '安全优先',
        subtitle: '适合新手、停车近、岸线风险低',
        spot: spots.first,
        color: InkPalette.pine,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: InkPalette.ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              InkInfoRow(
                icon: Icons.search_rounded,
                title: '地图搜索',
                subtitle: '按钓点、鱼种、玩法、设备和安全状态快速定位',
                color: InkPalette.pine,
              ),
              SizedBox(height: 12.h),
              for (var i = 0; i < suggestions.length; i++) ...[
                _SearchSuggestionCard(
                  suggestion: suggestions[i],
                  onTap: () =>
                      onSelect(suggestions[i].spot, suggestions[i].title),
                ),
                if (i != suggestions.length - 1) SizedBox(height: 9.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.spot,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _MapSpot spot;
  final Color color;
}

class _SearchSuggestionCard extends StatelessWidget {
  const _SearchSuggestionCard({required this.suggestion, required this.onTap});

  final _SearchSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.paper.withValues(alpha: 0.72),
      borderColor: suggestion.color.withValues(alpha: 0.14),
      onTap: onTap,
      child: InkInfoRow(
        icon: suggestion.icon,
        title: suggestion.title,
        subtitle: '${suggestion.subtitle} · ${suggestion.spot.name}',
        trailing: '定位',
        color: suggestion.color,
      ),
    );
  }
}

class _MapFilterSheet extends StatefulWidget {
  const _MapFilterSheet({required this.initialFilters, required this.onApply});

  final Set<String> initialFilters;
  final ValueChanged<Set<String>> onApply;

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late final Set<String> _selected;

  final _options = const [
    _FilterOption(
      Icons.water_rounded,
      '水情更新',
      '优先显示 30 分钟内更新水域',
      InkPalette.lake,
    ),
    _FilterOption(
      Icons.local_parking_rounded,
      '可停车',
      '停车点距岸边 300m 内',
      InkPalette.moss,
    ),
    _FilterOption(
      Icons.groups_rounded,
      '钓友实况',
      '最近 2 小时有动态或鱼获',
      InkPalette.reed,
    ),
    _FilterOption(Icons.verified_rounded, '安全优先', '过滤高风险岸线', InkPalette.pine),
    _FilterOption(
      Icons.alt_route_rounded,
      '路亚适配',
      '桥墩、浅滩、回水口优先',
      InkPalette.lake,
    ),
    _FilterOption(Icons.sensors_rounded, '设备在线', '附近有实时水情设备', InkPalette.moss),
  ];

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.of(widget.initialFilters);
  }

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: InkPalette.ink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              InkInfoRow(
                icon: Icons.tune_rounded,
                title: '地图筛选',
                subtitle: '组合水情、停车、实况、安全和玩法偏好',
                color: InkPalette.pine,
              ),
              SizedBox(height: 12.h),
              for (var i = 0; i < _options.length; i++) ...[
                _FilterOptionRow(
                  option: _options[i],
                  active: _selected.contains(_options[i].label),
                  onTap: () => _toggle(_options[i].label),
                ),
                if (i != _options.length - 1) SizedBox(height: 9.h),
              ],
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: InkPressable(
                      onTap: () => setState(_selected.clear),
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: InkPalette.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: InkPalette.ink.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '清空',
                            style: TextStyle(
                              color: InkPalette.pine,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: InkPrimaryButton(
                      label: '应用筛选',
                      icon: Icons.done_rounded,
                      onTap: () => widget.onApply(_selected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.icon, this.label, this.subtitle, this.color);

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final _FilterOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: active
          ? option.color.withValues(alpha: 0.09)
          : InkPalette.paper.withValues(alpha: 0.72),
      borderColor: option.color.withValues(alpha: active ? 0.22 : 0.12),
      onTap: onTap,
      child: Row(
        children: [
          InkIconMark(icon: option.icon, color: option.color, size: 38),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  option.subtitle,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: active ? option.color : InkPalette.white,
              shape: BoxShape.circle,
              border: Border.all(color: option.color.withValues(alpha: 0.38)),
            ),
            child: active
                ? Icon(Icons.done_rounded, color: InkPalette.white, size: 17.w)
                : null,
          ),
        ],
      ),
    );
  }
}

class _RoutePlanSheet extends StatefulWidget {
  const _RoutePlanSheet({
    required this.spot,
    required this.shared,
    required this.onNavigate,
    required this.onShare,
    required this.onSave,
  });

  final _MapSpot spot;
  final bool shared;
  final VoidCallback onNavigate;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  State<_RoutePlanSheet> createState() => _RoutePlanSheetState();
}

class _RoutePlanSheetState extends State<_RoutePlanSheet> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List<bool>.filled(4, false);
  }

  int get _done => _checked.where((item) => item).length;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_rounded, '装备', '鱼竿、抄网、防滑鞋、雨具、电池'),
      (Icons.schedule_rounded, '时间', '建议 ${widget.spot.window} 到达第一窗口'),
      (Icons.local_parking_rounded, '停车', widget.spot.parking),
      (Icons.warning_amber_rounded, '安全', widget.spot.riskText),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: InkPalette.ink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  InkIconMark(
                    icon: Icons.event_note_rounded,
                    color: widget.spot.color,
                    size: 42,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '出钓计划',
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          '${widget.spot.name} · ${widget.spot.routeMinutes} 分钟到达 · $_done/4 已确认',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.muted,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkChip(
                    label: widget.shared ? '已分享' : '待确认',
                    active: true,
                    color: widget.shared ? InkPalette.moss : widget.spot.color,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              for (var i = 0; i < items.length; i++) ...[
                _RouteChecklistRow(
                  icon: items[i].$1,
                  title: items[i].$2,
                  subtitle: items[i].$3,
                  color: widget.spot.color,
                  checked: _checked[i],
                  onTap: () => setState(() => _checked[i] = !_checked[i]),
                ),
                if (i != items.length - 1) SizedBox(height: 9.h),
              ],
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: InkPrimaryButton(
                      label: '开始导航',
                      icon: Icons.near_me_rounded,
                      color: widget.spot.color,
                      onTap: widget.onNavigate,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: InkPrimaryButton(
                      label: '分享行程',
                      icon: Icons.share_location_rounded,
                      color: InkPalette.moss,
                      onTap: widget.onShare,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              InkPressable(
                onTap: widget.onSave,
                child: Text(
                  '保存到今日计划',
                  style: TextStyle(
                    color: InkPalette.pine,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteChecklistRow extends StatelessWidget {
  const _RouteChecklistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.checked,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: checked
          ? color.withValues(alpha: 0.09)
          : InkPalette.paper.withValues(alpha: 0.72),
      borderColor: color.withValues(alpha: checked ? 0.22 : 0.12),
      onTap: onTap,
      child: Row(
        children: [
          InkIconMark(icon: icon, color: color, size: 36),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: checked ? color : InkPalette.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.38)),
            ),
            child: checked
                ? Icon(Icons.done_rounded, color: InkPalette.white, size: 16.w)
                : null,
          ),
        ],
      ),
    );
  }
}

class _SpotSyncSheet extends StatefulWidget {
  const _SpotSyncSheet({required this.spot});

  final _MapSpot spot;

  @override
  State<_SpotSyncSheet> createState() => _SpotSyncSheetState();
}

class _SpotSyncSheetState extends State<_SpotSyncSheet> {
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 780), () {
      if (!mounted) return;
      setState(() => _syncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: InkPalette.ink.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  InkIconMark(
                    icon: _syncing
                        ? Icons.sync_rounded
                        : Icons.cloud_done_rounded,
                    color: widget.spot.color,
                    size: 42,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _syncing ? '正在同步水情' : '水情同步完成',
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          _syncing
                              ? '读取附近设备、钓友实况和历史鱼获'
                              : '${widget.spot.name} 已刷新为最新热区判断',
                          style: TextStyle(
                            color: InkPalette.muted,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _syncing
                    ? const InkTaijiLoader(size: 44, label: '同步中')
                    : _MapDataStrip(
                        key: const ValueKey('synced-data'),
                        spot: widget.spot,
                        layer: '设备',
                      ),
              ),
              if (!_syncing) ...[
                SizedBox(height: 14.h),
                InkPrimaryButton(
                  label: '完成',
                  icon: Icons.done_rounded,
                  color: widget.spot.color,
                  onTap: () {
                    Navigator.of(context).pop();
                    AppFeedback.showMessage(context, '钓点水情已同步');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSpot {
  const _MapSpot({
    required this.name,
    required this.area,
    required this.distance,
    required this.meta,
    required this.score,
    required this.tags,
    required this.waterTemp,
    required this.depth,
    required this.fishActivity,
    required this.routeMinutes,
    required this.parking,
    required this.window,
    required this.riskLevel,
    required this.riskText,
    required this.avoid,
    required this.liveUpdate,
    required this.mainFish,
    required this.methodHint,
    required this.color,
    required this.hasParking,
    required this.deviceOnline,
    required this.live,
    required this.lureFriendly,
    required this.fishStats,
  });

  final String name;
  final String area;
  final String distance;
  final String meta;
  final int score;
  final List<String> tags;
  final String waterTemp;
  final String depth;
  final String fishActivity;
  final int routeMinutes;
  final String parking;
  final String window;
  final String riskLevel;
  final String riskText;
  final String avoid;
  final String liveUpdate;
  final String mainFish;
  final String methodHint;
  final Color color;
  final bool hasParking;
  final bool deviceOnline;
  final bool live;
  final bool lureFriendly;
  final List<_FishStat> fishStats;
}

class _FishStat {
  const _FishStat(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

const _spots = [
  _MapSpot(
    name: '西湖 · 花港观鱼',
    area: '杭州西湖区',
    distance: '3.2km',
    meta: '岸钓点 · 草边',
    score: 82,
    tags: ['鲫鱼', '免费', '适合新手'],
    waterTemp: '18.6°C',
    depth: '1.25m',
    fishActivity: '活跃',
    routeMinutes: 18,
    parking: '停车点 120m',
    window: '06:10-08:20',
    riskLevel: '低',
    riskText: '岸边平缓，水位稳定，注意游客和湿滑石阶。',
    avoid: '不要在人多区域长竿横摆',
    liveUpdate: '18 分钟前有钓友更新',
    mainFish: '鲫鱼',
    methodHint: '短竿草边小窝',
    color: InkPalette.pine,
    hasParking: true,
    deviceOnline: true,
    live: true,
    lureFriendly: false,
    fishStats: [
      _FishStat('鲫鱼', 0.82, InkPalette.pine),
      _FishStat('白条', 0.62, InkPalette.lake),
      _FishStat('鲤鱼', 0.36, InkPalette.reed),
    ],
  ),
  _MapSpot(
    name: '湘湖 · 下孙文化村',
    area: '杭州萧山区',
    distance: '5.6km',
    meta: '缓流水域 · 路亚',
    score: 76,
    tags: ['翘嘴', '停车', '清晨佳'],
    waterTemp: '19.4°C',
    depth: '1.8m',
    fishActivity: '上浮',
    routeMinutes: 26,
    parking: '停车点 260m',
    window: '05:40-07:50',
    riskLevel: '中',
    riskText: '清晨露水重，木栈道湿滑，建议穿防滑鞋。',
    avoid: '不要站到低矮亲水台远投',
    liveUpdate: '32 分钟前有路亚追口',
    mainFish: '翘嘴',
    methodHint: '亮片快搜浅滩外沿',
    color: InkPalette.lake,
    hasParking: true,
    deviceOnline: true,
    live: true,
    lureFriendly: true,
    fishStats: [
      _FishStat('翘嘴', 0.76, InkPalette.lake),
      _FishStat('鲈鱼', 0.58, InkPalette.pine),
      _FishStat('鲫鱼', 0.44, InkPalette.reed),
    ],
  ),
  _MapSpot(
    name: '钱塘江支流湾',
    area: '钱塘江支流',
    distance: '8.1km',
    meta: '回湾 · 水深 1.8m',
    score: 71,
    tags: ['鳜鱼', '风浪小', '谨慎涉水'],
    waterTemp: '20.1°C',
    depth: '2.4m',
    fishActivity: '分散',
    routeMinutes: 34,
    parking: '停车点 420m',
    window: '16:30-18:50',
    riskLevel: '高',
    riskText: '雨后支流水位变化快，陡坡泥滑，不建议涉水。',
    avoid: '不要下陡坡和踩低洼石板',
    liveUpdate: '1 小时前有回水口鱼情',
    mainFish: '鳜鱼',
    methodHint: '贴结构慢搜，短打回水边',
    color: InkPalette.cinnabar,
    hasParking: false,
    deviceOnline: false,
    live: true,
    lureFriendly: true,
    fishStats: [
      _FishStat('鳜鱼', 0.52, InkPalette.cinnabar),
      _FishStat('鲤鱼', 0.48, InkPalette.reed),
      _FishStat('黄颡', 0.41, InkPalette.moss),
    ],
  ),
  _MapSpot(
    name: '青山湖 · 北岸浅滩',
    area: '临安青山湖',
    distance: '12.4km',
    meta: '浅滩 · 开阔水面',
    score: 68,
    tags: ['露营', '路亚', '看风向'],
    waterTemp: '18.9°C',
    depth: '1.6m',
    fishActivity: '晨口',
    routeMinutes: 42,
    parking: '停车点 180m',
    window: '05:50-08:10',
    riskLevel: '中',
    riskText: '开阔水面起风快，风浪大时不建议远投。',
    avoid: '不要顶强侧风抛投',
    liveUpdate: '今天 06:40 有鱼获记录',
    mainFish: '鲈鱼',
    methodHint: '米诺慢控，先找风线',
    color: InkPalette.moss,
    hasParking: true,
    deviceOnline: false,
    live: false,
    lureFriendly: true,
    fishStats: [
      _FishStat('鲈鱼', 0.66, InkPalette.moss),
      _FishStat('翘嘴', 0.54, InkPalette.lake),
      _FishStat('鲫鱼', 0.39, InkPalette.reed),
    ],
  ),
];
