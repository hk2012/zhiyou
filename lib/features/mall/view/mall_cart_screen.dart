import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/mall_mock_data.dart';
import '../data/mall_models.dart';

class MallCartScreen extends StatefulWidget {
  const MallCartScreen({super.key});

  @override
  State<MallCartScreen> createState() => _MallCartScreenState();
}

class _MallCartScreenState extends State<MallCartScreen> {
  late final List<_CartEntry> _items;
  bool _isProMember = false;
  String? _couponId;

  @override
  void initState() {
    super.initState();
    _items = _buildInitialCartEntries();
    _couponId = _bestCoupon?.id;
  }

  List<_CartEntry> get _selectedItems {
    return _items.where((item) => item.selected).toList(growable: false);
  }

  int get _selectedCount {
    var total = 0;
    for (final item in _selectedItems) {
      total += item.quantity;
    }
    return total;
  }

  int get _subtotal {
    var total = 0;
    for (final item in _selectedItems) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  int get _memberSaving {
    var total = 0;
    for (final item in _selectedItems) {
      total += (item.product.price - item.product.memberPrice) * item.quantity;
    }
    return total < 0 ? 0 : total;
  }

  int get _activeMemberDiscount => _isProMember ? _memberSaving : 0;

  int get _packageSaving {
    final ids = _selectedItems.map((item) => item.product.id).toSet();
    final matched =
        ids.contains('smart-float-pro') && ids.contains('night-light-max');
    return matched ? 40 : 0;
  }

  MallCoupon? get _selectedCoupon {
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
    final coupon = _selectedCoupon;
    if (coupon == null || !_couponEnabled(coupon)) return 0;
    final cap = _subtotal - _activeMemberDiscount - _packageSaving;
    if (cap <= 0) return 0;
    return coupon.amount > cap ? cap : coupon.amount;
  }

  int get _payable {
    final amount =
        _subtotal - _activeMemberDiscount - _packageSaving - _couponDiscount;
    return amount < 0 ? 0 : amount;
  }

  bool _couponEnabled(MallCoupon coupon) {
    if (_subtotal < coupon.threshold) return false;
    if (coupon.memberOnly && !_isProMember) return false;
    return true;
  }

  void _selectCoupon(MallCoupon coupon) {
    if (!_couponEnabled(coupon)) {
      AppFeedback.showMessage(
        context,
        coupon.memberOnly && !_isProMember ? '开通 Pro 后可用会员券' : '未达到使用门槛',
      );
      return;
    }
    setState(() => _couponId = coupon.id);
  }

  void _clearCart() {
    setState(_items.clear);
    AppFeedback.showMessage(context, '购物车已清空');
  }

  void _openCheckout() {
    if (_selectedCount == 0) {
      AppFeedback.showMessage(context, '请先选择要结算的商品');
      return;
    }
    context.push(AppRouteNames.mallCheckout);
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;
    return InkPage(
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: hasItems
                  ? MediaQuery.of(context).viewPadding.bottom + 142.h
                  : 28.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkTopBar(
                  title: '购物车',
                  subtitle: '装备勾选 · 会员价 · 优惠券 · 结算',
                  onBack: () => context.pop(),
                  actions: [
                    if (hasItems)
                      InkRoundButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: _clearCart,
                      ),
                  ],
                ),
                if (!hasItems)
                  _CartEmptyPanel(
                    onMallTap: () => context.go(AppRouteNames.mall),
                    onDeviceTap: () => context.go(AppRouteNames.mall),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                    child: _CartOverviewCard(
                      selectedCount: _selectedCount,
                      subtotal: _subtotal,
                      memberSaving: _memberSaving,
                      couponDiscount: _couponDiscount,
                    ),
                  ),
                  const InkSectionHeader(
                    title: '装备清单',
                    subtitle: '勾选商品、调整数量或删除',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      children: [
                        for (var index = 0; index < _items.length; index++) ...[
                          _CartProductTile(
                            entry: _items[index],
                            onSelected: (value) =>
                                setState(() => _items[index].selected = value),
                            onIncrement: () =>
                                setState(() => _items[index].quantity += 1),
                            onDecrement: () => setState(() {
                              if (_items[index].quantity > 1) {
                                _items[index].quantity -= 1;
                              }
                            }),
                            onDelete: () {
                              final name = _items[index].product.name;
                              setState(() => _items.removeAt(index));
                              AppFeedback.showMessage(context, '$name 已移出购物车');
                            },
                          ),
                          if (index != _items.length - 1)
                            SizedBox(height: 10.h),
                        ],
                      ],
                    ),
                  ),
                  const InkSectionHeader(
                    title: '会员价',
                    subtitle: '专业权益，不做廉价促销感',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: _MemberSavingCard(
                      isProMember: _isProMember,
                      saving: _memberSaving,
                      onTap: () {
                        setState(() => _isProMember = true);
                        AppFeedback.showMessage(context, '已应用 Pro 会员价模拟');
                      },
                    ),
                  ),
                  const InkSectionHeader(
                    title: '优惠券',
                    subtitle: '新人券、设备券、钓场券、会员券和满减券',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      children: [
                        for (final coupon in mallCoupons) ...[
                          _CouponTile(
                            coupon: coupon,
                            active:
                                coupon.id == _couponId &&
                                _couponEnabled(coupon),
                            enabled: _couponEnabled(coupon),
                            onTap: () => _selectCoupon(coupon),
                          ),
                          if (coupon != mallCoupons.last) SizedBox(height: 8.h),
                        ],
                      ],
                    ),
                  ),
                  const InkSectionHeader(
                    title: '套餐优惠',
                    subtitle: '按智能作钓组合自动提示',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: _PackageSavingCard(saving: _packageSaving),
                  ),
                ],
              ],
            ),
          ),
          if (hasItems)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartBottomBar(
                selectedCount: _selectedCount,
                subtotal: _subtotal,
                discount:
                    _activeMemberDiscount + _packageSaving + _couponDiscount,
                payable: _payable,
                onCheckout: _openCheckout,
              ),
            ),
        ],
      ),
    );
  }
}

