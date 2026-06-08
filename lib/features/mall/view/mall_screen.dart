import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class MallScreen extends StatefulWidget {
  const MallScreen({super.key});

  @override
  State<MallScreen> createState() => _MallScreenState();
}

class _MallScreenState extends State<MallScreen> {
  int _selectedCategory = 0;
  String _searchQuery = '';
  String _selectedCouponId = _coupons.first.id;
  String _deliveryMethod = 'same_day';
  bool _usePoints = true;
  bool _rentalReserved = false;
  bool _hasNewAfterSale = false;
  int _pendingOrders = 1;
  int _shippingOrders = 2;
  int _afterSaleOrders = 0;
  String? _lastOrderNo;

  final Map<String, int> _cart = {};
  final Set<String> _favoriteProducts = {};

  _MallCategory get _activeCategory => _categories[_selectedCategory];

  int get _cartCount {
    var total = 0;
    for (final quantity in _cart.values) {
      total += quantity;
    }
    return total;
  }

  List<_Product> get _visibleProducts {
    final query = _searchQuery.trim().toLowerCase();
    final activeCategory = _activeCategory.id;

    final matches = _products.where((product) {
      final categoryMatched = product.categoryId == activeCategory;
      final queryMatched =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.desc.toLowerCase().contains(query) ||
          product.tags.any((tag) => tag.toLowerCase().contains(query));
      return categoryMatched && queryMatched;
    }).toList();

    if (matches.isNotEmpty || query.isNotEmpty) return matches;
    return _products.where((product) => product.featured).toList();
  }

  int get _cartSubtotal {
    var total = 0;
    _cart.forEach((productId, quantity) {
      final product = _productById(productId);
      if (product != null) total += product.price * quantity;
    });
    return total;
  }

  int get _memberDiscount => (_cartSubtotal * 0.05).round();

  int get _pointsDiscount {
    if (!_usePoints || _cartSubtotal == 0) return 0;
    final pointsAsMoney = (_memberPoints / 100).floor();
    return pointsAsMoney > 26 ? 26 : pointsAsMoney;
  }

  _Coupon? get _selectedCoupon {
    _Coupon? explicitCoupon;
    for (final coupon in _coupons) {
      if (coupon.id == _selectedCouponId) {
        explicitCoupon = coupon;
        break;
      }
    }
    if (explicitCoupon != null && _cartSubtotal >= explicitCoupon.threshold) {
      return explicitCoupon;
    }
    return _bestCouponForSubtotal(_cartSubtotal);
  }

  int get _couponDiscount {
    final coupon = _selectedCoupon;
    if (coupon == null || _cartSubtotal < coupon.threshold) return 0;
    final cap = _cartSubtotal - _memberDiscount;
    if (cap <= 0) return 0;
    return coupon.amount > cap ? cap : coupon.amount;
  }

  int get _payableAmount {
    final amount =
        _cartSubtotal - _memberDiscount - _couponDiscount - _pointsDiscount;
    return amount < 0 ? 0 : amount;
  }

  void _selectCategory(int index) {
    if (_selectedCategory == index) return;
    setState(() {
      _selectedCategory = index;
      _searchQuery = '';
    });
    AppFeedback.showMessage(context, '已筛选 ${_categories[index].label}');
  }

