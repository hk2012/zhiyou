import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/mall_mock_data.dart';
import '../data/mall_models.dart';

class MallProductDetailScreen extends StatelessWidget {
  const MallProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final product = mallProductById(productId);
    if (product == null) {
      return InkPage(
        child: AppErrorView(
          title: '商品不存在',
          message: '这个商品可能已下架，返回商城看看其他装备。',
          actionLabel: '返回商城',
          onAction: () => context.pop(),
        ),
      );
    }

    final pairings = mallProductsByIds(
      product.pairingProductIds,
    ).take(3).toList(growable: false);
    final suitableFish = product.suitableFish.isEmpty
        ? product.recommendedFor.take(3).toList(growable: false)
        : product.suitableFish;
    final reviews = product.reviews.isEmpty
        ? ['信息清晰，适合作为出钓前的装备参考。', '会员价和售后说明比较明确。']
        : product.reviews;

    return InkPage(
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 112.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkTopBar(
                  title: '商品详情',
                  subtitle: product.category.label,
                  onBack: () => context.pop(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                  child: _ProductHero(product: product),
                ),
                _DetailSection(
                  title: '核心卖点',
                  subtitle: '买它之后能解决什么问题',
                  child: _ChipWrap(
                    values: product.features,
                    color: _categoryColor(product.category),
                  ),
                ),
                _DetailSection(
                  title: '使用场景',
                  subtitle: product.scene,
                  child: _InfoCard(
                    icon: Icons.explore_rounded,
                    title: product.description.isEmpty
                        ? product.scene
                        : product.description,
                    color: _categoryColor(product.category),
                  ),
                ),
                _DetailSection(
                  title: '适合鱼种',
                  subtitle: '按场景和装备能力推荐',
                  child: _ChipWrap(
                    values: suitableFish,
                    color: InkPalette.moss,
                  ),
                ),
                if (product.isSmartDevice)
                  _SmartDeviceDetailBlock(product: product),
                _DetailSection(
                  title: '搭配推荐',
                  subtitle: '配件、套餐和会员权益一起看',
                  child: pairings.isEmpty
                      ? const _InfoCard(
                          icon: Icons.inventory_2_rounded,
                          title: '暂无固定搭配，后续会按你的作钓场景推荐。',
                          color: InkPalette.lake,
                        )
                      : Column(
                          children: [
                            for (final item in pairings) ...[
                              _PairingRow(product: item),
                              if (item != pairings.last) SizedBox(height: 8.h),
                            ],
                          ],
                        ),
                ),
                _DetailSection(
                  title: '用户评价',
                  subtitle: '真实使用反馈摘要',
                  child: Column(
                    children: [
                      for (final review in reviews.take(3)) ...[
                        _ReviewRow(text: review),
                        if (review != reviews.take(3).last)
                          SizedBox(height: 8.h),
                      ],
                    ],
                  ),
                ),
                _DetailSection(
                  title: '售后保障',
                  subtitle: '配送、质保和服务承诺',
                  child: Column(
                    children: [
                      _InfoCard(
                        icon: Icons.verified_user_rounded,
                        title: product.afterSale,
                        color: InkPalette.moss,
                      ),
                      SizedBox(height: 8.h),
                      _InfoCard(
                        icon: Icons.local_shipping_rounded,
                        title: product.delivery,
                        color: InkPalette.lake,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(product: product),
          ),
        ],
      ),
    );
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return InkCard(
      padding: EdgeInsets.all(14.r),
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 212.h,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.image,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.24),
                          InkPalette.ink.withValues(alpha: 0.16),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: InkPalette.white.withValues(alpha: 0.88),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _categoryIcon(product.category),
                        color: color,
                        size: 38.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 22.sp,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: product.isSmartDevice ? '智能设备' : product.category.label,
                color: color,
                icon: product.isSmartDevice
                    ? Icons.settings_input_antenna_rounded
                    : Icons.local_offer_rounded,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 13.sp,
              height: 1.36,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 13.h),
          Row(
            children: [
              Expanded(child: _PriceBlock(product: product)),
              SizedBox(width: 10.w),
              _MiniMetric(
                value: product.rating.toStringAsFixed(1),
                label: '评分',
                icon: Icons.star_rounded,
                color: InkPalette.reed,
              ),
              SizedBox(width: 8.w),
              _MiniMetric(
                value: '${product.sales}',
                label: '销量',
                icon: Icons.trending_up_rounded,
                color: InkPalette.lake,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _ChipWrap(values: product.tags, color: color),
        ],
      ),
    );
  }
}

