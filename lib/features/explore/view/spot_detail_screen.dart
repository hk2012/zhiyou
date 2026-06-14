import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/spot_detail_models.dart';
import '../data/spot_detail_repository.dart';
import '../data/venue_mock_data.dart';

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({super.key, required this.spotName});

  final String spotName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venue = venueByName(spotName);
    if (venue != null) {
      return InkPage(child: _VenueDetailContent(venue: venue));
    }

    final state = ref.watch(spotDetailProvider(spotName));
    return InkPage(
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _SpotDetailFallback(spotName: spotName),
        data: (detail) => _SpotDetailContent(detail: detail),
      ),
    );
  }
}

class _VenueDetailContent extends StatelessWidget {
  const _VenueDetailContent({required this.venue});

  final FishingVenue venue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 124.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkTopBar(
                title: venue.name,
                subtitle: '${venue.area} · ${venue.distanceLabel}',
                onBack: () => context.pop(),
                actions: [
                  InkRoundButton(
                    icon: Icons.bookmark_add_rounded,
                    onTap: () =>
                        AppFeedback.showMessage(context, '${venue.name} 已收藏'),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                child: _VenueDetailHero(venue: venue),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkMetric(
                        value: '${venue.todayIndex}',
                        label: '适钓指数',
                        icon: Icons.auto_graph_rounded,
                        color: _venueColor(venue),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkMetric(
                        value: venue.distanceLabel,
                        label: '距离',
                        icon: Icons.near_me_rounded,
                        color: InkPalette.lake,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: InkMetric(
                        value: '${venue.rating}',
                        label: '评分',
                        icon: Icons.star_rounded,
                        color: InkPalette.reed,
                      ),
                    ),
                  ],
                ),
              ),
              _VenueDetailSection(
                title: '地址与营业',
                subtitle: '导航、营业时间和收费规则',
                children: [
                  _DetailInfoCard(
                    icon: Icons.location_on_rounded,
                    title: venue.address,
                    subtitle: venue.navigationHint,
                    color: InkPalette.lake,
                  ),
                  _DetailInfoCard(
                    icon: Icons.schedule_rounded,
                    title: venue.openHours,
                    subtitle: venue.chargeRule,
                    color: InkPalette.pine,
                  ),
                ],
              ),
              _VenueDetailSection(
                title: '鱼种与设施',
                subtitle: '目标鱼、服务配套和钓场规则',
                children: [
                  _ChipPanel(
                    icon: Icons.set_meal_rounded,
                    title: '主要鱼种',
                    chips: venue.fishSpecies,
                    color: InkPalette.lake,
                  ),
                  _ChipPanel(
                    icon: Icons.storefront_rounded,
                    title: '服务设施',
                    chips: venue.facilities,
                    color: InkPalette.moss,
                  ),
                ],
              ),
              _VenueDetailSection(
                title: '智能设备数据',
                subtitle: '智能鱼漂、探鱼器和钓友报告',
                children: [
                  _DeviceInsightCard(venue: venue),
                  _ChipPanel(
                    icon: Icons.settings_input_antenna_rounded,
                    title: '推荐设备',
                    chips: venue.recommendedDevices,
                    color: InkPalette.lake,
                  ),
                ],
              ),
              _VenueDetailSection(
                title: '钓位预约',
                subtitle: '可选时段、余位和会员价',
                children: [
                  for (final slot in venue.bookingSlots)
                    _BookingSlotCard(slot: slot),
                ],
              ),
              if (venue.packages.isNotEmpty)
                _VenueDetailSection(
                  title: '钓场套餐 / 会员优惠',
                  subtitle: venue.memberBenefit,
                  children: [
                    for (final package in venue.packages)
                      _PackageCard(package: package),
                  ],
                ),
              if (venue.events.isNotEmpty)
                _VenueDetailSection(
                  title: '活动与赛事',
                  subtitle: '报名、体验课和活动券',
                  children: [
                    for (final event in venue.events) _EventCard(event: event),
                  ],
                ),
              _VenueDetailSection(
                title: '用户评价',
                subtitle: '真实到场体验和设备使用反馈',
                children: [
                  for (final review in venue.reviews)
                    _ReviewCard(review: review),
                ],
              ),
              _VenueDetailSection(
                title: '渔获动态',
                subtitle: '设备记录和钓友上传',
                children: [
                  for (final feed in venue.catchFeeds)
                    _CatchFeedCard(feed: feed),
                ],
              ),
              _VenueDetailSection(
                title: '推荐装备',
                subtitle: '适合该钓场的商城商品',
                children: [
                  for (final item in venueMallRecommendations.where(
                    (product) =>
                        venue.recommendedProductIds.contains(product.productId),
                  ))
                    _MallProductLink(
                      item: item,
                      onTap: () => context.push(
                        '${AppRouteNames.mallProductDetail}?id=${item.productId}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _VenueDetailBottomBar(venue: venue),
        ),
      ],
    );
  }
}

class _VenueDetailHero extends StatelessWidget {
  const _VenueDetailHero({required this.venue});