  void _addToCart(_Product product, {int quantity = 1, bool toast = true}) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + quantity;
    });
    if (toast) {
      AppFeedback.showMessage(context, '已加入购物车：${product.name}');
    }
  }

  void _removeFromCart(_Product product) {
    final quantity = _cart[product.id] ?? 0;
    if (quantity <= 0) return;
    setState(() {
      if (quantity == 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = quantity - 1;
      }
    });
  }

  void _clearCart() {
    setState(_cart.clear);
    AppFeedback.showMessage(context, '购物车已清空');
  }

  void _toggleFavorite(_Product product) {
    setState(() {
      if (_favoriteProducts.contains(product.id)) {
        _favoriteProducts.remove(product.id);
      } else {
        _favoriteProducts.add(product.id);
      }
    });
    AppFeedback.showMessage(
      context,
      _favoriteProducts.contains(product.id)
          ? '${product.name} 已收藏'
          : '${product.name} 已取消收藏',
    );
  }

  void _addGearCombo() {
    for (final productId in _gearComboProductIds) {
      final product = _productById(productId);
      if (product != null) {
        _cart[product.id] = (_cart[product.id] ?? 0) + 1;
      }
    }
    setState(() {});
    AppFeedback.showMessage(context, 'AI 装备组合已加入购物车');
  }

  void _applySearch(String query) {
    final text = query.trim();
    setState(() => _searchQuery = text);
    if (text.isNotEmpty) AppFeedback.showMessage(context, '已搜索：$text');
  }

  void _selectSearchProduct(_Product product) {
    final categoryIndex = _categories.indexWhere(
      (category) => category.id == product.categoryId,
    );
    setState(() {
      if (categoryIndex >= 0) _selectedCategory = categoryIndex;
      _searchQuery = product.name;
    });
    _showProductSheet(product);
  }

  void _placeOrder({required int payable}) {
    final orderNo = 'JH${DateTime.now().millisecondsSinceEpoch % 1000000}';
    setState(() {
      _cart.clear();
      _pendingOrders += 1;
      _lastOrderNo = orderNo;
    });
    AppFeedback.showMessage(context, '订单 $orderNo 已提交，待支付 ¥$payable');
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _activeCategory;
    final visibleProducts = _visibleProducts;

    return InkPage(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 32.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkTopBar(
              title: '商城服务',
              subtitle: '会员权益 · 装备组合 · 结算闭环',
              onBack: () => context.pop(),
              actions: [
                InkRoundButton(
                  icon: Icons.shopping_cart_outlined,
                  badge: _cartCount == 0 ? null : '$_cartCount',
                  onTap: _showCartSheet,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
              child: InkSearchBox(
                hint: _searchQuery.isEmpty
                    ? '搜索鱼竿、鱼轮、饵料、向导服务'
                    : '搜索：$_searchQuery',
                onTap: _showMallSearchSheet,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: _MallMemberCard(
                cartCount: _cartCount,
                favoriteCount: _favoriteProducts.length,
                onTap: _showMemberSheet,
                onCartTap: _showCartSheet,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
              child: InkPressable(
                onTap: _showGearComboSheet,
                child: InkLandscapeHero(
                  height: 156,
                  title: '钓无界 趣无穷',
                  subtitle: 'AI 根据今日鱼情推荐装备组合，减少试错。',
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: InkPalette.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '去看看',
                      style: TextStyle(
                        color: InkPalette.pine,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const InkSectionHeader(title: '服务分类', subtitle: '装备、租赁、向导、售后'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: InkCard(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final item = _categories[index];
                    return _CategoryTile(
                      category: item,
                      selected: index == _selectedCategory,
                      count: _products
                          .where((product) => product.categoryId == item.id)
                          .length,
                      onTap: () => _selectCategory(index),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: _CouponCheckoutCard(
                subtotal: _cartSubtotal,
                couponDiscount: _couponDiscount,
                pointsDiscount: _pointsDiscount,
                payable: _payableAmount,
                onTap: _showCheckoutSheet,
              ),
            ),
            InkSectionHeader(
              title: '智能推荐',
              subtitle: _searchQuery.isEmpty
                  ? '当前分类：${selectedCategory.label} · 适配今日鱼情'
                  : '当前分类：${selectedCategory.label} · 搜索 $_searchQuery',
              action: '全部',
              onAction: _showAllProductsSheet,
            ),
            if (visibleProducts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: _MallEmptyResult(
                  query: _searchQuery,
                  onClear: () => setState(() => _searchQuery = ''),
                ),
              )
            else
              SizedBox(
                height: 228.h,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleProducts.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final product = visibleProducts[index];
                    return _ProductCard(
                      product: product,
                      quantity: _cart[product.id] ?? 0,
                      favorite: _favoriteProducts.contains(product.id),
                      onTap: () => _showProductSheet(product),
                      onFavorite: () => _toggleFavorite(product),
                      onAdd: () => _addToCart(product),
                    );
                  },
                ),
              ),
            const InkSectionHeader(title: '服务与订单', subtitle: '购买、预约、售后进度'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  InkCard(
                    padding: EdgeInsets.all(13.r),
                    onTap: _showOrdersSheet,
                    child: InkInfoRow(
                      icon: Icons.receipt_long_rounded,
                      title: '我的订单',
                      subtitle:
                          '待付款 $_pendingOrders · 待发货 $_shippingOrders · 售后 $_afterSaleOrders',
                      trailing: '查看',
                      color: InkPalette.pine,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  InkCard(
                    padding: EdgeInsets.all(13.r),
                    onTap: _showRentalSheet,
                    child: InkInfoRow(
                      icon: Icons.local_shipping_rounded,
                      title: '本地租赁服务',
                      subtitle: _rentalReserved
                          ? '已预约明日 09:00 取还装备'
                          : '可预约鱼竿、探鱼器、露营装备',
                      trailing: _rentalReserved ? '已预约' : '预约',
                      color: InkPalette.lake,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  InkCard(
                    padding: EdgeInsets.all(13.r),
                    onTap: _showAfterSaleSheet,
                    child: InkInfoRow(
                      icon: Icons.support_agent_rounded,
                      title: '售后管家',
                      subtitle: _hasNewAfterSale
                          ? '已创建保养工单，客服待确认'
                          : '保养、维修、退换和押金退还',
                      trailing: _hasNewAfterSale ? '处理中' : '发起',
                      color: InkPalette.reed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMallSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _MallSearchSheet(
        initialQuery: _searchQuery,
        categories: _categories,
        products: _products,
        onApply: _applySearch,
        onSelectCategory: (category) {
          final index = _categories.indexWhere(
            (item) => item.id == category.id,
          );
          if (index >= 0) _selectCategory(index);
        },
        onSelectProduct: _selectSearchProduct,
        onClear: () {
          setState(() => _searchQuery = '');
          AppFeedback.showMessage(context, '已清空搜索');
        },
      ),
    );
  }

  void _showGearComboSheet() {
    final comboProducts = _gearComboProductIds
        .map(_productById)
        .whereType<_Product>()
        .toList();
    final comboPrice = comboProducts.fold<int>(
      0,
      (total, product) => total + product.price,
    );

    showInkActionSheet(
      context,
      title: 'AI 装备组合',
      subtitle: '轻量路亚竿 + 浅水纺车轮 + 浮水米诺，适合清晨浅水搜索',
      icon: Icons.auto_awesome_rounded,
      color: InkPalette.pine,
      showLandscape: true,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: '¥$comboPrice',
                label: '组合价',
                icon: Icons.shopping_bag_rounded,
                color: InkPalette.pine,
              ),
            ),
            SizedBox(width: 8.w),
            const Expanded(
              child: InkMetric(
                value: '3件',
                label: '装备清单',
                icon: Icons.inventory_2_rounded,
                color: InkPalette.lake,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        for (final product in comboProducts) ...[
          _SheetMiniProduct(product: product),
          SizedBox(height: 8.h),
        ],
      ],
      actions: [
        InkSheetAction(
          icon: Icons.add_shopping_cart_rounded,
          title: '一键加入购物车',
          subtitle: '加入竿、轮、饵三件组合',
          color: InkPalette.pine,
          onTap: _addGearCombo,
        ),
        InkSheetAction(
          icon: Icons.tune_rounded,
          title: '按预算替换装备',
          subtitle: '切到配件分类，手动挑选更经济组合',
          color: InkPalette.lake,
          onTap: () {
            final index = _categories.indexWhere((item) => item.id == 'gear');
            if (index >= 0) _selectCategory(index);
          },
        ),
      ],
    );
  }

  void _showMemberSheet() {
    showInkActionSheet(
      context,
      title: '江湖钓客会员',
      subtitle: '会员、积分、优惠券和租赁权益统一沉淀',
      icon: Icons.workspace_premium_rounded,
      color: InkPalette.reed,
      children: [
        Row(
          children: [
            const Expanded(
              child: InkMetric(
                value: '95折',
                label: '装备会员价',
                icon: Icons.verified_rounded,
                color: InkPalette.reed,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: '$_memberPoints',
                label: '可用积分',
                icon: Icons.stars_rounded,
                color: InkPalette.pine,
              ),
            ),
          ],
        ),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.confirmation_number_rounded,
          title: '优惠券包',
          subtitle: '当前可用 ${_coupons.length} 张，结算自动匹配门槛',
          color: InkPalette.cinnabar,
          onTap: _showCheckoutSheet,
        ),
        InkSheetAction(
          icon: Icons.stars_rounded,
          title: _usePoints ? '关闭积分抵扣' : '开启积分抵扣',
          subtitle: _usePoints ? '结算时暂不使用积分' : '100 积分抵 ¥1，最多抵 ¥26',
          color: InkPalette.reed,
          onTap: () {
            setState(() => _usePoints = !_usePoints);
            AppFeedback.showMessage(
              context,
              _usePoints ? '已开启积分抵扣' : '已关闭积分抵扣',
            );
          },
        ),
        InkSheetAction(
          icon: Icons.support_agent_rounded,
          title: '会员售后',
          subtitle: '装备保养、质保提醒和优先客服',
          color: InkPalette.moss,
          onTap: _showAfterSaleSheet,
        ),
      ],
    );
  }

  void _showCheckoutSheet() {
    if (_cartCount == 0) {
      showInkActionSheet(
        context,
        title: '结算流程',
        subtitle: '购物车为空，先加入装备或服务后再结算',
        icon: Icons.payments_rounded,
        color: InkPalette.cinnabar,
        actions: [
          InkSheetAction(
            icon: Icons.auto_awesome_rounded,
            title: '加入 AI 装备组合',
            subtitle: '竿、轮、饵三件组合，适合今日鱼情',
            color: InkPalette.pine,
            onTap: _addGearCombo,
          ),
          InkSheetAction(
            icon: Icons.storefront_rounded,
            title: '浏览全部商品',
            subtitle: '装备、租赁、向导和售后服务',
            color: InkPalette.lake,
            onTap: _showAllProductsSheet,
          ),
        ],
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _CheckoutSheet(
        cartCount: _cartCount,
        subtotal: _cartSubtotal,
        memberDiscount: _memberDiscount,
        maxPointsDiscount: (_memberPoints / 100).floor() > 26
            ? 26
            : (_memberPoints / 100).floor(),
        coupons: _coupons,
        selectedCouponId: _selectedCouponId,
        usePoints: _usePoints,
        deliveryMethod: _deliveryMethod,
        onCouponChanged: (id) => setState(() => _selectedCouponId = id),
        onUsePointsChanged: (value) => setState(() => _usePoints = value),
        onDeliveryChanged: (method) => setState(() => _deliveryMethod = method),
        onSubmit: (payable) => _placeOrder(payable: payable),
      ),
    );
  }

  void _showAllProductsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _AllProductsSheet(
        categories: _categories,
        products: _products,
        favorites: _favoriteProducts,
        cart: _cart,
        onSelectCategory: (category) {
          final index = _categories.indexWhere(
            (item) => item.id == category.id,
          );
          if (index >= 0) _selectCategory(index);
        },
        onProductTap: _showProductSheet,
        onAdd: _addToCart,
        onFavorite: _toggleFavorite,
      ),
    );
  }

  void _showProductSheet(_Product product) {
    showInkActionSheet(
      context,
      title: product.name,
      subtitle: '${product.desc} · ¥${product.price}${product.unit}',
      icon: product.icon,
      color: product.color,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: product.rating.toStringAsFixed(1),
                label: '评分',
                icon: Icons.star_rounded,
                color: product.color,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: product.delivery,
                label: '履约',
                icon: Icons.local_shipping_rounded,
                color: InkPalette.lake,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _ProductDetailNote(product: product),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.add_shopping_cart_rounded,
          title: '加入购物车',
          subtitle: '稍后一起结算',
          color: InkPalette.pine,
          onTap: () => _addToCart(product),
        ),
        InkSheetAction(
          icon: _favoriteProducts.contains(product.id)
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          title: _favoriteProducts.contains(product.id) ? '取消收藏' : '收藏商品',
          subtitle: _favoriteProducts.contains(product.id)
              ? '从我的收藏移除'
              : '保存到会员收藏夹',
          color: InkPalette.cinnabar,
          onTap: () => _toggleFavorite(product),
        ),
        InkSheetAction(
          icon: Icons.support_agent_rounded,
          title: '咨询服务',
          subtitle: '询问适配鱼情、保养和售后',
          color: InkPalette.lake,
          onTap: () => AppFeedback.showMessage(context, '已为你接入商城客服'),
        ),
      ],
    );
  }

  void _showCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: InkPalette.ink.withValues(alpha: 0.24),
      builder: (_) => _MallCartSheet(
        cart: _cart,
        products: _products,
        onIncrement: (product) => _addToCart(product, toast: false),
        onDecrement: _removeFromCart,
        onClear: _clearCart,
        onCheckout: _showCheckoutSheet,
      ),
    );
  }

  void _showOrdersSheet() {
    showInkActionSheet(
      context,
      title: '我的订单',
      subtitle: _lastOrderNo == null
          ? '待付款 $_pendingOrders · 待发货 $_shippingOrders · 售后 $_afterSaleOrders'
          : '最近订单 $_lastOrderNo · 待付款 $_pendingOrders',
      icon: Icons.receipt_long_rounded,
      color: InkPalette.pine,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: '$_pendingOrders',
                label: '待付款',
                icon: Icons.payments_rounded,
                color: InkPalette.cinnabar,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: '$_shippingOrders',
                label: '待发货',
                icon: Icons.local_shipping_rounded,
                color: InkPalette.lake,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkMetric(
                value: '$_afterSaleOrders',
                label: '售后',
                icon: Icons.support_agent_rounded,
                color: InkPalette.reed,
              ),
            ),
          ],
        ),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.payments_rounded,
          title: '模拟支付待付款',
          subtitle: '前端演示：待付款转为待发货',
          color: InkPalette.pine,
          onTap: () {
            if (_pendingOrders == 0) {
              AppFeedback.showMessage(context, '暂无待付款订单');
              return;
            }
            setState(() {
              _pendingOrders -= 1;
              _shippingOrders += 1;
            });
            AppFeedback.showMessage(context, '支付成功，订单已进入待发货');
          },
        ),
        InkSheetAction(
          icon: Icons.local_shipping_rounded,
          title: '查看物流节点',
          subtitle: '同城订单预计 24 小时内送达',
          color: InkPalette.lake,
          onTap: () => AppFeedback.showMessage(context, '物流节点已刷新'),
        ),
      ],
    );
  }

  void _showRentalSheet() {
    showInkActionSheet(
      context,
      title: '本地租赁服务',
      subtitle: _rentalReserved
          ? '已预约明日 09:00 取件，免押权益已锁定'
          : '可预约鱼竿、探鱼器、露营装备，会员支持免押',
      icon: Icons.local_shipping_rounded,
      color: InkPalette.lake,
      children: [
        Row(
          children: const [
            Expanded(
              child: InkMetric(
                value: '免押',
                label: '会员权益',
                icon: Icons.verified_rounded,
                color: InkPalette.reed,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: InkMetric(
                value: '2公里',
                label: '附近门店',
                icon: Icons.place_rounded,
                color: InkPalette.lake,
              ),
            ),
          ],
        ),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.event_available_rounded,
          title: _rentalReserved ? '调整预约时间' : '预约明日取件',
          subtitle: '09:00-11:00 到店取，20:00 前归还',
          color: InkPalette.lake,
          onTap: () {
            setState(() => _rentalReserved = true);
            AppFeedback.showMessage(context, '租赁预约已确认');
          },
        ),
        InkSheetAction(
          icon: Icons.sensors_rounded,
          title: '租赁探鱼设备',
          subtitle: '押金、归还和数据清除流程可在结算中确认',
          color: InkPalette.moss,
          onTap: () {
            final product = _productById('device-finder-rent');
            if (product != null) _addToCart(product);
          },
        ),
      ],
    );
  }

  void _showAfterSaleSheet() {
    showInkActionSheet(
      context,
      title: '售后管家',
      subtitle: '保养、维修、退换和押金退还，先做前端工单流转',
      icon: Icons.support_agent_rounded,
      color: InkPalette.reed,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: _hasNewAfterSale ? '处理中' : '可发起',
                label: '保养工单',
                icon: Icons.handyman_rounded,
                color: InkPalette.reed,
              ),
            ),
            SizedBox(width: 8.w),
            const Expanded(
              child: InkMetric(
                value: '48h',
                label: '响应承诺',
                icon: Icons.verified_user_rounded,
                color: InkPalette.moss,
              ),
            ),
          ],
        ),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.handyman_rounded,
          title: '发起鱼轮保养',
          subtitle: '创建售后工单并加入服务订单',
          color: InkPalette.reed,
          onTap: () {
            setState(() {
              _hasNewAfterSale = true;
              _afterSaleOrders += 1;
            });
            AppFeedback.showMessage(context, '售后工单已创建');
          },
        ),
        InkSheetAction(
          icon: Icons.assignment_return_rounded,
          title: '退换 / 押金退还',
          subtitle: '前端先展示规则和节点，后续接后台',
          color: InkPalette.lake,
          onTap: () => AppFeedback.showMessage(context, '已打开退换规则'),
        ),
      ],
    );
  }
}