class _SmartDeviceDetailBlock extends StatelessWidget {
  const _SmartDeviceDetailBlock({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'App 智能能力',
      subtitle: '购买后可在江湖钓客 App 中解锁',
      child: Column(
        children: [
          _ChipWrap(values: product.appFunctions, color: InkPalette.lake),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  label: '作钓模式',
                  value: '支持',
                  icon: Icons.play_circle_rounded,
                  color: InkPalette.pine,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SpecTile(
                  label: '设备联动',
                  value: product.supportDeviceLink ? '支持' : '不支持',
                  icon: Icons.hub_rounded,
                  color: InkPalette.moss,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  label: '续航',
                  value: product.batteryLife.isEmpty
                      ? '咨询客服'
                      : product.batteryLife,
                  icon: Icons.battery_charging_full_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SpecTile(
                  label: '防水',
                  value: product.waterproofLevel.isEmpty
                      ? '咨询客服'
                      : product.waterproofLevel,
                  icon: Icons.water_drop_rounded,
                  color: InkPalette.lake,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _InfoCard(
            icon: Icons.system_update_rounded,
            title: product.firmwareUpgrade.isEmpty
                ? '固件升级能力待确认'
                : product.firmwareUpgrade,
            color: InkPalette.lake,
          ),
          SizedBox(height: 8.h),
          _InfoCard(
            icon: Icons.verified_rounded,
            title: product.warranty.isEmpty
                ? product.afterSale
                : product.warranty,
            color: InkPalette.moss,
          ),
          SizedBox(height: 8.h),
          _InfoCard(
            icon: Icons.qr_code_scanner_rounded,
            title: product.bindingGuide.isEmpty
                ? '打开设备中心，根据页面提示完成绑定。'
                : product.bindingGuide,
            color: InkPalette.pine,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(title: title, subtitle: subtitle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: child,
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '会员价 ¥${product.memberPrice}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: InkPalette.cinnabar,
            fontSize: 21.sp,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            Text(
              '售价 ¥${product.price}',
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '原价 ¥${product.originalPrice}',
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 54.w, minHeight: 52.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 15.w),
          SizedBox(height: 3.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      borderColor: color.withValues(alpha: 0.16),
      color: color.withValues(alpha: 0.07),
      child: Row(
        children: [
          InkIconMark(icon: icon, color: color, size: 32, iconSize: 16),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 12.sp,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      borderColor: color.withValues(alpha: 0.16),
      color: InkPalette.white.withValues(alpha: 0.96),
      child: Row(
        children: [
          InkIconMark(icon: icon, color: color, size: 36, iconSize: 18),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 12.5.sp,
                height: 1.38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PairingRow extends StatelessWidget {
  const _PairingRow({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return InkCard(
      padding: EdgeInsets.all(10.r),
      borderColor: color.withValues(alpha: 0.14),
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            height: 50.w,
            child: _Thumb(product: product),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  product.scene,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '¥${product.memberPrice}',
            style: TextStyle(
              color: InkPalette.cinnabar,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkIconMark(
            icon: Icons.forum_rounded,
            color: InkPalette.reed,
            size: 34,
            iconSize: 17,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 12.5.sp,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.values, required this.color});

  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final chips = values.isEmpty ? ['暂无数据'] : values;
    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: [
        for (final item in chips.take(8))
          _StatusPill(label: item, color: color),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 28.h, maxWidth: 132.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.17)),
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(product.image, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18)),
          ),
          Icon(_categoryIcon(product.category), color: color, size: 24.w),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.96),
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
              icon: Icons.support_agent_rounded,
              label: '客服',
              onTap: () => AppFeedback.showMessage(context, '已为你接入商城客服'),
            ),
            SizedBox(width: 8.w),
            _BottomIconAction(
              icon: Icons.favorite_border_rounded,
              label: '收藏',
              onTap: () =>
                  AppFeedback.showMessage(context, '${product.name} 已收藏'),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BottomButton(
                label: '加入购物车',
                color: InkPalette.pine,
                filled: false,
                onTap: () =>
                    AppFeedback.showMessage(context, '${product.name} 已加入购物车'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _BottomButton(
                label: '立即购买',
                color: InkPalette.cinnabar,
                filled: true,
                onTap: () => AppFeedback.showMessage(
                  context,
                  '已进入 ${product.name} 结算确认',
                ),
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
        width: 42.w,
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

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 44.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: filled ? InkPalette.white : color,
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(MallProductCategory category) {
  switch (category) {
    case MallProductCategory.smartDevice:
    case MallProductCategory.smartFloat:
    case MallProductCategory.fishFinder:
    case MallProductCategory.sensor:
      return InkPalette.lake;
    case MallProductCategory.smartTackleBox:
    case MallProductCategory.smartPlatform:
    case MallProductCategory.smartUmbrella:
    case MallProductCategory.nightLight:
    case MallProductCategory.oxygen:
      return InkPalette.moss;
    case MallProductCategory.bait:
    case MallProductCategory.accessory:
    case MallProductCategory.fishingLine:
      return InkPalette.reed;
    case MallProductCategory.rod:
    case MallProductCategory.membership:
    case MallProductCategory.fishingVenue:
      return InkPalette.pine;
  }
}

IconData _categoryIcon(MallProductCategory category) {
  switch (category) {
    case MallProductCategory.smartDevice:
      return Icons.settings_input_antenna_rounded;
    case MallProductCategory.smartFloat:
      return Icons.water_drop_rounded;
    case MallProductCategory.smartTackleBox:
      return Icons.inventory_2_rounded;
    case MallProductCategory.smartPlatform:
      return Icons.dashboard_customize_rounded;
    case MallProductCategory.smartUmbrella:
      return Icons.beach_access_rounded;
    case MallProductCategory.fishFinder:
      return Icons.sensors_rounded;
    case MallProductCategory.nightLight:
      return Icons.lightbulb_rounded;
    case MallProductCategory.bait:
      return Icons.grain_rounded;
    case MallProductCategory.rod:
      return Icons.phishing_rounded;
    case MallProductCategory.fishingLine:
      return Icons.cable_rounded;
    case MallProductCategory.accessory:
      return Icons.build_rounded;
    case MallProductCategory.membership:
      return Icons.workspace_premium_rounded;
    case MallProductCategory.fishingVenue:
      return Icons.location_on_rounded;
    case MallProductCategory.sensor:
      return Icons.thermostat_rounded;
    case MallProductCategory.oxygen:
      return Icons.air_rounded;
  }
}
