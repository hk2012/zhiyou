import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/venue_mock_data.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialContent = 0,
    this.initialSpot,
    this.initialFish,
    this.initialWindow,
    this.initialHint,
    this.initialIntent,
    this.entry,
  });

  final int initialContent;
  final String? initialSpot;
  final String? initialFish;
  final String? initialWindow;
  final String? initialHint;
  final String? initialIntent;
  final String? entry;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

String _routeContextKeyFor(ExploreScreen widget) {
  final values =
      [
            widget.entry,
            widget.initialIntent,
            widget.initialSpot,
            widget.initialFish,
            widget.initialWindow,
            widget.initialHint,
          ]
          .where((value) => value != null && value.trim().isNotEmpty)
          .map((value) => value!.trim())
          .join('|');
  return values;
}

class _ExploreScreenState extends State<ExploreScreen> {
  final Set<String> _filters = {'bookable', 'device_friendly'};
  String _searchQuery = '';
  String _sortId = 'nearest';
  bool _loading = false;
  bool _networkError = false;
  bool _locationGranted = true;
  String? _appliedRouteContextKey;

  @override
  void initState() {
    super.initState();
    _applyRouteContext();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_routeContextKeyFor(widget) != _routeContextKeyFor(oldWidget)) {
      setState(_applyRouteContext);
    }
  }

  bool get _hasRouteContext => _routeContextKeyFor(widget).isNotEmpty;

  void _applyRouteContext() {
    final key = _routeContextKeyFor(widget);
    if (key.isEmpty || key == _appliedRouteContextKey) return;
    _appliedRouteContextKey = key;

    final fish = widget.initialFish?.trim();
    if (fish != null && fish.isNotEmpty) {
      _filters.add('fish_$fish');
      _sortId = 'today_good';
    }
    if (widget.initialIntent == 'booking' || widget.initialIntent == 'route') {
      _sortId = 'today_good';
    }
    _searchQuery = '';
    _networkError = false;
    _locationGranted = true;
  }

  List<FishingVenue> get _visibleVenues {
    final query = _searchQuery.trim().toLowerCase();
    final venues = fishingVenues.where((venue) {
      if (query.isNotEmpty) {
        final matched =
            venue.name.toLowerCase().contains(query) ||
            venue.area.toLowerCase().contains(query) ||
            venue.fishSpecies.any(
              (item) => item.toLowerCase().contains(query),
            ) ||
            venue.tags.any((item) => item.toLowerCase().contains(query)) ||
            venue.sceneTypes.any((item) => item.toLowerCase().contains(query));
        if (!matched) return false;
      }
      for (final filter in _filters) {
        if (!venue.matchesFilter(filter)) return false;
      }
      return true;
    }).toList();

    switch (_sortId) {
      case 'popular':
        venues.sort((a, b) => b.popularity.compareTo(a.popularity));
      case 'today_good':
        venues.sort((a, b) => b.todayIndex.compareTo(a.todayIndex));
      default:
        venues.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return venues;
  }

  FishingVenue get _featuredVenue {
    final visible = _visibleVenues;
    return visible.isEmpty ? recommendedVenues().first : visible.first;
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _networkError = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() => _loading = false);
    AppFeedback.showMessage(context, '已刷新附近钓场和设备鱼情');
  }

  void _applyFilter(String filterId) {
    setState(() {
      if (filterId == 'nearest' || filterId == 'popular') {
        _sortId = filterId;
        return;
      }
      if (_filters.contains(filterId)) {
        _filters.remove(filterId);
      } else {
        _filters.add(filterId);
      }
    });
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _VenueSearchSheet(
        initialQuery: _searchQuery,
        onSearch: (query) {
          Navigator.of(context).pop();
          setState(() => _searchQuery = query.trim());
        },
        onSelect: (venue) {
          Navigator.of(context).pop();
          setState(() => _searchQuery = venue.name);
        },
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _VenueFilterSheet(
        selected: _filters,
        sortId: _sortId,
        onApply: (filters, sortId) {
          Navigator.of(context).pop();
          setState(() {
            _filters
              ..clear()
              ..addAll(filters);
            _sortId = sortId;
          });
          AppFeedback.showMessage(context, '已应用 ${filters.length + 1} 项筛选');
        },
      ),
    );
  }

  void _openDetail(FishingVenue venue) {
    context.push(
      '${AppRouteNames.spotDetail}?name=${Uri.encodeComponent(venue.name)}',
    );
  }

  void _openBooking(FishingVenue venue) {
    if (!_locationGranted) {
      AppFeedback.showMessage(context, '请先允许定位后再预约附近钓位');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _BookingSheet(venue: venue),
    );
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchQuery = '';
      _filters
        ..clear()
        ..addAll({'bookable', 'device_friendly'});
      _sortId = 'nearest';
      _networkError = false;
      _locationGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final venues = _visibleVenues;
    final featured = _featuredVenue;

    return InkPage(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: InkPalette.pine,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 92.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkTopBar(
                title: '选钓点',
                subtitle:
                    '${venueSummary.location} · ${venueSummary.updatedAt}',
                leading: Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: InkPalette.lake.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(
                    Icons.place_rounded,
                    color: InkPalette.lake,
                    size: 22.w,
                  ),
                ),
                actions: [
                  InkRoundButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      setState(() => _locationGranted = !_locationGranted);
                      AppFeedback.showMessage(
                        context,
                        _locationGranted ? '定位已恢复' : '已模拟定位未授权',
                      );
                    },
                  ),
                  InkRoundButton(icon: Icons.tune_rounded, onTap: _openFilters),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 5.h, 18.w, 0),
                child: _LocationSearchCard(
                  query: _searchQuery,
                  locationGranted: _locationGranted,
                  onSearch: _openSearch,
                  onLocationTap: () {
                    setState(() => _locationGranted = true);
                    AppFeedback.showMessage(context, '已同步当前位置');
                  },
                ),
              ),
              if (_hasRouteContext)
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 7.h, 18.w, 0),
                  child: _ExploreRouteContextCard(
                    venue: featured,
                    fish: widget.initialFish,
                    window: widget.initialWindow,
                    hint: widget.initialHint,
                    intent: widget.initialIntent,
                    onTap: widget.initialIntent == 'booking'
                        ? () => _openBooking(featured)
                        : () => _openDetail(featured),
                  ),
                ),
              if (!_locationGranted)
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                  child: _VenueStateCard(
                    icon: Icons.location_off_rounded,
                    title: '定位未授权',
                    message: '开启定位后可推荐附近钓场、导航路线和可预约钓位。',
                    actionLabel: '开启定位',
                    color: InkPalette.reed,
                    onAction: () => setState(() => _locationGranted = true),
                  ),
                ),
              if (_networkError)
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                  child: _VenueStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: '网络错误',
                    message: '钓场列表暂时无法同步，已保留本地推荐数据。',
                    actionLabel: '重试',
                    color: InkPalette.cinnabar,
                    onAction: _refresh,
                  ),
                ),
              if (_loading)
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                  child: const _LoadingVenueCard(),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                child: _FishingIndexCard(
                  summary: venueSummary,
                  venue: featured,
                  onRefresh: _refresh,
                ),
              ),
              _QuickFilterBar(
                filters: venueFilterOptions,
                selected: _filters,
                sortId: _sortId,
                onTap: _applyFilter,
                onMore: _openFilters,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                child: _ExploreServiceDock(
                  venue: featured,
                  onOpenServices: () =>
                      _showExploreMoreSheet(context, featured),
                  onBook: () => _openBooking(featured),
                  onMall: () => context.go(AppRouteNames.mall),
                ),
              ),
              InkSectionHeader(
                title: _searchQuery.isEmpty ? '更多钓点' : '搜索结果',
                subtitle: _searchQuery.isEmpty
                    ? '按距离和适合度排序'
                    : '匹配 $_searchQuery',
                action: '刷新',
                onAction: _refresh,
              ),
              if (venues.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: _VenueStateCard(
                    icon: Icons.search_off_rounded,
                    title: _searchQuery.isEmpty ? '筛选无结果' : '搜索无结果',
                    message: '换个鱼种、距离或预约条件，再试一次。',
                    actionLabel: '清空条件',
                    color: InkPalette.lake,
                    onAction: _clearSearchAndFilters,
                  ),
                )
              else
                SizedBox(
                  height: 254.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    itemCount: venues.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final venue = venues[index];
                      return _VenueCard(
                        venue: venue,
                        onDetail: () => _openDetail(venue),
                        onBook: () => _openBooking(venue),
                      );
                    },
                  ),
                ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

