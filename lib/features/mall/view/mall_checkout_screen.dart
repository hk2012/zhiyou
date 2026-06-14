import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/mall_mock_data.dart';
import '../data/mall_models.dart';

class MallCheckoutScreen extends StatefulWidget {
  const MallCheckoutScreen({super.key});

  @override
  State<MallCheckoutScreen> createState() => _MallCheckoutScreenState();
}

class _MallCheckoutScreenState extends State<MallCheckoutScreen> {
  late final List<_CheckoutEntry> _items;
  String _couponId = mallCoupons.first.id;
  bool _useProPrice = false;
  String _deliveryMethod = 'same_day';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _items = _buildCheckoutEntries();
    _couponId = _bestCoupon?.id ?? mallCoupons.first.id;
  }

  int get _itemCount {
    var count = 0;
    for (final item in _items) {
      count += item.quantity;
    }
    return count;
  }

  int get _subtotal {
    var total = 0;
    for (final item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  int get _memberSaving {
    var total = 0;
    for (final item in _items) {
      total += (item.product.price - item.product.memberPrice) * item.quantity;
    }
    return total < 0 ? 0 : total;
  }

  int get _memberDiscount => _useProPrice ? _memberSaving : 0;

  int get _packageDiscount {
    final ids = _items.map((item) => item.product.id).toSet();
    return ids.contains('smart-float-pro') && ids.contains('night-light-max')
        ? 40
        : 0;
  }

  int get _shippingFee => _deliveryMethod == 'same_day' ? 12 : 0;

  MallCoupon? get _coupon {
    for (final coupon in mallCoupons) {
      if (coupon.id == _couponId) return coupon;
    }
    return null;
  }

  MallCoupon? get _bestCoupon {
    MallCoupon? best;
    for (final coupon in mallCoupons) {
      if (!_couponEnabled(coupon)) continue;
      if (best == null || coupon.amount > best.amount) best = coupon;
    }
    return best;
  }

  int get _couponDiscount {
    final coupon = _coupon;
    if (coupon == null || !_couponEnabled(coupon)) return 0;
    final cap = _subtotal - _memberDiscount - _packageDiscount;
    if (cap <= 0) return 0;
    return coupon.amount > cap ? cap : coupon.amount;
  }

  int get _payable {
    final amount =
        _subtotal +
        _shippingFee -
        _memberDiscount -
        _packageDiscount -
        _couponDiscount;
    return amount < 0 ? 0 : amount;
  }

  bool _couponEnabled(MallCoupon coupon) {
    if (_subtotal < coupon.threshold) return false;
    if (coupon.memberOnly && !_useProPrice) return false;
    return true;
  }

  void _submitOrder() {
    setState(() => _submitting = true);
    Future<void>.delayed(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppFeedback.showMessage(context, '订单已提交，待支付 ¥$_payable');
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkPage(
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 146.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkTopBar(
                  title: '确认订单',
                  subtitle: '地址 · 商品 · 优惠 · 实付',
                  onBack: () => context.pop(),
                  actions: [
                    InkRoundButton(
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => context.push(AppRouteNames.mallCart),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                  child: _AddressCard(
                    onTap: () =>
                        AppFeedback.showMessage(context, '收货地址编辑入口已预留'),
                  ),
                ),
                const InkSectionHeader(
                  title: '商品列表',
                  subtitle: '智能设备和场景配件统一结算',
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    children: [
                      for (var index = 0; index < _items.length; index++) ...[
                        _CheckoutProductRow(entry: _items[index]),
                        if (index != _items.length - 1) SizedBox(height: 8.h),
                      ],
                    ],
                  ),
                ),
                const InkSectionHeader(title: '会员优惠', subtitle: '未开通时保留专业转化入口'),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: _CheckoutMemberCard(
                    enabled: _useProPrice,
                    saving: _memberSaving,
                    onTap: () {
                      setState(() => _useProPrice = true);
                      AppFeedback.showMessage(context, '已模拟开通并使用 Pro 会员价');
                    },
                  ),
                ),
                const InkSectionHeader(title: '优惠券', subtitle: '自动按门槛判断可用状态'),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    children: [
                      for (final coupon in mallCoupons) ...[
                        _CheckoutCouponRow(
                          coupon: coupon,
                          active:
                              coupon.id == _couponId && _couponEnabled(coupon),
                          enabled: _couponEnabled(coupon),
                          onTap: () {
                            if (!_couponEnabled(coupon)) {
                              AppFeedback.showMessage(
                                context,
                                coupon.memberOnly && !_useProPrice
                                    ? '开通 Pro 后可用会员券'
                                    : '未达到优惠券门槛',
                              );
                              return;
                            }
                            setState(() => _couponId = coupon.id);
                          },
                        ),
                        if (coupon != mallCoupons.last) SizedBox(height: 8.h),
                      ],
                    ],
                  ),
                ),
                const InkSectionHeader(title: '配送方式', subtitle: '按装备属性选择履约方式'),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DeliveryChoice(
                          title: '同城达',
                          subtitle: '24 小时内送达 · ¥12',
                          icon: Icons.local_shipping_rounded,
                          active: _deliveryMethod == 'same_day',
                          color: InkPalette.lake,
                          onTap: () =>
                              setState(() => _deliveryMethod = 'same_day'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _DeliveryChoice(
                          title: '到店取',
                          subtitle: '预约自提 · 免运费',
                          icon: Icons.storefront_rounded,
                          active: _deliveryMethod == 'pickup',
                          color: InkPalette.pine,
                          onTap: () =>
                              setState(() => _deliveryMethod = 'pickup'),
                        ),
                      ),
                    ],
                  ),
                ),
                const InkSectionHeader(
                  title: '金额明细',
                  subtitle: '商品、会员、优惠券、运费和实付',
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: _CheckoutSummaryCard(
                    subtotal: _subtotal,
                    memberDiscount: _memberDiscount,
                    packageDiscount: _packageDiscount,
                    couponDiscount: _couponDiscount,
                    shippingFee: _shippingFee,
                    payable: _payable,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CheckoutBottomBar(
              itemCount: _itemCount,
              payable: _payable,
              submitting: _submitting,
              onSubmit: _submitOrder,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutEntry {
  const _CheckoutEntry({
    required this.product,
    required this.quantity,
    required this.addedFrom,
  });

  final MallProduct product;
  final int quantity;
  final String addedFrom;
}

List<_CheckoutEntry> _buildCheckoutEntries() {
  final entries = <_CheckoutEntry>[];
  for (final item in mallCartMockItems.where((item) => item.selected)) {
    final product = mallProductById(item.productId);
    if (product == null) continue;
    entries.add(
      _CheckoutEntry(
        product: product,
        quantity: item.quantity,
        addedFrom: item.addedFrom,
      ),
    );
  }
  return entries;
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      onTap: onTap,
      child: Row(
        children: [
          const InkIconMark(
            icon: Icons.location_on_rounded,
            color: InkPalette.pine,
            size: 42,
            iconSize: 21,
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '杭州市 西湖区 江湖钓客智能装备体验点',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '洪先生 138****2026 · 支持同城达 / 到店自提',
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
          SizedBox(width: 8.w),
          Text(
            '修改',
            style: TextStyle(
              color: InkPalette.pine,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutProductRow extends StatelessWidget {
  const _CheckoutProductRow({required this.entry});

  final _CheckoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    final color = _categoryColor(product.category);
    return InkCard(
      padding: EdgeInsets.all(11.r),
      child: Row(
        children: [
          _ProductThumb(product: product, size: 56),
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${entry.addedFrom} · ${product.category.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 5.h,
                  children: [
                    for (final tag in product.tags.take(2))
                      _TinyPill(label: tag, color: color),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${product.memberPrice}',
                style: TextStyle(
                  color: InkPalette.cinnabar,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'x${entry.quantity}',
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutMemberCard extends StatelessWidget {
  const _CheckoutMemberCard({
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  final bool enabled;
  final int saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      borderColor: InkPalette.reed.withValues(alpha: 0.24),
      color: InkPalette.reed.withValues(alpha: 0.08),
      child: Row(
        children: [
          const InkIconMark(
            icon: Icons.workspace_premium_rounded,
            color: InkPalette.reed,
            size: 42,
            iconSize: 21,
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'Pro 会员价已应用' : '开启 Pro，使用本单会员价',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  enabled
                      ? '已抵扣 ¥$saving，并保留设备延保和专属客服权益'
                      : '开通后本单可省 ¥$saving，智能设备订单更适合一起开通。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 12.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (!enabled) ...[
            SizedBox(width: 8.w),
            InkPressable(
              onTap: onTap,
              child: Container(
                constraints: BoxConstraints(minHeight: 34.h),
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: InkPalette.reed,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  '开通',
                  style: TextStyle(
                    color: InkPalette.ink,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutCouponRow extends StatelessWidget {
  const _CheckoutCouponRow({
    required this.coupon,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final MallCoupon coupon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? InkPalette.cinnabar : InkPalette.muted;
    return InkCard(
      padding: EdgeInsets.all(11.r),
      onTap: onTap,
      color: active
          ? color.withValues(alpha: 0.10)
          : InkPalette.white.withValues(alpha: 0.96),
      borderColor: active ? color.withValues(alpha: 0.34) : null,
      child: InkInfoRow(
        icon: Icons.confirmation_number_rounded,
        title: coupon.title,
        subtitle: enabled
            ? coupon.description
            : coupon.memberOnly
            ? '开通 Pro 后可用'
            : '满 ¥${coupon.threshold} 可用',
        trailing: active ? '已选' : '-¥${coupon.amount}',
        color: color,
      ),
    );
  }
}

class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      onTap: onTap,
      borderColor: active ? color.withValues(alpha: 0.34) : null,
      color: active
          ? color.withValues(alpha: 0.10)
          : InkPalette.white.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkIconMark(icon: icon, color: color, size: 36, iconSize: 18),
          SizedBox(height: 9.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.sp,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  const _CheckoutSummaryCard({
    required this.subtotal,
    required this.memberDiscount,
    required this.packageDiscount,
    required this.couponDiscount,
    required this.shippingFee,
    required this.payable,
  });

  final int subtotal;
  final int memberDiscount;
  final int packageDiscount;
  final int couponDiscount;
  final int shippingFee;
  final int payable;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      child: Column(
        children: [
          _AmountLine(label: '商品金额', value: '¥$subtotal'),
          _AmountLine(label: '会员优惠', value: '-¥$memberDiscount'),
          _AmountLine(label: '套餐优惠', value: '-¥$packageDiscount'),
          _AmountLine(label: '优惠券', value: '-¥$couponDiscount'),
          _AmountLine(
            label: '运费',
            value: shippingFee == 0 ? '免运费' : '¥$shippingFee',
          ),
          Divider(color: InkPalette.line.withValues(alpha: 0.72)),
          _AmountLine(label: '实付金额', value: '¥$payable', strong: true),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: strong ? InkPalette.text : InkPalette.muted,
              fontSize: strong ? 14.sp : 12.5.sp,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: strong ? InkPalette.cinnabar : InkPalette.text,
              fontSize: strong ? 18.sp : 12.5.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.itemCount,
    required this.payable,
    required this.submitting,
    required this.onSubmit,
  });

  final int itemCount;
  final int payable;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
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
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, bottom + 10.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '实付 ¥$payable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '$itemCount 件商品 · 下单后进入待付款',
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
            SizedBox(width: 12.w),
            SizedBox(
              width: 134.w,
              child: InkPrimaryButton(
                label: '提交订单',
                icon: Icons.payments_rounded,
                busy: submitting,
                onTap: submitting ? null : onSubmit,
                color: InkPalette.cinnabar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product, required this.size});

  final MallProduct product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    final side = size.w;
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(product.image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18)),
            ),
            Icon(_categoryIcon(product.category), color: color, size: 25.w),
          ],
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 88.w, minHeight: 23.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
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