class _CartEntry {
  _CartEntry({
    required this.product,
    required this.quantity,
    required this.selected,
    required this.addedFrom,
  });

  final MallProduct product;
  int quantity;
  bool selected;
  final String addedFrom;
}

List<_CartEntry> _buildInitialCartEntries() {
  final entries = <_CartEntry>[];
  for (final item in mallCartMockItems) {
    final product = mallProductById(item.productId);
    if (product == null) continue;
    entries.add(
      _CartEntry(
        product: product,
        quantity: item.quantity,
        selected: item.selected,
        addedFrom: item.addedFrom,
      ),
    );
  }
  return entries;
}

class _CartEmptyPanel extends StatelessWidget {
  const _CartEmptyPanel({required this.onMallTap, required this.onDeviceTap});

  final VoidCallback onMallTap;
  final VoidCallback onDeviceTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 56.h, 18.w, 0),
      child: InkCard(
        padding: EdgeInsets.all(18.r),
        child: Column(
          children: [
            const InkIconMark(
              icon: Icons.shopping_cart_outlined,
              color: InkPalette.lake,
              size: 64,
              iconSize: 30,
            ),
            SizedBox(height: 14.h),
            Text(
              '还没有添加装备，去看看适合你的作钓方案吧',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 17.sp,
                height: 1.28,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '智能鱼漂、夜钓套装、钓场套餐和配件会在这里统一结算。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 12.5.sp,
                height: 1.42,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: InkPrimaryButton(
                    label: '去商城看看',
                    icon: Icons.storefront_rounded,
                    onTap: onMallTap,
                    color: InkPalette.pine,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: InkPrimaryButton(
                    label: '查看智能装备',
                    icon: Icons.settings_input_antenna_rounded,
                    onTap: onDeviceTap,
                    color: InkPalette.lake,
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

class _CartOverviewCard extends StatelessWidget {
  const _CartOverviewCard({
    required this.selectedCount,
    required this.subtotal,
    required this.memberSaving,
    required this.couponDiscount,
  });

  final int selectedCount;
  final int subtotal;
  final int memberSaving;
  final int couponDiscount;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      child: Row(
        children: [
          Expanded(
            child: InkMetric(
              value: '$selectedCount件',
              label: '已选商品',
              icon: Icons.check_circle_rounded,
              color: InkPalette.pine,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(
              value: '¥$subtotal',
              label: '商品总价',
              icon: Icons.payments_rounded,
              color: InkPalette.cinnabar,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(
              value: '¥${memberSaving + couponDiscount}',
              label: '可省金额',
              icon: Icons.workspace_premium_rounded,
              color: InkPalette.reed,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartProductTile extends StatelessWidget {
  const _CartProductTile({
    required this.entry,
    required this.onSelected,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  final _CartEntry entry;
  final ValueChanged<bool> onSelected;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    final color = _categoryColor(product.category);
    return InkCard(
      padding: EdgeInsets.all(11.r),
      borderColor: entry.selected ? color.withValues(alpha: 0.32) : null,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 28.w,
                height: 38.h,
                child: Checkbox(
                  value: entry.selected,
                  activeColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  onChanged: (value) => onSelected(value ?? false),
                ),
              ),
              SizedBox(width: 8.w),
              _ProductThumb(product: product, size: 58),
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
                    SizedBox(height: 3.h),
                    Text(
                      product.scene,
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
                        _TinyPill(label: entry.addedFrom, color: color),
                        if (product.supportDeviceLink)
                          const _TinyPill(
                            label: 'App联动',
                            color: InkPalette.lake,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              InkPressable(
                onTap: onDelete,
                child: Padding(
                  padding: EdgeInsets.all(5.r),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: InkPalette.muted,
                    size: 19.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              SizedBox(width: 36.w),
              Expanded(child: _CartPriceText(product: product)),
              _CartQuantityStepper(
                quantity: entry.quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartPriceText extends StatelessWidget {
  const _CartPriceText({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'Pro价 ¥${product.memberPrice}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.cinnabar,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            '售价 ¥${product.price}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              decoration: product.memberPrice < product.price
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _CartQuantityStepper extends StatelessWidget {
  const _CartQuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 34.h),
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkPressable(
            onTap: onDecrement,
            child: Icon(
              Icons.remove_rounded,
              color: InkPalette.pine,
              size: 18.w,
            ),
          ),
          SizedBox(width: 9.w),
          Text(
            '$quantity',
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 9.w),
          InkPressable(
            onTap: onIncrement,
            child: Icon(Icons.add_rounded, color: InkPalette.pine, size: 18.w),
          ),
        ],
      ),
    );
  }
}

class _MemberSavingCard extends StatelessWidget {
  const _MemberSavingCard({
    required this.isProMember,
    required this.saving,
    required this.onTap,
  });

  final bool isProMember;
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
                  isProMember ? '江湖钓客 Pro 已生效' : '开通 Pro 后使用专业会员价',
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
                  isProMember
                      ? '本单已按会员价抵扣 ¥$saving'
                      : '本单预计可省 ¥$saving，包含设备延保和专属客服权益',
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
          SizedBox(width: 8.w),
          if (!isProMember)
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
                  '立即开通',
                  style: TextStyle(
                    color: InkPalette.ink,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
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
      borderColor: active ? color.withValues(alpha: 0.36) : null,
      color: active
          ? color.withValues(alpha: 0.10)
          : InkPalette.white.withValues(alpha: 0.96),
      child: Row(
        children: [
          InkIconMark(
            icon: Icons.confirmation_number_rounded,
            color: color,
            size: 40,
            iconSize: 20,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _TinyPill(label: coupon.scene, color: color),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  enabled
                      ? coupon.description
                      : coupon.memberOnly
                      ? '开通 Pro 后可用'
                      : '满 ¥${coupon.threshold} 可用',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            active ? '已选' : '¥${coupon.amount}',
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageSavingCard extends StatelessWidget {
  const _PackageSavingCard({required this.saving});

  final int saving;

  @override
  Widget build(BuildContext context) {
    final matched = saving > 0;
    return InkCard(
      padding: EdgeInsets.all(13.r),
      child: InkInfoRow(
        icon: matched ? Icons.auto_awesome_rounded : Icons.add_circle_outline,
        title: matched ? '夜钓智能组合已匹配' : '继续补齐场景套装',
        subtitle: matched
            ? '智能鱼漂 + 夜钓灯触发组合提示，本单套餐优惠 ¥$saving'
            : '加入夜钓灯、钓伞灯带或鱼漂电池仓，可形成完整作钓方案。',
        trailing: matched ? '-¥$saving' : '去补齐',
        color: matched ? InkPalette.pine : InkPalette.lake,
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.selectedCount,
    required this.subtotal,
    required this.discount,
    required this.payable,
    required this.onCheckout,
  });

  final int selectedCount;
  final int subtotal;
  final int discount;
  final int payable;
  final VoidCallback onCheckout;

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
                    selectedCount == 0 ? '未选择商品' : '合计 ¥$payable',
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
                    '商品 ¥$subtotal · 已优惠 ¥$discount',
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
              width: 126.w,
              child: InkPrimaryButton(
                label: '去结算',
                icon: Icons.receipt_long_rounded,
                onTap: selectedCount == 0 ? null : onCheckout,
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
      constraints: BoxConstraints(maxWidth: 92.w, minHeight: 23.h),
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