void _showExploreMoreSheet(BuildContext context, FishingVenue featured) {
  showInkActionSheet(
    context,
    title: '钓点服务',
    subtitle: '地图、活动、设备和补给放在这里',
    icon: Icons.layers_rounded,
    color: InkPalette.lake,
    showLandscape: true,
    children: [
      _VenueMapPreview(venue: featured),
      _EventSection(
        venues: fishingVenues.where((item) => item.events.isNotEmpty),
        onTap: (venue) => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: InkPalette.ink.withValues(alpha: 0.24),
          builder: (_) => _BookingSheet(venue: venue),
        ),
      ),
      _DeviceInsightSection(
        venue: featured,
        onSync: () =>
            AppFeedback.showMessage(context, '${featured.name} 设备数据已同步'),
      ),
      _MallRecommendationSection(
        venue: featured,
        onProductTap: (productId) =>
            context.push('${AppRouteNames.mallProductDetail}?id=$productId'),
        onMallTap: () => context.go(AppRouteNames.mall),
      ),
    ],
  );
}

class _ExploreServiceDock extends StatelessWidget {
  const _ExploreServiceDock({
    required this.venue,
    required this.onOpenServices,
    required this.onBook,
    required this.onMall,
  });

  final FishingVenue venue;
  final VoidCallback onOpenServices;
  final VoidCallback onBook;
  final VoidCallback onMall;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExploreServiceItem(
        icon: Icons.map_rounded,
        title: '地图',
        subtitle: venue.navigationHint,
        color: InkPalette.lake,
        onTap: onOpenServices,
      ),
      _ExploreServiceItem(
        icon: Icons.event_available_rounded,
        title: '预约',
        subtitle: venue.bookingSupported ? '可订钓位' : '查看规则',
        color: InkPalette.pine,
        onTap: onBook,
      ),
      _ExploreServiceItem(
        icon: Icons.sensors_rounded,
        title: '鱼情',
        subtitle: '设备联动',
        color: InkPalette.moss,
        onTap: onOpenServices,
      ),
      _ExploreServiceItem(
        icon: Icons.shopping_bag_rounded,
        title: '补给',
        subtitle: '按钓点配',
        color: InkPalette.reed,
        onTap: onMall,
      ),
    ];

    return InkGlassCard(
      padding: EdgeInsets.all(10.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InkCommercialVisual(
                kind: InkVisualTileKind.map,
                width: 48,
                height: 48,
                radius: 14,
                borderColor: Colors.transparent,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '钓点服务',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '地图、预约、设备鱼情和补给',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 10.8.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              InkPressable(
                onTap: onOpenServices,
                child: Text(
                  '全部服务',
                  style: TextStyle(
                    color: InkPalette.lake,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: InkEntrance(
                    delay: Duration(milliseconds: 35 * i),
                    offset: 6,
                    child: _ExploreServiceTile(item: items[i]),
                  ),
                ),
                if (i != items.length - 1) SizedBox(width: 8.w),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreServiceTile extends StatelessWidget {
  const _ExploreServiceTile({required this.item});

  final _ExploreServiceItem item;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: 76.h),
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: item.color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 18.w),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 9.8.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreServiceItem {
  const _ExploreServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _LocationSearchCard extends StatelessWidget {
  const _LocationSearchCard({
    required this.query,
    required this.locationGranted,
    required this.onSearch,
    required this.onLocationTap,
  });

  final String query;
  final bool locationGranted;
  final VoidCallback onSearch;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(10.r),
      child: Column(
        children: [
          InkInfoRow(
            icon: locationGranted
                ? Icons.my_location_rounded
                : Icons.location_off_rounded,
            title: locationGranted ? venueSummary.location : '定位未授权',
            subtitle: locationGranted
                ? '${venueSummary.nearbyCount} 个附近钓场 · ${venueSummary.weather}'
                : '开启定位后同步附近钓场、鱼情和导航',
            trailing: locationGranted ? '切换' : '开启',
            color: locationGranted ? InkPalette.pine : InkPalette.reed,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: InkSearchBox(
                  hint: query.isEmpty ? '搜索钓场、鱼种、夜钓、赛事' : '搜索：$query',
                  onTap: onSearch,
                ),
              ),
              SizedBox(width: 8.w),
              InkPressable(
                onTap: onLocationTap,
                child: Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: InkPalette.lake.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: InkPalette.lake.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: InkPalette.lake,
                    size: 20.w,
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

class _ExploreRouteContextCard extends StatelessWidget {
  const _ExploreRouteContextCard({
    required this.venue,
    required this.fish,
    required this.window,
    required this.hint,
    required this.intent,
    required this.onTap,
  });

  final FishingVenue venue;
  final String? fish;
  final String? window;
  final String? hint;
  final String? intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actionLabel = intent == 'booking'
        ? '预约'
        : intent == 'route'
        ? '查看'
        : '承接';
    final fishText = fish?.trim().isNotEmpty == true
        ? fish!.trim()
        : venue.fishSpecies.first;
    final windowText = window?.trim().isNotEmpty == true
        ? window!.trim()
        : venue.openHours;
    final hintText = hint?.trim().isNotEmpty == true
        ? hint!.trim()
        : venue.navigationHint;

    return InkRouteContextBanner(
      icon: Icons.route_rounded,
      title: '首页推荐已带入 · $fishText',
      subtitle: '$windowText · $hintText · ${venue.name}',
      trailing: actionLabel,
      color: InkPalette.lake,
      onTap: onTap,
    );
  }
}

class _FishingIndexCard extends StatelessWidget {
  const _FishingIndexCard({
    required this.summary,
    required this.venue,
    required this.onRefresh,
  });

  final VenueSummary summary;
  final FishingVenue venue;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      borderColor: InkPalette.pine.withValues(alpha: 0.22),
      child: Row(
        children: [
          SizedBox(
            width: 88.w,
            height: 104.h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const InkCommercialVisual(
                  kind: InkVisualTileKind.map,
                  radius: 18,
                  borderColor: Colors.transparent,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    color: InkPalette.ink.withValues(alpha: 0.10),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.todayIndex}',
                        style: TextStyle(
                          color: InkPalette.white,
                          fontSize: 28.sp,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '适钓指数',
                        style: TextStyle(
                          color: InkPalette.white.withValues(alpha: 0.86),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TinyPill(
                  label: summary.indexLabel,
                  color: InkPalette.pine,
                  icon: Icons.auto_graph_rounded,
                ),
                SizedBox(height: 6.h),
                Text(
                  '推荐：${venue.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 17.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  summary.indexReason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7.h),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        value: summary.recommendedWindow,
                        label: '推荐窗口',
                        color: InkPalette.lake,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkPressable(
                      onTap: onRefresh,
                      child: Container(
                        height: 34.h,
                        padding: EdgeInsets.symmetric(horizontal: 9.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: InkPalette.pine,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          '刷新',
                          style: TextStyle(
                            color: InkPalette.white,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  venue.navigationHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.pine,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterBar extends StatelessWidget {
  const _QuickFilterBar({
    required this.filters,
    required this.selected,
    required this.sortId,
    required this.onTap,
    required this.onMore,
  });

  final List<VenueFilterOption> filters;
  final Set<String> selected;
  final String sortId;
  final ValueChanged<String> onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final quick = filters
        .where(
          (item) =>
              item.id == 'nearest' ||
              item.id == 'bookable' ||
              item.id == 'today_good' ||
              item.id == 'device_friendly',
        )
        .toList();
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
        itemCount: quick.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == quick.length) {
            return InkChip(
              label: '更多筛选',
              icon: Icons.tune_rounded,
              color: InkPalette.moss,
              onTap: onMore,
            );
          }
          final filter = quick[index];
          final active = filter.id == 'nearest' || filter.id == 'popular'
              ? sortId == filter.id
              : selected.contains(filter.id);
          return InkChip(
            label: filter.label,
            icon: _iconForFilter(filter.iconKey),
            active: active,
            color: _colorForFilter(filter.group),
            onTap: () => onTap(filter.id),
          );
        },
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.onDetail,
    required this.onBook,
  });

  final FishingVenue venue;
  final VoidCallback onDetail;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final color = _colorForVenue(venue);
    final bookable = venue.bookingSupported && venue.status == VenueStatus.open;
    return SizedBox(
      width: 272.w,
      child: InkCard(
        padding: EdgeInsets.all(10.r),
        onTap: onDetail,
        borderColor: color.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VenueImage(venue: venue, width: 82, height: 72),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.text,
                                fontSize: 14.5.sp,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _TinyPill(
                            label: '${venue.todayIndex}',
                            color: color,
                            icon: Icons.auto_graph_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${venue.distanceLabel} · ${venue.area} · ${venue.openHours}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.muted,
                          fontSize: 10.8.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: InkPalette.reed,
                            size: 14.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: InkPalette.text,
                              fontSize: 10.8.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '¥${venue.priceFrom}起 · 会员¥${venue.memberPriceFrom}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.cinnabar,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 7.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 5.h,
              children: [
                for (final fish in venue.fishSpecies.take(3))
                  _TinyPill(label: fish, color: InkPalette.lake),
                _TinyPill(
                  label: venue.bookingSupported ? '可预约' : '仅查看',
                  color: venue.bookingSupported
                      ? InkPalette.pine
                      : InkPalette.muted,
                ),
                if (venue.nightFishing)
                  const _TinyPill(label: '夜钓', color: InkPalette.reed),
                if (venue.smartDeviceFriendly)
                  const _TinyPill(label: '设备友好', color: InkPalette.moss),
              ],
            ),
            SizedBox(height: 7.h),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    value: venue.todayLabel,
                    label: '今日鱼情',
                    color: color,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: _MiniMetric(
                    value: _statusText(venue),
                    label: '钓位',
                    color: bookable ? InkPalette.pine : InkPalette.reed,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    label: '详情',
                    icon: Icons.article_rounded,
                    color: color,
                    onTap: onDetail,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _SolidButton(
                    label: bookable ? '立即预约' : _statusText(venue),
                    icon: bookable
                        ? Icons.event_available_rounded
                        : Icons.info_rounded,
                    color: bookable ? color : InkPalette.muted,
                    onTap: bookable ? onBook : onDetail,
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

class _VenueMapPreview extends StatelessWidget {
  const _VenueMapPreview({required this.venue});

  final FishingVenue venue;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkInfoRow(
            icon: Icons.map_rounded,
            title: '钓场地图与钓位概览',
            subtitle: '${venue.name} · ${venue.navigationHint}',
            trailing: '导航',
            color: InkPalette.lake,
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              InkMiniMap(
                height: 174,
                selectedIndex: fishingVenues.indexOf(venue),
              ),
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: InkGlassCard(
                  padding: EdgeInsets.all(10.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${venue.leftSeats} 个可用钓位 · ${venue.chargeRule}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _TinyPill(
                        label: venue.status == VenueStatus.open
                            ? '营业中'
                            : _statusText(venue),
                        color: _colorForVenue(venue),
                      ),
                    ],
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

class _EventSection extends StatelessWidget {
  const _EventSection({required this.venues, required this.onTap});

  final Iterable<FishingVenue> venues;
  final ValueChanged<FishingVenue> onTap;

  @override
  Widget build(BuildContext context) {
    final list = venues.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InkSectionHeader(title: '钓场活动 / 赛事', subtitle: '活动券、赛事报名和体验课'),
        SizedBox(
          height: 164.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            itemCount: list.length,
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final venue = list[index];
              final event = venue.events.first;
              return SizedBox(
                width: 264.w,
                child: InkCard(
                  padding: EdgeInsets.all(12.r),
                  onTap: () => onTap(venue),
                  borderColor: InkPalette.reed.withValues(alpha: 0.18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TinyPill(
                        label: event.time,
                        color: InkPalette.reed,
                        icon: Icons.event_available_rounded,
                      ),
                      SizedBox(height: 9.h),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.muted,
                          fontSize: 12.sp,
                          height: 1.32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '会员 ¥${event.memberPrice}',
                              style: TextStyle(
                                color: InkPalette.cinnabar,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _SolidButton(
                            label: '报名',
                            icon: Icons.flash_on_rounded,
                            color: InkPalette.reed,
                            onTap: () => onTap(venue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceInsightSection extends StatelessWidget {
  const _DeviceInsightSection({required this.venue, required this.onSync});

  final FishingVenue venue;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final insight = venue.deviceInsight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InkSectionHeader(title: '设备数据联动', subtitle: '智能鱼漂、探鱼器和钓友报告'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: InkCard(
            padding: EdgeInsets.all(13.r),
            child: Column(
              children: [
                InkInfoRow(
                  icon: Icons.sensors_rounded,
                  title: '${venue.name} · 设备鱼情',
                  subtitle: insight.summary,
                  trailing: '同步',
                  color: InkPalette.moss,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: InkMetric(
                        value: insight.waterTemperature,
                        label: '水温',
                        icon: Icons.water_drop_rounded,
                        color: InkPalette.lake,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkMetric(
                        value: insight.airPressure,
                        label: '气压',
                        icon: Icons.compress_rounded,
                        color: InkPalette.pine,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkMetric(
                        value: insight.biteFrequency,
                        label: '咬钩频率',
                        icon: Icons.auto_graph_rounded,
                        color: InkPalette.reed,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${insight.smartFloatRecords} 条智能鱼漂记录 · ${insight.uploadedReports} 份钓友报告',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.muted,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _OutlineButton(
                      label: '同步',
                      icon: Icons.sync_rounded,
                      color: InkPalette.moss,
                      onTap: onSync,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MallRecommendationSection extends StatelessWidget {
  const _MallRecommendationSection({
    required this.venue,
    required this.onProductTap,
    required this.onMallTap,
  });

  final FishingVenue venue;
  final ValueChanged<String> onProductTap;
  final VoidCallback onMallTap;

  @override
  Widget build(BuildContext context) {
    final products = venueMallRecommendations
        .where((item) => venue.recommendedProductIds.contains(item.productId))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(
          title: '适配装备推荐',
          subtitle: '${venue.name} 的智能设备组合',
          action: '商城',
          onAction: onMallTap,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            children: [
              for (var index = 0; index < products.length; index++) ...[
                InkCard(
                  padding: EdgeInsets.all(11.r),
                  onTap: () => onProductTap(products[index].productId),
                  child: InkInfoRow(
                    icon: Icons.settings_input_antenna_rounded,
                    title: products[index].name,
                    subtitle: products[index].reason,
                    trailing: '¥${products[index].memberPrice}',
                    color: InkPalette.lake,
                  ),
                ),
                if (index != products.length - 1) SizedBox(height: 8.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _VenueSearchSheet extends StatefulWidget {
  const _VenueSearchSheet({
    required this.initialQuery,
    required this.onSearch,
    required this.onSelect,
  });

  final String initialQuery;
  final ValueChanged<String> onSearch;
  final ValueChanged<FishingVenue> onSelect;

  @override
  State<_VenueSearchSheet> createState() => _VenueSearchSheetState();
}

class _VenueSearchSheetState extends State<_VenueSearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FishingVenue> get _results {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return recommendedVenues().take(4).toList();
    return fishingVenues.where((venue) {
      return venue.name.toLowerCase().contains(query) ||
          venue.fishSpecies.any((fish) => fish.toLowerCase().contains(query)) ||
          venue.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          venue.sceneTypes.any((scene) => scene.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
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
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: widget.onSearch,
                decoration: InputDecoration(
                  hintText: '搜索钓场、鱼种、夜钓、亲子',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: InkPalette.line),
                  ),
                  filled: true,
                  fillColor: InkPalette.white.withValues(alpha: 0.86),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                results.isEmpty ? '没有匹配钓场' : '推荐结果',
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10.h),
              if (results.isEmpty)
                _VenueStateCard(
                  icon: Icons.search_off_rounded,
                  title: '搜索无结果',
                  message: '试试搜索鲫鱼、夜钓、亲子或设备友好。',
                  actionLabel: '清空',
                  color: InkPalette.lake,
                  onAction: () {
                    _controller.clear();
                    setState(() {});
                  },
                )
              else
                for (var index = 0; index < results.length; index++) ...[
                  InkCard(
                    padding: EdgeInsets.all(11.r),
                    onTap: () => widget.onSelect(results[index]),
                    child: InkInfoRow(
                      icon: Icons.place_rounded,
                      title: results[index].name,
                      subtitle:
                          '${results[index].distanceLabel} · ${results[index].fishSpecies.join('、')} · ${results[index].todayIndex}分',
                      trailing: '定位',
                      color: _colorForVenue(results[index]),
                    ),
                  ),
                  if (index != results.length - 1) SizedBox(height: 8.h),
                ],
              SizedBox(height: 14.h),
              InkPrimaryButton(
                label: '搜索',
                icon: Icons.search_rounded,
                color: InkPalette.pine,
                onTap: () => widget.onSearch(_controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueFilterSheet extends StatefulWidget {
  const _VenueFilterSheet({
    required this.selected,
    required this.sortId,
    required this.onApply,
  });

  final Set<String> selected;
  final String sortId;
  final void Function(Set<String> filters, String sortId) onApply;

  @override
  State<_VenueFilterSheet> createState() => _VenueFilterSheetState();
}

class _VenueFilterSheetState extends State<_VenueFilterSheet> {
  late final Set<String> _selected;
  late String _sortId;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.of(widget.selected);
    _sortId = widget.sortId;
  }

  void _toggle(String id) {
    setState(() {
      if (id == 'nearest' || id == 'popular') {
        _sortId = id;
        return;
      }
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                    ),
                  ),
                  const InkInfoRow(
                    icon: Icons.tune_rounded,
                    title: '钓场筛选',
                    subtitle: '距离、人气、预约、鱼种、价格、夜钓、设施和活动',
                    color: InkPalette.pine,
                  ),
                  SizedBox(height: 12.h),
                  for (final group in _filterGroups) ...[
                    Text(
                      group,
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final option in venueFilterOptions.where(
                          (item) => item.group == group,
                        ))
                          InkChip(
                            label: option.label,
                            icon: _iconForFilter(option.iconKey),
                            active:
                                option.id == 'nearest' || option.id == 'popular'
                                ? _sortId == option.id
                                : _selected.contains(option.id),
                            color: _colorForFilter(group),
                            onTap: () => _toggle(option.id),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineButton(
                          label: '清空',
                          icon: Icons.close_rounded,
                          color: InkPalette.muted,
                          onTap: () {
                            setState(() {
                              _selected.clear();
                              _sortId = 'nearest';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkPrimaryButton(
                          label: '应用筛选',
                          icon: Icons.done_rounded,
                          color: InkPalette.pine,
                          onTap: () => widget.onApply(_selected, _sortId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.venue});

  final FishingVenue venue;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late VenueBookingSlot _slot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _slot = widget.venue.bookingSlots.first;
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final canBook =
        venue.status == VenueStatus.open &&
        _slot.status != BookingSlotStatus.full;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: InkGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
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
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              InkInfoRow(
                icon: Icons.event_available_rounded,
                title: venue.name,
                subtitle: canBook ? '选择钓位时段，会员价自动展示' : _statusMessage(venue),
                color: _colorForVenue(venue),
              ),
              SizedBox(height: 12.h),
              for (final slot in venue.bookingSlots) ...[
                _BookingSlotTile(
                  slot: slot,
                  active: _slot.id == slot.id,
                  onTap: () => setState(() => _slot = slot),
                ),
                SizedBox(height: 8.h),
              ],
              if (venue.packages.isNotEmpty) ...[
                SizedBox(height: 4.h),
                InkCard(
                  padding: EdgeInsets.all(11.r),
                  child: InkInfoRow(
                    icon: Icons.inventory_2_rounded,
                    title: venue.packages.first.title,
                    subtitle: venue.packages.first.description,
                    trailing: '¥${venue.packages.first.memberPrice}',
                    color: InkPalette.reed,
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              InkPrimaryButton(
                label: canBook
                    ? '确认预约 ¥${_slot.memberPrice}'
                    : _statusText(venue),
                icon: canBook ? Icons.payments_rounded : Icons.info_rounded,
                busy: _submitting,
                color: canBook ? _colorForVenue(venue) : InkPalette.muted,
                onTap: canBook
                    ? () async {
                        setState(() => _submitting = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 420),
                        );
                        if (!mounted || !context.mounted) return;
                        Navigator.of(context).pop();
                        AppFeedback.showMessage(
                          context,
                          '${venue.name} ${_slot.label} 已预约',
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingSlotTile extends StatelessWidget {
  const _BookingSlotTile({
    required this.slot,
    required this.active,
    required this.onTap,
  });

  final VenueBookingSlot slot;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (slot.status) {
      BookingSlotStatus.available => InkPalette.pine,
      BookingSlotStatus.few => InkPalette.reed,
      BookingSlotStatus.full => InkPalette.muted,
    };
    return InkCard(
      padding: EdgeInsets.all(11.r),
      onTap: onTap,
      color: active
          ? color.withValues(alpha: 0.09)
          : InkPalette.white.withValues(alpha: 0.96),
      borderColor: active ? color.withValues(alpha: 0.24) : null,
      child: Row(
        children: [
          InkIconMark(
            icon: Icons.event_seat_rounded,
            color: color,
            size: 38,
            iconSize: 19,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${slot.timeRange} · 剩余 ${slot.leftSeats} 位',
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
          SizedBox(width: 8.w),
          Text(
            slot.status == BookingSlotStatus.full
                ? '已满'
                : '¥${slot.memberPrice}',
            style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueStateCard extends StatelessWidget {
  const _VenueStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.color,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Color color;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(14.r),
      child: Column(
        children: [
          InkInfoRow(icon: icon, title: title, subtitle: message, color: color),
          SizedBox(height: 12.h),
          InkPrimaryButton(
            label: actionLabel,
            icon: Icons.refresh_rounded,
            color: color,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _LoadingVenueCard extends StatelessWidget {
  const _LoadingVenueCard();

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      child: Row(
        children: [
          const InkTaijiLoader(size: 36, label: ''),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '正在同步附近钓场、钓位余量和设备鱼情',
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

class _VenueImage extends StatelessWidget {
  const _VenueImage({
    required this.venue,
    required this.width,
    required this.height,
  });

  final FishingVenue venue;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkCommercialVisual(
          kind: _visualKind(venue.mainImageKind),
          width: width,
          height: height,
          radius: 17,
          borderColor: Colors.transparent,
        ),
        Positioned(
          left: 6.w,
          bottom: 6.h,
          child: _TinyPill(
            label: venue.status == VenueStatus.open
                ? '营业中'
                : _statusText(venue),
            color: _colorForVenue(venue),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 46.h),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 11.8.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 118.w, minHeight: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12.w),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 40.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15.w),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 40.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: Offset(0, 7.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: InkPalette.white, size: 15.w),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _filterGroups = [
  '排序',
  '交易',
  '鱼种',
  '价格',
  '场景',
  '设施',
  '智能设备',
  '智能推荐',
  '商业活动',
];

Color _colorForVenue(FishingVenue venue) {
  if (venue.status == VenueStatus.paused) return InkPalette.reed;
  if (venue.status == VenueStatus.full) return InkPalette.muted;
  if (venue.todayIndex >= 84) return InkPalette.pine;
  if (venue.nightFishing) return InkPalette.lake;
  return InkPalette.moss;
}

Color _colorForFilter(String group) {
  switch (group) {
    case '交易':
    case '商业活动':
      return InkPalette.reed;
    case '鱼种':
    case '智能设备':
      return InkPalette.lake;
    case '设施':
    case '场景':
      return InkPalette.moss;
    default:
      return InkPalette.pine;
  }
}

IconData _iconForFilter(String key) {
  switch (key) {
    case 'near':
      return Icons.near_me_rounded;
    case 'hot':
      return Icons.local_fire_department_rounded;
    case 'booking':
      return Icons.event_available_rounded;
    case 'fish':
      return Icons.set_meal_rounded;
    case 'price':
      return Icons.payments_rounded;
    case 'night':
      return Icons.nights_stay_rounded;
    case 'pond':
      return Icons.water_rounded;
    case 'wild':
      return Icons.terrain_rounded;
    case 'family':
      return Icons.family_restroom_rounded;
    case 'device':
      return Icons.sensors_rounded;
    case 'parking':
      return Icons.local_parking_rounded;
    case 'dining':
      return Icons.restaurant_rounded;
    case 'event':
      return Icons.emoji_events_rounded;
    default:
      return Icons.auto_graph_rounded;
  }
}

InkVisualTileKind _visualKind(VenueImageKind kind) {
  switch (kind) {
    case VenueImageKind.lake:
      return InkVisualTileKind.map;
    case VenueImageKind.pond:
      return InkVisualTileKind.spot;
    case VenueImageKind.night:
      return InkVisualTileKind.mall;
    case VenueImageKind.family:
      return InkVisualTileKind.achievement;
    case VenueImageKind.competition:
      return InkVisualTileKind.spot;
  }
}

String _statusText(FishingVenue venue) {
  switch (venue.status) {
    case VenueStatus.open:
      return venue.leftSeats > 0 ? '余${venue.leftSeats}位' : '已约满';
    case VenueStatus.paused:
      return '暂停营业';
    case VenueStatus.full:
      return '已约满';
  }
}

String _statusMessage(FishingVenue venue) {
  switch (venue.status) {
    case VenueStatus.open:
      return venue.leftSeats > 0 ? '可预约 ${venue.leftSeats} 个钓位' : '钓位已约满';
    case VenueStatus.paused:
      return '该钓场因安全或运营原因暂停营业';
    case VenueStatus.full:
      return '今日钓位已全部约满，可查看其他钓场';
  }
}