class _MallMemberCard extends StatelessWidget {
  const _MallMemberCard({
    required this.cartCount,
    required this.favoriteCount,
    required this.onTap,
    required this.onCartTap,
  });

  final int cartCount;
  final int favoriteCount;
  final VoidCallback onTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(14.r),
      onTap: onTap,
      color: InkPalette.ink.withValues(alpha: 0.88),
      borderColor: InkPalette.reed.withValues(alpha: 0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InkSeal(text: '会\n员'),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '江湖钓客会员',
                      style: TextStyle(
                        color: InkPalette.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        fontFamilyFallback: brushFontFallback,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '积分 $_memberPoints · 优惠券 ${_coupons.length} 张 · 同城租赁免押',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.white.withValues(alpha: 0.72),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkChip(
                label: cartCount == 0 ? '购物车' : '购物车 $cartCount',
                active: true,
                color: InkPalette.reed,
                onTap: onCartTap,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Expanded(
                child: _MemberMetric(value: '95折', label: '装备'),
              ),
              SizedBox(width: 8.w),
              const Expanded(
                child: _MemberMetric(value: '免押', label: '租赁'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MemberMetric(
                  value: favoriteCount == 0 ? '优先' : '$favoriteCount藏',
                  label: '售后',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberMetric extends StatelessWidget {
  const _MemberMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: InkPalette.reed,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: InkPalette.white.withValues(alpha: 0.90),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final _MallCategory category;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: selected
                  ? category.color
                  : category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: selected
                    ? category.color
                    : category.color.withValues(alpha: 0.2),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    category.icon,
                    color: selected ? InkPalette.white : category.color,
                    size: 22.w,
                  ),
                ),
                Positioned(
                  right: -3.w,
                  top: -4.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? InkPalette.reed : InkPalette.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? InkPalette.reed
                            : category.color.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? InkPalette.ink : category.color,
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? category.color : InkPalette.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCheckoutCard extends StatelessWidget {
  const _CouponCheckoutCard({
    required this.subtotal,
    required this.couponDiscount,
    required this.pointsDiscount,
    required this.payable,
    required this.onTap,
  });

  final int subtotal;
  final int couponDiscount;
  final int pointsDiscount;
  final int payable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = couponDiscount + pointsDiscount;
    return InkCard(
      padding: EdgeInsets.all(13.r),
      onTap: onTap,
      child: Column(
        children: [
          InkInfoRow(
            icon: Icons.receipt_long_rounded,
            title: '优惠券 / 积分 / 结算',
            subtitle: subtotal == 0
                ? '平台券、会员积分、押金租赁和售后承诺'
                : '商品 ¥$subtotal · 已优惠 ¥$discount · 待付 ¥$payable',
            trailing: subtotal == 0 ? '去结算' : '确认',
            color: InkPalette.cinnabar,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InkMetric(
                  value: '¥$couponDiscount',
                  label: '券优惠',
                  icon: Icons.confirmation_number_rounded,
                  color: InkPalette.cinnabar,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkMetric(
                  value: '¥$pointsDiscount',
                  label: '积分抵扣',
                  icon: Icons.stars_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkMetric(
                  value: subtotal == 0 ? '3步' : '¥$payable',
                  label: '结算',
                  icon: Icons.payments_rounded,
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAdd,
  });

  final _Product product;
  final int quantity;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154.w,
      child: InkCard(
        padding: EdgeInsets.all(10.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: product.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Icon(product.icon, color: product.color, size: 44.w),
                  ),
                  Positioned(
                    left: 7.w,
                    top: 7.h,
                    child: _TinyBadge(
                      label: product.badge,
                      color: product.color,
                    ),
                  ),
                  if (quantity > 0)
                    Positioned(
                      left: 7.w,
                      bottom: 7.h,
                      child: _TinyBadge(
                        label: '已加 $quantity',
                        color: InkPalette.cinnabar,
                      ),
                    ),
                  Positioned(
                    right: 6.w,
                    top: 6.h,
                    child: InkPressable(
                      onTap: onFavorite,
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: InkPalette.white.withValues(alpha: 0.82),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? InkPalette.cinnabar
                              : InkPalette.muted,
                          size: 17.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              product.desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '¥${product.price}${product.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.cinnabar,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InkPressable(
                  onTap: onAdd,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: const BoxDecoration(
                      color: InkPalette.pine,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: InkPalette.white,
                      size: 16.w,
                    ),
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

class _MallEmptyResult extends StatelessWidget {
  const _MallEmptyResult({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        children: [
          InkIconMark(
            icon: Icons.search_off_rounded,
            color: InkPalette.muted,
            size: 48,
            iconSize: 24,
          ),
          SizedBox(height: 10.h),
          Text(
            '没有找到「$query」',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '可以换个关键词，或者清空搜索继续浏览当前分类。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14.h),
          InkPrimaryButton(
            label: '清空搜索',
            icon: Icons.close_rounded,
            onTap: onClear,
            color: InkPalette.pine,
          ),
        ],
      ),
    );
  }
}

class _MallSearchSheet extends StatefulWidget {
  const _MallSearchSheet({
    required this.initialQuery,
    required this.categories,
    required this.products,
    required this.onApply,
    required this.onSelectCategory,
    required this.onSelectProduct,
    required this.onClear,
  });

  final String initialQuery;
  final List<_MallCategory> categories;
  final List<_Product> products;
  final ValueChanged<String> onApply;
  final ValueChanged<_MallCategory> onSelectCategory;
  final ValueChanged<_Product> onSelectProduct;
  final VoidCallback onClear;

  @override
  State<_MallSearchSheet> createState() => _MallSearchSheetState();
}

class _MallSearchSheetState extends State<_MallSearchSheet> {
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

  List<_Product> get _results {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.products.where((item) => item.featured).toList();
    }
    return widget.products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.desc.toLowerCase().contains(query) ||
          product.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  void _apply() {
    widget.onApply(_controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: InkPalette.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const InkInfoRow(
                    icon: Icons.search_rounded,
                    title: '商品搜索',
                    subtitle: '支持装备、服务、订单和售后关键词',
                    color: InkPalette.pine,
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: InkPalette.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: InkPalette.line),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _apply(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search_rounded,
                          color: InkPalette.muted,
                          size: 20.w,
                        ),
                        hintText: '输入鱼竿、鱼轮、向导、保养',
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: InkPalette.muted,
                                  size: 18.w,
                                ),
                              ),
                      ),
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (final category in widget.categories)
                        InkChip(
                          label: category.label,
                          icon: category.icon,
                          color: category.color,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelectCategory(category);
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    _controller.text.trim().isEmpty ? '热门推荐' : '搜索结果',
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (results.isEmpty)
                    InkCard(
                      padding: EdgeInsets.all(12.r),
                      color: InkPalette.paper.withValues(alpha: 0.72),
                      child: const InkInfoRow(
                        icon: Icons.search_off_rounded,
                        title: '暂无匹配',
                        subtitle: '可以换个词，或者清空搜索',
                        color: InkPalette.muted,
                      ),
                    )
                  else
                    for (var i = 0; i < results.length; i++) ...[
                      InkCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 11.h,
                        ),
                        color: InkPalette.paper.withValues(alpha: 0.72),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelectProduct(results[i]);
                        },
                        child: InkInfoRow(
                          icon: results[i].icon,
                          title: results[i].name,
                          subtitle:
                              '${results[i].desc} · ¥${results[i].price}${results[i].unit}',
                          trailing: '查看',
                          color: results[i].color,
                        ),
                      ),
                      if (i != results.length - 1) SizedBox(height: 9.h),
                    ],
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkPrimaryButton(
                          label: '清空',
                          icon: Icons.close_rounded,
                          onTap: () {
                            widget.onClear();
                            Navigator.of(context).pop();
                          },
                          color: InkPalette.muted,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkPrimaryButton(
                          label: '搜索',
                          icon: Icons.search_rounded,
                          onTap: _apply,
                          color: InkPalette.pine,
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

class _AllProductsSheet extends StatefulWidget {
  const _AllProductsSheet({
    required this.categories,
    required this.products,
    required this.favorites,
    required this.cart,
    required this.onSelectCategory,
    required this.onProductTap,
    required this.onAdd,
    required this.onFavorite,
  });

  final List<_MallCategory> categories;
  final List<_Product> products;
  final Set<String> favorites;
  final Map<String, int> cart;
  final ValueChanged<_MallCategory> onSelectCategory;
  final ValueChanged<_Product> onProductTap;
  final ValueChanged<_Product> onAdd;
  final ValueChanged<_Product> onFavorite;

  @override
  State<_AllProductsSheet> createState() => _AllProductsSheetState();
}

class _AllProductsSheetState extends State<_AllProductsSheet> {
  String _categoryId = _categories.first.id;

  List<_Product> get _products {
    return widget.products
        .where((product) => product.categoryId == _categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: InkPalette.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const InkInfoRow(
                    icon: Icons.storefront_rounded,
                    title: '全部商品',
                    subtitle: '装备、租赁、向导、维修和售后服务',
                    color: InkPalette.pine,
                  ),
                  SizedBox(height: 14.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final category in widget.categories) ...[
                          InkChip(
                            label: category.label,
                            icon: category.icon,
                            active: _categoryId == category.id,
                            color: category.color,
                            onTap: () {
                              setState(() => _categoryId = category.id);
                              widget.onSelectCategory(category);
                            },
                          ),
                          SizedBox(width: 8.w),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  for (var i = 0; i < products.length; i++) ...[
                    _SheetProductRow(
                      product: products[i],
                      quantity: widget.cart[products[i].id] ?? 0,
                      favorite: widget.favorites.contains(products[i].id),
                      onTap: () => widget.onProductTap(products[i]),
                      onAdd: () {
                        widget.onAdd(products[i]);
                        setState(() {});
                      },
                      onFavorite: () {
                        widget.onFavorite(products[i]);
                        setState(() {});
                      },
                    ),
                    if (i != products.length - 1) SizedBox(height: 9.h),
                  ],
                  SizedBox(height: 16.h),
                  InkPrimaryButton(
                    label: '完成',
                    onTap: () => Navigator.of(context).pop(),
                    color: InkPalette.pine,
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

class _MallCartSheet extends StatefulWidget {
  const _MallCartSheet({
    required this.cart,
    required this.products,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onCheckout,
  });

  final Map<String, int> cart;
  final List<_Product> products;
  final ValueChanged<_Product> onIncrement;
  final ValueChanged<_Product> onDecrement;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  @override
  State<_MallCartSheet> createState() => _MallCartSheetState();
}

class _MallCartSheetState extends State<_MallCartSheet> {
  List<_CartItem> get _items {
    final items = <_CartItem>[];
    widget.cart.forEach((id, quantity) {
      final product = _productById(id);
      if (product != null && quantity > 0) {
        items.add(_CartItem(product: product, quantity: quantity));
      }
    });
    return items;
  }

  int get _subtotal {
    var total = 0;
    for (final item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: InkPalette.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  InkInfoRow(
                    icon: Icons.shopping_cart_rounded,
                    title: '购物车',
                    subtitle: items.isEmpty
                        ? '购物车还是空的'
                        : '已加入 ${widget.cart.values.fold<int>(0, (a, b) => a + b)} 件装备或服务',
                    color: InkPalette.pine,
                  ),
                  SizedBox(height: 14.h),
                  if (items.isEmpty)
                    InkCard(
                      padding: EdgeInsets.all(14.r),
                      color: InkPalette.paper.withValues(alpha: 0.72),
                      child: const InkInfoRow(
                        icon: Icons.auto_awesome_rounded,
                        title: '先挑一套装备',
                        subtitle: '可以从 AI 组合或全部商品加入购物车',
                        color: InkPalette.lake,
                      ),
                    )
                  else ...[
                    for (var i = 0; i < items.length; i++) ...[
                      _CartLine(
                        item: items[i],
                        onIncrement: () {
                          widget.onIncrement(items[i].product);
                          setState(() {});
                        },
                        onDecrement: () {
                          widget.onDecrement(items[i].product);
                          setState(() {});
                        },
                      ),
                      if (i != items.length - 1) SizedBox(height: 9.h),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkMetric(
                            value: '¥$_subtotal',
                            label: '商品小计',
                            icon: Icons.payments_rounded,
                            color: InkPalette.cinnabar,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: InkMetric(
                            value: '${items.length}类',
                            label: '服务类型',
                            icon: Icons.inventory_2_rounded,
                            color: InkPalette.lake,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkPrimaryButton(
                            label: '清空',
                            icon: Icons.delete_outline_rounded,
                            onTap: () {
                              widget.onClear();
                              setState(() {});
                            },
                            color: InkPalette.muted,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkPrimaryButton(
                            label: '去结算',
                            icon: Icons.receipt_long_rounded,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onCheckout();
                            },
                            color: InkPalette.pine,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 16.h),
                  InkPrimaryButton(
                    label: '完成',
                    onTap: () => Navigator.of(context).pop(),
                    color: InkPalette.pine,
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

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({
    required this.cartCount,
    required this.subtotal,
    required this.memberDiscount,
    required this.maxPointsDiscount,
    required this.coupons,
    required this.selectedCouponId,
    required this.usePoints,
    required this.deliveryMethod,
    required this.onCouponChanged,
    required this.onUsePointsChanged,
    required this.onDeliveryChanged,
    required this.onSubmit,
  });

  final int cartCount;
  final int subtotal;
  final int memberDiscount;
  final int maxPointsDiscount;
  final List<_Coupon> coupons;
  final String selectedCouponId;
  final bool usePoints;
  final String deliveryMethod;
  final ValueChanged<String> onCouponChanged;
  final ValueChanged<bool> onUsePointsChanged;
  final ValueChanged<String> onDeliveryChanged;
  final ValueChanged<int> onSubmit;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late String _couponId;
  late bool _usePoints;
  late String _deliveryMethod;

  @override
  void initState() {
    super.initState();
    _couponId =
        _bestCouponForSubtotal(widget.subtotal)?.id ?? widget.selectedCouponId;
    _usePoints = widget.usePoints;
    _deliveryMethod = widget.deliveryMethod;
  }

  _Coupon? get _coupon {
    for (final coupon in widget.coupons) {
      if (coupon.id == _couponId) return coupon;
    }
    return null;
  }

  int get _couponDiscount {
    final coupon = _coupon;
    if (coupon == null || widget.subtotal < coupon.threshold) return 0;
    final cap = widget.subtotal - widget.memberDiscount;
    if (cap <= 0) return 0;
    return coupon.amount > cap ? cap : coupon.amount;
  }

  int get _pointsDiscount => _usePoints ? widget.maxPointsDiscount : 0;

  int get _payable {
    final amount =
        widget.subtotal -
        widget.memberDiscount -
        _couponDiscount -
        _pointsDiscount;
    return amount < 0 ? 0 : amount;
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
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: InkPalette.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  InkInfoRow(
                    icon: Icons.payments_rounded,
                    title: '确认结算',
                    subtitle: '${widget.cartCount} 件装备或服务 · 会员优惠已生效',
                    color: InkPalette.cinnabar,
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkMetric(
                          value: '¥${widget.subtotal}',
                          label: '商品金额',
                          icon: Icons.shopping_bag_rounded,
                          color: InkPalette.pine,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: InkMetric(
                          value: '-¥${widget.memberDiscount}',
                          label: '会员 95折',
                          icon: Icons.workspace_premium_rounded,
                          color: InkPalette.reed,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '选择优惠券',
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  for (final coupon in widget.coupons) ...[
                    _CouponOption(
                      coupon: coupon,
                      active:
                          coupon.id == _couponId &&
                          widget.subtotal >= coupon.threshold,
                      enabled: widget.subtotal >= coupon.threshold,
                      onTap: () => setState(() => _couponId = coupon.id),
                    ),
                    SizedBox(height: 8.h),
                  ],
                  SizedBox(height: 4.h),
                  _CheckoutToggle(
                    title: '使用 $_memberPoints 积分抵扣',
                    subtitle: _usePoints ? '本单抵扣 ¥$_pointsDiscount' : '已关闭积分抵扣',
                    value: _usePoints,
                    onChanged: (value) => setState(() => _usePoints = value),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '履约方式',
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _DeliveryOption(
                          icon: Icons.local_shipping_rounded,
                          title: '同城达',
                          subtitle: '24h',
                          active: _deliveryMethod == 'same_day',
                          color: InkPalette.lake,
                          onTap: () =>
                              setState(() => _deliveryMethod = 'same_day'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _DeliveryOption(
                          icon: Icons.storefront_rounded,
                          title: '到店取',
                          subtitle: '免运费',
                          active: _deliveryMethod == 'pickup',
                          color: InkPalette.pine,
                          onTap: () =>
                              setState(() => _deliveryMethod = 'pickup'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  InkCard(
                    padding: EdgeInsets.all(12.r),
                    color: InkPalette.paper.withValues(alpha: 0.72),
                    child: Column(
                      children: [
                        _CheckoutLine(
                          label: '商品金额',
                          value: '¥${widget.subtotal}',
                        ),
                        _CheckoutLine(
                          label: '会员折扣',
                          value: '-¥${widget.memberDiscount}',
                        ),
                        _CheckoutLine(
                          label: '优惠券',
                          value: '-¥$_couponDiscount',
                        ),
                        _CheckoutLine(
                          label: '积分抵扣',
                          value: '-¥$_pointsDiscount',
                        ),
                        Divider(color: InkPalette.line.withValues(alpha: 0.7)),
                        _CheckoutLine(
                          label: '应付金额',
                          value: '¥$_payable',
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  InkPrimaryButton(
                    label: '确认结算 ¥$_payable',
                    icon: Icons.payments_rounded,
                    onTap: () {
                      widget.onCouponChanged(_couponId);
                      widget.onUsePointsChanged(_usePoints);
                      widget.onDeliveryChanged(_deliveryMethod);
                      Navigator.of(context).pop();
                      widget.onSubmit(_payable);
                    },
                    color: InkPalette.cinnabar,
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

class _SheetMiniProduct extends StatelessWidget {
  const _SheetMiniProduct({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color: InkPalette.paper.withValues(alpha: 0.72),
      child: InkInfoRow(
        icon: product.icon,
        title: product.name,
        subtitle: '${product.desc} · ¥${product.price}${product.unit}',
        color: product.color,
      ),
    );
  }
}

class _SheetProductRow extends StatelessWidget {
  const _SheetProductRow({
    required this.product,
    required this.quantity,
    required this.favorite,
    required this.onTap,
    required this.onAdd,
    required this.onFavorite,
  });

  final _Product product;
  final int quantity;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      color: InkPalette.paper.withValues(alpha: 0.72),
      onTap: onTap,
      child: Row(
        children: [
          InkIconMark(
            icon: product.icon,
            color: product.color,
            size: 40,
            iconSize: 20,
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${product.desc} · ¥${product.price}${product.unit}',
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
          InkPressable(
            onTap: onFavorite,
            child: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? InkPalette.cinnabar : InkPalette.muted,
              size: 20.w,
            ),
          ),
          SizedBox(width: 10.w),
          InkPressable(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: InkPalette.pine,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                quantity == 0 ? '加入' : '加$quantity',
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 11.sp,
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

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final _CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      color: InkPalette.paper.withValues(alpha: 0.72),
      child: Row(
        children: [
          InkIconMark(
            icon: product.icon,
            color: product.color,
            size: 40,
            iconSize: 20,
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '¥${product.price}${product.unit} · ${product.delivery}',
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
          _QuantityStepper(
            quantity: item.quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
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
          SizedBox(width: 8.w),
          Text(
            '$quantity',
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 8.w),
          InkPressable(
            onTap: onIncrement,
            child: Icon(Icons.add_rounded, color: InkPalette.pine, size: 18.w),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailNote extends StatelessWidget {
  const _ProductDetailNote({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: InkPalette.paper.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.note,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.sp,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final tag in product.tags.take(4))
                _TinyBadge(label: tag, color: product.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponOption extends StatelessWidget {
  const _CouponOption({
    required this.coupon,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final _Coupon coupon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? InkPalette.cinnabar : InkPalette.muted;
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      color: active
          ? color.withValues(alpha: 0.12)
          : InkPalette.paper.withValues(alpha: 0.72),
      borderColor: active ? color : InkPalette.ink.withValues(alpha: 0.16),
      onTap: enabled ? onTap : null,
      child: InkInfoRow(
        icon: Icons.confirmation_number_rounded,
        title: coupon.title,
        subtitle: enabled ? coupon.subtitle : '满 ¥${coupon.threshold} 可用',
        trailing: enabled ? (active ? '已选' : '选择') : '未达',
        color: color,
      ),
    );
  }
}

class _CheckoutToggle extends StatelessWidget {
  const _CheckoutToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      color: InkPalette.paper.withValues(alpha: 0.72),
      child: Row(
        children: [
          const InkIconMark(
            icon: Icons.stars_rounded,
            color: InkPalette.reed,
            size: 38,
            iconSize: 19,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
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
          Switch(
            value: value,
            activeThumbColor: InkPalette.pine,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.14)
              : InkPalette.paper.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: active ? color : InkPalette.ink.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            InkIconMark(icon: icon, color: color, size: 34, iconSize: 17),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
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
          ],
        ),
      ),
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({
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
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? InkPalette.text : InkPalette.muted,
                fontSize: strong ? 14.sp : 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong ? InkPalette.cinnabar : InkPalette.text,
              fontSize: strong ? 18.sp : 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: InkPalette.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MallCategory {
  const _MallCategory({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String label;
  final Color color;
}

class _Product {
  const _Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.desc,
    required this.note,
    required this.price,
    required this.icon,
    required this.color,
    required this.badge,
    required this.delivery,
    required this.rating,
    required this.tags,
    this.unit = '',
    this.featured = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final String desc;
  final String note;
  final int price;
  final IconData icon;
  final Color color;
  final String badge;
  final String delivery;
  final double rating;
  final List<String> tags;
  final String unit;
  final bool featured;
}

class _Coupon {
  const _Coupon({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.threshold,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final int threshold;
}

class _CartItem {
  const _CartItem({required this.product, required this.quantity});

  final _Product product;
  final int quantity;
}

_Product? _productById(String id) {
  for (final product in _products) {
    if (product.id == id) return product;
  }
  return null;
}

_Coupon? _bestCouponForSubtotal(int subtotal) {
  _Coupon? best;
  for (final coupon in _coupons) {
    if (subtotal < coupon.threshold) continue;
    if (best == null || coupon.amount > best.amount) best = coupon;
  }
  return best;
}

const _memberPoints = 2680;

const _gearComboProductIds = [
  'rod-stream-lure',
  'reel-shallow-3000',
  'bait-minnow-95',
];

const _categories = [
  _MallCategory(
    id: 'rod',
    icon: Icons.phishing_rounded,
    label: '鱼竿',
    color: InkPalette.pine,
  ),
  _MallCategory(
    id: 'reel',
    icon: Icons.adjust_rounded,
    label: '鱼轮',
    color: InkPalette.lake,
  ),
  _MallCategory(
    id: 'bait',
    icon: Icons.grain_rounded,
    label: '饵料',
    color: InkPalette.reed,
  ),
  _MallCategory(
    id: 'parts',
    icon: Icons.build_rounded,
    label: '配件',
    color: InkPalette.moss,
  ),
  _MallCategory(
    id: 'gear',
    icon: Icons.backpack_rounded,
    label: '装备',
    color: InkPalette.pine,
  ),
  _MallCategory(
    id: 'guide',
    icon: Icons.map_rounded,
    label: '向导',
    color: InkPalette.lake,
  ),
  _MallCategory(
    id: 'device',
    icon: Icons.sensors_rounded,
    label: '设备',
    color: InkPalette.moss,
  ),
  _MallCategory(
    id: 'service',
    icon: Icons.support_agent_rounded,
    label: '售后',
    color: InkPalette.reed,
  ),
];

const _coupons = [
  _Coupon(
    id: 'gear80',
    title: '装备满 899 减 80',
    subtitle: '鱼竿、鱼轮、装备组合可用',
    amount: 80,
    threshold: 899,
  ),
  _Coupon(
    id: 'service30',
    title: '服务满 299 减 30',
    subtitle: '向导、租赁和保养服务可用',
    amount: 30,
    threshold: 299,
  ),
  _Coupon(
    id: 'combo120',
    title: '组合满 1299 减 120',
    subtitle: '跨分类组合结算可用',
    amount: 120,
    threshold: 1299,
  ),
];

const _products = [
  _Product(
    id: 'rod-stream-lure',
    categoryId: 'rod',
    name: '溪流路亚竿 1.54m',
    desc: '轻量碳素 · 适合翘嘴',
    note: '短节溪流路亚竿，适合城市河道、浅滩和小型水库搜索。手把轻，长时间抛投更省力。',
    price: 599,
    icon: Icons.phishing_rounded,
    color: InkPalette.pine,
    badge: '热卖',
    delivery: '24h',
    rating: 4.9,
    tags: ['轻量', '翘嘴', '鳜鱼', '路亚'],
    featured: true,
  ),
  _Product(
    id: 'rod-tai-fishing',
    categoryId: 'rod',
    name: '湖库台钓竿 4.5m',
    desc: '腰力稳定 · 新手友好',
    note: '兼顾湖库与野河的入门台钓竿，配重平衡，适合鲫鱼、鲤鱼和综合鱼情。',
    price: 329,
    icon: Icons.phishing_rounded,
    color: InkPalette.pine,
    badge: '入门',
    delivery: '48h',
    rating: 4.7,
    tags: ['台钓', '鲫鱼', '湖库', '新手'],
  ),
  _Product(
    id: 'reel-shallow-3000',
    categoryId: 'reel',
    name: '浅水纺车轮 3000',
    desc: '顺滑泄力 · 防腐蚀',
    note: '轻量纺车轮，泄力顺滑，适合浅水搜索与中小型目标鱼。金属线杯兼容 PE 线。',
    price: 399,
    icon: Icons.adjust_rounded,
    color: InkPalette.lake,
    badge: '推荐',
    delivery: '24h',
    rating: 4.8,
    tags: ['纺车轮', '防腐蚀', '路亚', '浅水'],
    featured: true,
  ),
  _Product(
    id: 'reel-baitcaster-lite',
    categoryId: 'reel',
    name: '微物水滴轮 BFS',
    desc: '轻饵启动 · 磁力刹车',
    note: '适合 2-7g 轻饵抛投，刹车调节直观，帮助进阶玩家拓展微物玩法。',
    price: 529,
    icon: Icons.adjust_rounded,
    color: InkPalette.lake,
    badge: '进阶',
    delivery: '48h',
    rating: 4.7,
    tags: ['微物', '水滴轮', '轻饵', '路亚'],
  ),
  _Product(
    id: 'bait-minnow-95',
    categoryId: 'bait',
    name: '浮水米诺 9.5cm',
    desc: '浅区搜索 · 高反光',
    note: '浮水米诺适合晨昏浅水搜索，慢收有摆动，停顿上浮可避开水草。',
    price: 59,
    icon: Icons.set_meal_rounded,
    color: InkPalette.reed,
    badge: '高频',
    delivery: '24h',
    rating: 4.6,
    tags: ['米诺', '浅区', '翘嘴', '浮水'],
    featured: true,
  ),
  _Product(
    id: 'bait-summer-groundbait',
    categoryId: 'bait',
    name: '夏季腥香窝料',
    desc: '快速聚鱼 · 野钓适配',
    note: '颗粒与粉料混合，适合夏季野河和水库守钓。建议少量多次补窝。',
    price: 39,
    icon: Icons.grain_rounded,
    color: InkPalette.reed,
    badge: '补货',
    delivery: '24h',
    rating: 4.5,
    tags: ['窝料', '鲫鱼', '鲤鱼', '野钓'],
  ),
  _Product(
    id: 'parts-pe-leader',
    categoryId: 'parts',
    name: 'PE线 + 前导套装',
    desc: '8编主线 · 碳素前导',
    note: '主线和前导线一次配齐，适合路亚入门组合。附绑结卡片，减少现场试错。',
    price: 89,
    icon: Icons.cable_rounded,
    color: InkPalette.moss,
    badge: '套装',
    delivery: '24h',
    rating: 4.8,
    tags: ['PE线', '前导', '线组', '配件'],
  ),
  _Product(
    id: 'parts-waterproof-bag',
    categoryId: 'parts',
    name: '防水鱼护包',
    desc: '可折叠 · 易清洗',
    note: '适合短途野钓和城市岸钓，内层防水易冲洗，收纳后不占后备箱空间。',
    price: 129,
    icon: Icons.shopping_bag_rounded,
    color: InkPalette.moss,
    badge: '实用',
    delivery: '48h',
    rating: 4.6,
    tags: ['收纳', '鱼护', '防水', '配件'],
  ),
  _Product(
    id: 'gear-light-box',
    categoryId: 'gear',
    name: '轻量钓箱 26L',
    desc: '坐钓稳定 · 配件位齐',
    note: '26L 轻量钓箱，适合半日出钓。杯架、炮台和伞架接口齐全。',
    price: 299,
    icon: Icons.backpack_rounded,
    color: InkPalette.pine,
    badge: '轻装',
    delivery: '48h',
    rating: 4.7,
    tags: ['钓箱', '收纳', '台钓', '装备'],
  ),
  _Product(
    id: 'gear-sun-rain',
    categoryId: 'gear',
    name: '防晒雨披套装',
    desc: '速干透气 · 防小雨',
    note: '适合夏季岸边长时间等待，帽檐和袖口有防晒设计，小雨也能继续作钓。',
    price: 169,
    icon: Icons.umbrella_rounded,
    color: InkPalette.pine,
    badge: '夏季',
    delivery: '24h',
    rating: 4.5,
    tags: ['防晒', '雨披', '速干', '装备'],
  ),
  _Product(
    id: 'guide-west-lake-morning',
    categoryId: 'guide',
    name: '西湖晨钓向导',
    desc: '3小时带钓 · 路线规划',
    note: '本地向导提供合法水域建议、停车点、岸边路线和基础装备调试。',
    price: 199,
    icon: Icons.map_rounded,
    color: InkPalette.lake,
    badge: '同城',
    delivery: '预约',
    rating: 4.9,
    tags: ['向导', '西湖', '晨钓', '带钓'],
    unit: '/次',
  ),
  _Product(
    id: 'guide-xiang-lake-night',
    categoryId: 'guide',
    name: '湘湖夜钓向导',
    desc: '安全点位 · 夜间提醒',
    note: '夜钓向导侧重安全路线、照明建议和收竿节点，适合新手体验。',
    price: 259,
    icon: Icons.route_rounded,
    color: InkPalette.lake,
    badge: '夜钓',
    delivery: '预约',
    rating: 4.8,
    tags: ['向导', '湘湖', '夜钓', '安全'],
    unit: '/次',
  ),
  _Product(
    id: 'device-finder-rent',
    categoryId: 'device',
    name: '便携探鱼器租赁',
    desc: '免押可用 · 数据清除',
    note: '会员可免押租赁，归还时自动清除个人数据。适合陌生水域快速判断水深和障碍。',
    price: 79,
    icon: Icons.sensors_rounded,
    color: InkPalette.moss,
    badge: '租赁',
    delivery: '预约',
    rating: 4.8,
    tags: ['探鱼器', '租赁', '设备', '水深'],
    unit: '/天',
  ),
  _Product(
    id: 'device-smart-scale',
    categoryId: 'device',
    name: '智能鱼获秤',
    desc: '蓝牙同步 · 自动记录',
    note: '鱼获称重后可同步到钓获记录，适合活动排行、个人统计和复盘。',
    price: 149,
    icon: Icons.scale_rounded,
    color: InkPalette.moss,
    badge: '记录',
    delivery: '24h',
    rating: 4.6,
    tags: ['鱼获', '蓝牙', '设备', '记录'],
  ),
  _Product(
    id: 'service-rod-care',
    categoryId: 'service',
    name: '鱼竿保养服务',
    desc: '清洁上蜡 · 导环检查',
    note: '线槽、导环、竿节和手把统一检查，适合高频使用后的周期保养。',
    price: 49,
    icon: Icons.handyman_rounded,
    color: InkPalette.reed,
    badge: '保养',
    delivery: '到店',
    rating: 4.7,
    tags: ['售后', '鱼竿', '保养', '到店'],
    unit: '/次',
  ),
  _Product(
    id: 'service-reel-care',
    categoryId: 'service',
    name: '鱼轮深度养护',
    desc: '拆洗润滑 · 泄力检测',
    note: '针对纺车轮、水滴轮的轴承、线杯和泄力系统做深度清洁维护。',
    price: 89,
    icon: Icons.support_agent_rounded,
    color: InkPalette.reed,
    badge: '售后',
    delivery: '到店',
    rating: 4.8,
    tags: ['售后', '鱼轮', '清洁', '润滑'],
    unit: '/次',
  ),
];