  final FishingVenue venue;

  @override
  Widget build(BuildContext context) {
    final color = _venueColor(venue);
    return InkCard(
      padding: EdgeInsets.all(14.r),
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 196.h,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InkCommercialVisual(
                    kind: _visualKind(venue.mainImageKind),
                    radius: 20,
                    borderColor: Colors.transparent,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          InkPalette.ink.withValues(alpha: 0.05),
                          InkPalette.ink.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14.w,
                    right: 14.w,
                    bottom: 14.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailPill(
                          label: _venueStatusText(venue),
                          color: color,
                          icon: Icons.event_seat_rounded,
                          dark: true,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          venue.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.white,
                            fontSize: 21.sp,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            venue.description,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 12.5.sp,
              height: 1.42,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final tag in venue.tags)
                _DetailPill(label: tag, color: color),
              if (venue.nightFishing)
                const _DetailPill(label: '夜钓', color: InkPalette.reed),
              if (venue.smartDeviceFriendly)
                const _DetailPill(label: '设备友好', color: InkPalette.lake),
            ],
          ),
        ],
      ),
    );
  }
}

class _VenueDetailSection extends StatelessWidget {
  const _VenueDetailSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(title: title, subtitle: subtitle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: 9.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: InkInfoRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: color,
      ),
    );
  }
}

class _ChipPanel extends StatelessWidget {
  const _ChipPanel({
    required this.icon,
    required this.title,
    required this.chips,
    required this.color,
  });

  final IconData icon;
  final String title;
  final List<String> chips;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkInfoRow(
            icon: icon,
            title: title,
            subtitle: chips.join('、'),
            color: color,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final chip in chips) _DetailPill(label: chip, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceInsightCard extends StatelessWidget {
  const _DeviceInsightCard({required this.venue});

  final FishingVenue venue;

  @override
  Widget build(BuildContext context) {
    final insight = venue.deviceInsight;
    return InkCard(
      padding: EdgeInsets.all(12.r),
      borderColor: InkPalette.lake.withValues(alpha: 0.18),
      child: Column(
        children: [
          InkInfoRow(
            icon: Icons.sensors_rounded,
            title: '设备作钓数据',
            subtitle: insight.summary,
            color: InkPalette.lake,
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
                  value: insight.biteFrequency,
                  label: '咬钩',
                  icon: Icons.auto_graph_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkMetric(
                  value: '${insight.uploadedReports}',
                  label: '报告',
                  icon: Icons.article_rounded,
                  color: InkPalette.pine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingSlotCard extends StatelessWidget {
  const _BookingSlotCard({required this.slot});

  final VenueBookingSlot slot;

  @override
  Widget build(BuildContext context) {
    final color = switch (slot.status) {
      BookingSlotStatus.available => InkPalette.pine,
      BookingSlotStatus.few => InkPalette.reed,
      BookingSlotStatus.full => InkPalette.muted,
    };
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: InkInfoRow(
        icon: Icons.event_seat_rounded,
        title: slot.label,
        subtitle: '${slot.timeRange} · 剩余 ${slot.leftSeats} 位',
        trailing: slot.status == BookingSlotStatus.full
            ? '已满'
            : '¥${slot.memberPrice}',
        color: color,
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final VenuePackage package;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkInfoRow(
            icon: Icons.inventory_2_rounded,
            title: package.title,
            subtitle: package.description,
            trailing: '¥${package.memberPrice}',
            color: InkPalette.reed,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final item in package.includes)
                _DetailPill(label: item, color: InkPalette.reed),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final VenueEvent event;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkInfoRow(
            icon: Icons.emoji_events_rounded,
            title: event.title,
            subtitle: '${event.time} · ${event.description}',
            trailing: '¥${event.memberPrice}',
            color: InkPalette.reed,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final tag in event.tags)
                _DetailPill(label: tag, color: InkPalette.reed),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final VenueReview review;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkInfoRow(
            icon: Icons.forum_rounded,
            title: '${review.user} · ${review.rating}',
            subtitle: review.content,
            color: InkPalette.pine,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final tag in review.tags)
                _DetailPill(label: tag, color: InkPalette.pine),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatchFeedCard extends StatelessWidget {
  const _CatchFeedCard({required this.feed});

  final VenueCatchFeed feed;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: InkInfoRow(
        icon: Icons.set_meal_rounded,
        title: '${feed.user} · ${feed.fish} ${feed.weight}',
        subtitle: '${feed.time} · ${feed.device}',
        color: InkPalette.lake,
      ),
    );
  }
}

class _MallProductLink extends StatelessWidget {
  const _MallProductLink({required this.item, required this.onTap});

  final VenueMallRecommendation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      onTap: onTap,
      child: InkInfoRow(
        icon: Icons.shopping_bag_rounded,
        title: item.name,
        subtitle: item.reason,
        trailing: '¥${item.memberPrice}',
        color: InkPalette.lake,
      ),
    );
  }
}

class _VenueDetailBottomBar extends StatelessWidget {
  const _VenueDetailBottomBar({required this.venue});

  final FishingVenue venue;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final canBook = venue.status == VenueStatus.open && venue.bookingSupported;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.97),
        border: Border(top: BorderSide(color: InkPalette.line)),
        boxShadow: [
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: Offset(0, -8.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, bottom + 10.h),
        child: Row(
          children: [
            _BottomIconAction(
              icon: Icons.call_rounded,
              label: '联系',
              onTap: () => AppFeedback.showMessage(context, venue.contactPhone),
            ),
            SizedBox(width: 8.w),
            _BottomIconAction(
              icon: Icons.near_me_rounded,
              label: '导航',
              onTap: () =>
                  AppFeedback.showMessage(context, venue.navigationHint),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: InkPrimaryButton(
                label: canBook ? '预约钓位' : _venueStatusText(venue),
                icon: canBook
                    ? Icons.event_available_rounded
                    : Icons.info_rounded,
                color: canBook ? _venueColor(venue) : InkPalette.muted,
                onTap: canBook
                    ? () => AppFeedback.showMessage(
                        context,
                        '${venue.name} 预约入口已打开',
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomIconAction extends StatelessWidget {
  const _BottomIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: SizedBox(
        width: 44.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: InkPalette.muted, size: 20.w),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.label,
    required this.color,
    this.icon,
    this.dark = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 136.w, minHeight: 26.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: dark
            ? InkPalette.white.withValues(alpha: 0.16)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: dark
              ? InkPalette.white.withValues(alpha: 0.30)
              : color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: dark ? InkPalette.white : color, size: 12.w),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? InkPalette.white : color,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _venueColor(FishingVenue venue) {
  if (venue.status == VenueStatus.paused) return InkPalette.reed;
  if (venue.status == VenueStatus.full) return InkPalette.muted;
  if (venue.todayIndex >= 84) return InkPalette.pine;
  if (venue.nightFishing) return InkPalette.lake;
  return InkPalette.moss;
}

String _venueStatusText(FishingVenue venue) {
  switch (venue.status) {
    case VenueStatus.open:
      return venue.leftSeats > 0 ? '余${venue.leftSeats}位' : '已约满';
    case VenueStatus.paused:
      return '暂停营业';
    case VenueStatus.full:
      return '已约满';
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

class _SpotDetailContent extends ConsumerWidget {
  const _SpotDetailContent({required this.detail});

  final SpotDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskColor = detail.riskLevel == '高'
        ? InkPalette.cinnabar
        : detail.riskLevel == '中'
        ? InkPalette.reed
        : InkPalette.moss;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 116.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkTopBar(
            title: detail.name,
            subtitle: detail.addressHint,
            leading: InkRoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
            actions: [
              InkRoundButton(
                icon: Icons.bookmark_add_rounded,
                onTap: () async {
                  await ref
                      .read(spotDetailRepositoryProvider)
                      .favorite(detail.spotId, note: detail.headline);
                  if (context.mounted) {
                    AppFeedback.showMessage(context, '${detail.name} 已收藏');
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
            child: InkCard(
              padding: EdgeInsets.all(14.r),
              color: InkPalette.white.withValues(alpha: 0.96),
              borderColor: InkPalette.pine.withValues(alpha: 0.18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkIconMark(
                        icon: Icons.water_rounded,
                        color: InkPalette.pine,
                        size: 48,
                        iconSize: 24,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.headline,
                              style: TextStyle(
                                color: InkPalette.text,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                fontFamilyFallback: brushFontFallback,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              detail.summary,
                              style: TextStyle(
                                color: InkPalette.muted,
                                fontSize: 12.5.sp,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkMetric(
                          value: '${detail.score}',
                          label: '推荐分',
                          icon: Icons.auto_graph_rounded,
                          color: InkPalette.pine,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: InkMetric(
                          value: detail.distanceLabel,
                          label: '距离',
                          icon: Icons.near_me_rounded,
                          color: InkPalette.lake,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: InkMetric(
                          value: detail.riskLevel,
                          label: '风险',
                          icon: Icons.security_rounded,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkMetric(
                    value: detail.waterTemperature,
                    label: '水温',
                    icon: Icons.water_drop_rounded,
                    color: InkPalette.lake,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: InkMetric(
                    value: detail.depthLabel,
                    label: '水深',
                    icon: Icons.straighten_rounded,
                    color: InkPalette.pine,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: InkMetric(
                    value: detail.bestWindow,
                    label: '窗口',
                    icon: Icons.schedule_rounded,
                    color: InkPalette.reed,
                  ),
                ),
              ],
            ),
          ),
          const InkSectionHeader(title: '目标鱼', subtitle: '按活跃度和钓法排序'),
          SizedBox(
            height: 138.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              itemCount: detail.targetFish.length,
              separatorBuilder: (_, _) => SizedBox(width: 10.w),
              itemBuilder: (context, index) =>
                  _FishTargetCard(target: detail.targetFish[index]),
            ),
          ),
          _SpotSection(
            title: '设施与规则',
            subtitle: '停车、设备、隐私和文明垂钓',
            items: [...detail.facilities, ...detail.rules],
          ),
          _SpotSection(
            title: '钓法方案',
            subtitle: '到点后优先执行的打法',
            items: detail.tactics,
          ),
          _SpotSection(
            title: '安全清单',
            subtitle: detail.riskText,
            items: detail.safetyChecklist,
          ),
          _SpotSection(
            title: '附近服务',
            subtitle: '补给、向导和设备租赁',
            items: detail.services,
          ),
          _SpotSection(
            title: '今日鱼情',
            subtitle: '不同时间段的出钓判断',
            items: detail.forecast,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: InkPrimaryButton(
                    label: '记录鱼获',
                    icon: Icons.add_photo_alternate_rounded,
                    color: InkPalette.pine,
                    onTap: () => context.push(
                      '${AppRouteNames.creationModal}?spot=${Uri.encodeComponent(detail.name)}',
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: InkPrimaryButton(
                    label: '开始导航',
                    icon: Icons.near_me_rounded,
                    color: InkPalette.lake,
                    onTap: () => AppFeedback.showMessage(
                      context,
                      '${detail.parkingLabel} · 预计 ${detail.routeMinutes} 分钟',
                    ),
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

class _FishTargetCard extends StatelessWidget {
  const _FishTargetCard({required this.target});

  final SpotFishTarget target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176.w,
      child: InkCard(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkInfoRow(
              icon: Icons.set_meal_rounded,
              title: target.fish,
              subtitle: '${target.method} · ${target.window}',
              trailing: '${target.activity}%',
              color: InkPalette.pine,
            ),
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: target.activity / 100,
                minHeight: 8.h,
                color: InkPalette.pine,
                backgroundColor: InkPalette.line.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotSection extends StatelessWidget {
  const _SpotSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<SpotSectionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(title: title, subtitle: subtitle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                InkCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 11.h,
                  ),
                  child: InkInfoRow(
                    icon: _iconForItem(items[i].title),
                    title: items[i].title,
                    subtitle: items[i].subtitle,
                    trailing: items[i].status,
                    color: _colorForAccent(items[i].accentKey),
                  ),
                ),
                if (i != items.length - 1) SizedBox(height: 9.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpotDetailFallback extends StatelessWidget {
  const _SpotDetailFallback({required this.spotName});

  final String spotName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: InkCard(
          child: InkInfoRow(
            icon: Icons.cloud_off_rounded,
            title: spotName,
            subtitle: '钓点详情暂时无法同步，稍后重试或返回钓点页。',
            color: InkPalette.reed,
          ),
        ),
      ),
    );
  }
}

IconData _iconForItem(String title) {
  if (title.contains('停车')) return Icons.local_parking_rounded;
  if (title.contains('设备')) return Icons.sensors_rounded;
  if (title.contains('隐私')) return Icons.visibility_off_rounded;
  if (title.contains('安全') || title.contains('撤离')) {
    return Icons.security_rounded;
  }
  if (title.contains('向导') || title.contains('服务')) {
    return Icons.support_agent_rounded;
  }
  if (title.contains('补给')) return Icons.store_rounded;
  return Icons.check_circle_rounded;
}

Color _colorForAccent(String key) {
  switch (key) {
    case 'cyan':
      return InkPalette.lake;
    case 'orange':
      return InkPalette.reed;
    case 'blue':
      return InkPalette.moss;
    default:
      return InkPalette.pine;
  }
}
