import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/ink_app_widgets.dart';
import '../../data/mall_models.dart';

class MallHome extends StatelessWidget {
  const MallHome({
    super.key,
    required this.searchText,
    required this.cartCount,
    required this.favoriteIds,
    required this.cartQuantities,
    required this.categories,
    required this.activeCategoryId,
    required this.smartDevices,
    required this.scenarioPackages,
    required this.memberProducts,
    required this.venueProducts,
    required this.accessoryProducts,
    required this.hotProducts,
    required this.recommendedProducts,
    required this.searchResults,
    required this.checkoutSummary,
    required this.serviceSummary,
    required this.onSearchTap,
    required this.onQuickSearch,
    required this.onCartTap,
    required this.onCategoryTap,
    required this.onBannerTap,
    required this.onProductTap,
    required this.onProductAdd,
    required this.onProductFavorite,
    required this.onScenarioTap,
    required this.onScenarioBuy,
    required this.onMemberTap,
    required this.onAllProductsTap,
  });

  final String searchText;
  final int cartCount;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final List<MallCategoryEntry> categories;
  final String activeCategoryId;
  final List<MallProduct> smartDevices;
  final List<MallScenarioPackage> scenarioPackages;
  final List<MallProduct> memberProducts;
  final List<MallProduct> venueProducts;
  final List<MallProduct> accessoryProducts;
  final List<MallProduct> hotProducts;
  final List<MallProduct> recommendedProducts;
  final List<MallProduct> searchResults;
  final Widget checkoutSummary;
  final Widget serviceSummary;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onQuickSearch;
  final VoidCallback onCartTap;
  final ValueChanged<MallCategoryEntry> onCategoryTap;
  final VoidCallback onBannerTap;
  final ValueChanged<MallProduct> onProductTap;
  final ValueChanged<MallProduct> onProductAdd;
  final ValueChanged<MallProduct> onProductFavorite;
  final ValueChanged<MallScenarioPackage> onScenarioTap;
  final ValueChanged<MallScenarioPackage> onScenarioBuy;
  final VoidCallback onMemberTap;
  final VoidCallback onAllProductsTap;

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchText.trim().isNotEmpty;
    final categoryEntries = categories.take(10).toList(growable: false);
    final hasCategoryFocus =
        categoryEntries.isNotEmpty &&
        activeCategoryId != categoryEntries.first.id;
    final showFocusedProducts = hasSearch || hasCategoryFocus;
    MallCategoryEntry? activeCategory;
    for (final entry in categoryEntries) {
      if (entry.id == activeCategoryId) {
        activeCategory = entry;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 5.h, 18.w, 0),
          child: MallSearchBar(searchText: searchText, onTap: onSearchTap),
        ),
        if (!hasSearch)
          _MallShoppingModeStrip(
            onSceneTap: () => onQuickSearch('夜钓'),
            onProblemTap: () => onQuickSearch('鱼口轻'),
            onDeviceTap: () => onQuickSearch('智能鱼漂'),
            onMemberTap: onMemberTap,
          ),
        if (!hasSearch)
          _MallSolutionGuideSection(
            title: '需求',
            subtitle: '按问题找',
            entries: [
              ..._sceneSolutionEntries.take(2),
              ..._problemSolutionEntries.take(2),
            ],
            onTap: onQuickSearch,
          ),
        if (showFocusedProducts && hasSearch)
          ProductSection(
            title: '搜索结果',
            subtitle: '匹配 $searchText',
            products: searchResults,
            compact: true,
            emptyText: '当前没有匹配商品，试试智能鱼漂、夜钓或钓场套餐',
            favoriteIds: favoriteIds,
            cartQuantities: cartQuantities,
            onProductTap: onProductTap,
            onProductAdd: onProductAdd,
            onProductFavorite: onProductFavorite,
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, hasSearch ? 8.h : 12.h, 18.w, 0),
          child: MallBanner(
            cartCount: cartCount,
            onTap: onBannerTap,
            onCartTap: onCartTap,
          ),
        ),
        MallCategoryGrid(
          categories: categoryEntries,
          activeCategoryId: activeCategoryId,
          onTap: onCategoryTap,
        ),
        if (showFocusedProducts && !hasSearch)
          ProductSection(
            title: '${activeCategory?.label ?? '分类'}专区',
            subtitle: activeCategory?.subtitle ?? '按分类查看商城商品',
            products: searchResults,
            emptyText: '当前没有匹配商品，试试智能鱼漂、夜钓或钓场套餐',
            favoriteIds: favoriteIds,
            cartQuantities: cartQuantities,
            onProductTap: onProductTap,
            onProductAdd: onProductAdd,
            onProductFavorite: onProductFavorite,
          ),
        SmartDeviceSection(
          products: smartDevices,
          favoriteIds: favoriteIds,
          cartQuantities: cartQuantities,
          onProductTap: onProductTap,
          onProductAdd: onProductAdd,
          onProductFavorite: onProductFavorite,
          onAll: onAllProductsTap,
        ),
        ScenarioPackageSection(
          packages: scenarioPackages,
          onPackageTap: onScenarioTap,
          onPackageBuy: onScenarioBuy,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
          child: checkoutSummary,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
          child: serviceSummary,
        ),
      ],
    );
  }
}

class MallSearchBar extends StatelessWidget {
  const MallSearchBar({
    super.key,
    required this.searchText,
    required this.onTap,
  });

  final String searchText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkSearchBox(
      hint: searchText.trim().isEmpty ? '搜索智能鱼漂、夜钓套装、钓箱配件' : '搜索：$searchText',
      onTap: onTap,
    );
  }
}

const _sceneSolutionEntries = [
  _MallSolutionEntry(
    icon: Icons.school_rounded,
    title: '新手入门',
    subtitle: '少踩坑，先配齐基础套装',
    query: '新手入门',
    color: InkPalette.pine,
  ),
  _MallSolutionEntry(
    icon: Icons.nights_stay_rounded,
    title: '夜钓',
    subtitle: '照明、安全和轻口提醒',
    query: '夜钓',
    color: InkPalette.moss,
  ),
  _MallSolutionEntry(
    icon: Icons.set_meal_rounded,
    title: '路亚',
    subtitle: '快搜、找层、陌生水域',
    query: '路亚',
    color: InkPalette.lake,
  ),
  _MallSolutionEntry(
    icon: Icons.sports_score_rounded,
    title: '黑坑',
    subtitle: '抢口、钓箱和线组补给',
    query: '黑坑',
    color: InkPalette.reed,
  ),
  _MallSolutionEntry(
    icon: Icons.terrain_rounded,
    title: '野钓',
    subtitle: '安全、续航和轻量装备',
    query: '野钓',
    color: InkPalette.pine,
  ),
];

const _problemSolutionEntries = [
  _MallSolutionEntry(
    icon: Icons.visibility_rounded,
    title: '看不清漂',
    subtitle: '智能鱼漂和夜间提醒',
    query: '智能鱼漂',
    color: InkPalette.lake,
  ),
  _MallSolutionEntry(
    icon: Icons.lightbulb_rounded,
    title: '夜钓找位',
    subtitle: '夜钓灯、头灯和安全定位',
    query: '夜钓灯',
    color: InkPalette.moss,
  ),
  _MallSolutionEntry(
    icon: Icons.battery_charging_full_rounded,
    title: '设备没电',
    subtitle: '电池仓、充电和配件',
    query: '电池',
    color: InkPalette.reed,
  ),
  _MallSolutionEntry(
    icon: Icons.edit_note_rounded,
    title: '想记录鱼获',
    subtitle: '自动报告和设备联动',
    query: '作钓报告',
    color: InkPalette.pine,
  ),
];

class _MallSolutionEntry {
  const _MallSolutionEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.query,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String query;
  final Color color;
}

class _MallShoppingModeStrip extends StatelessWidget {
  const _MallShoppingModeStrip({
    required this.onSceneTap,
    required this.onProblemTap,
    required this.onDeviceTap,
    required this.onMemberTap,
  });

  final VoidCallback onSceneTap;
  final VoidCallback onProblemTap;
  final VoidCallback onDeviceTap;
  final VoidCallback onMemberTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MallModeItem(
        icon: Icons.explore_rounded,
        title: '按场景买',
        subtitle: '夜钓/野钓',
        color: InkPalette.pine,
        onTap: onSceneTap,
      ),
      _MallModeItem(
        icon: Icons.tips_and_updates_rounded,
        title: '按问题买',
        subtitle: '鱼口/风浪',
        color: InkPalette.lake,
        onTap: onProblemTap,
      ),
      _MallModeItem(
        icon: Icons.sensors_rounded,
        title: '智能设备',
        subtitle: '鱼漂/探鱼',
        color: InkPalette.moss,
        onTap: onDeviceTap,
      ),
      _MallModeItem(
        icon: Icons.workspace_premium_rounded,
        title: '会员权益',
        subtitle: '券/延保',
        color: InkPalette.reed,
        onTap: onMemberTap,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
      child: InkGlassCard(
        padding: EdgeInsets.all(10.r),
        child: Column(
          children: [
            Row(
              children: [
                const InkCommercialVisual(
                  kind: InkVisualTileKind.mall,
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
                        '补给',
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '场景 / 问题 / 设备 / 权益',
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
              ],
            ),
            SizedBox(height: 10.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 520 ? 2 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: constraints.maxWidth < 520 ? 1.24 : 1.36,
                  ),
                  itemBuilder: (context, index) => InkEntrance(
                    delay: Duration(milliseconds: 35 * index),
                    offset: 6,
                    child: _MallModeTile(item: items[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MallModeTile extends StatelessWidget {
  const _MallModeTile({required this.item});

  final _MallModeItem item;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: 72.h),
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
                fontSize: 11.5.sp,
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
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MallModeItem {
  const _MallModeItem({
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

class _MallSolutionGuideSection extends StatelessWidget {
  const _MallSolutionGuideSection({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<_MallSolutionEntry> entries;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(title: title, subtitle: subtitle),
        SizedBox(
          height: 106.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _MallSolutionCard(
                entry: entry,
                onTap: () => onTap(entry.query),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MallSolutionCard extends StatelessWidget {
  const _MallSolutionCard({required this.entry, required this.onTap});

  final _MallSolutionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156.w,
      child: InkCard(
        padding: EdgeInsets.all(10.r),
        borderColor: entry.color.withValues(alpha: 0.16),
        color: entry.color.withValues(alpha: 0.07),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkIconMark(
                  icon: entry.icon,
                  color: entry.color,
                  size: 30,
                  iconSize: 15,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: entry.color,
                  size: 18.w,
                ),
              ],
            ),
            const Spacer(),
            Text(
              entry.title,
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
              entry.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 11.sp,
                height: 1.22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MallBanner extends StatelessWidget {
  const MallBanner({
    super.key,
    required this.cartCount,
    required this.onTap,
    required this.onCartTap,
  });

  final int cartCount;
  final VoidCallback onTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 138.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: InkPalette.ink,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: InkPalette.lake.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: InkPalette.ink.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: Offset(0, 9.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniPill(
                    label: '智能装备生态',
                    icon: Icons.settings_input_antenna_rounded,
                    color: InkPalette.lake,
                    dark: true,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '智能鱼漂 Pro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: 21.sp,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '漂相识别、咬口提醒、夜钓联动，搭配 Pro 会员价更划算。',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.white.withValues(alpha: 0.76),
                      fontSize: 11.5.sp,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _BannerMetric(value: '¥359', label: '会员价'),
                      SizedBox(width: 8.w),
                      _BannerMetric(value: '4.9', label: '评分'),
                      SizedBox(width: 8.w),
                      InkPressable(
                        onTap: onCartTap,
                        child: Container(
                          constraints: BoxConstraints(minHeight: 32.h),
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: InkPalette.reed,
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cartCount == 0 ? '查看购物车' : '购物车 $cartCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const InkCommercialVisual(
                  kind: InkVisualTileKind.mall,
                  width: 88,
                  height: 88,
                  radius: 20,
                  borderColor: Colors.transparent,
                ),
                SizedBox(height: 6.h),
                _MiniPill(
                  label: '夜钓套装',
                  icon: Icons.nights_stay_rounded,
                  color: InkPalette.reed,
                  dark: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MallCategoryGrid extends StatelessWidget {
  const MallCategoryGrid({
    super.key,
    required this.categories,
    required this.activeCategoryId,
    required this.onTap,
  });

  final List<MallCategoryEntry> categories;
  final String activeCategoryId;
  final ValueChanged<MallCategoryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InkSectionHeader(title: '商品分类', subtitle: '设备、场景、配件和会员权益'),
        SizedBox(
          height: 126.h,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.w,
              crossAxisSpacing: 8.h,
              childAspectRatio: 0.56,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final active = category.id == activeCategoryId;
              return _CategoryEntryTile(
                entry: category,
                active: active,
                onTap: () => onTap(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SmartDeviceSection extends StatelessWidget {
  const SmartDeviceSection({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.cartQuantities,
    required this.onProductTap,
    required this.onProductAdd,
    required this.onProductFavorite,
    required this.onAll,
  });

  final List<MallProduct> products;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final ValueChanged<MallProduct> onProductTap;
  final ValueChanged<MallProduct> onProductAdd;
  final ValueChanged<MallProduct> onProductFavorite;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(
          title: '智能设备专区',
          subtitle: 'App 绑定、作钓模式和设备联动是核心能力',
          action: '全部',
          onAction: onAll,
        ),
        if (products.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: const _InlineEmpty(text: '暂无智能设备，稍后再来看看。'),
          )
        else
          SizedBox(
            height: 318.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final product = products[index];
                return SmartDeviceCard(
                  product: product,
                  quantity: cartQuantities[product.id] ?? 0,
                  favorite: favoriteIds.contains(product.id),
                  onTap: () => onProductTap(product),
                  onAdd: () => onProductAdd(product),
                  onFavorite: () => onProductFavorite(product),
                );
              },
            ),
          ),
      ],
    );
  }
}

class SmartDeviceCard extends StatelessWidget {
  const SmartDeviceCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.favorite,
    required this.onTap,
    required this.onAdd,
    required this.onFavorite,
  });

  final MallProduct product;
  final int quantity;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return SizedBox(
      width: 270.w,
      child: InkCard(
        padding: EdgeInsets.all(10.r),
        onTap: onTap,
        borderColor: color.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82.w,
                  height: 82.h,
                  child: _ProductVisual(product: product),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.text,
                                fontSize: 15.sp,
                                height: 1.14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _CircleIconButton(
                            icon: favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favorite
                                ? InkPalette.cinnabar
                                : InkPalette.muted,
                            onTap: onFavorite,
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        product.scene,
                        maxLines: 1,
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
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '核心能力',
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final feature in product.features.take(3))
                  _MiniPill(label: feature, color: color),
              ],
            ),
            SizedBox(height: 7.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _DeviceSupportChip(
                  label: 'App绑定',
                  enabled: product.supportDeviceLink,
                ),
                _DeviceSupportChip(
                  label: '作钓模式',
                  enabled: _supportsFishingMode(product),
                ),
                _DeviceSupportChip(
                  label: '设备联动',
                  enabled: _supportsDeviceInterlock(product),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _PriceText(
                    price: product.price,
                    memberPrice: product.memberPrice,
                  ),
                ),
                Text(
                  '销量 ${product.sales}',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            Row(
              children: [
                Expanded(
                  child: _DevicePrimaryButton(
                    label: '查看详情',
                    icon: Icons.article_rounded,
                    color: color,
                    onTap: onTap,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _DeviceSecondaryButton(
                    label: quantity == 0 ? '加入购物车' : '已加 $quantity',
                    icon: Icons.add_shopping_cart_rounded,
                    color: color,
                    onTap: onAdd,
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

class ScenarioPackageSection extends StatelessWidget {
  const ScenarioPackageSection({
    super.key,
    required this.packages,
    required this.onPackageTap,
    required this.onPackageBuy,
  });

  final List<MallScenarioPackage> packages;
  final ValueChanged<MallScenarioPackage> onPackageTap;
  final ValueChanged<MallScenarioPackage> onPackageBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InkSectionHeader(title: '场景套餐', subtitle: '按作钓场景配齐设备、补给和服务'),
        SizedBox(
          height: 306.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: packages.length,
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final package = packages[index];
              return ScenarioPackageCard(
                package: package,
                onTap: () => onPackageTap(package),
                onBuy: () => onPackageBuy(package),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MemberDealSection extends StatelessWidget {
  const MemberDealSection({
    super.key,
    required this.products,
    required this.onTap,
    required this.onProductTap,
    required this.onProductAdd,
  });

  final List<MallProduct> products;
  final VoidCallback onTap;
  final ValueChanged<MallProduct> onProductTap;
  final ValueChanged<MallProduct> onProductAdd;

  @override
  Widget build(BuildContext context) {
    final product = products.isEmpty ? null : products.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InkSectionHeader(title: '会员专享优惠', subtitle: 'Pro 权益、设备延保和商城会员价'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: InkPressable(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(15.r),
              decoration: BoxDecoration(
                color: InkPalette.ink.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: InkPalette.reed.withValues(alpha: 0.46),
                ),
              ),
              child: Row(
                children: [
                  const InkCommercialVisual(
                    kind: InkVisualTileKind.achievement,
                    width: 86,
                    height: 96,
                    radius: 20,
                    borderColor: Colors.transparent,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.name ?? '江湖钓客 Pro',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '高级报告 · 多设备绑定 · 90 天历史数据 · 商城会员价',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.white.withValues(alpha: 0.76),
                            fontSize: 12.sp,
                            height: 1.36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            _PriceText(
                              price: product?.price ?? 198,
                              memberPrice: product?.memberPrice ?? 198,
                              dark: true,
                            ),
                            const Spacer(),
                            if (product != null)
                              _SmallActionButton(
                                label: '加入',
                                icon: Icons.add_shopping_cart_rounded,
                                color: InkPalette.reed,
                                onTap: () => onProductAdd(product),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductSection extends StatelessWidget {
  const ProductSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.favoriteIds,
    required this.cartQuantities,
    required this.onProductTap,
    required this.onProductAdd,
    required this.onProductFavorite,
    this.action,
    this.onAction,
    this.emptyText = '暂无商品',
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  final List<MallProduct> products;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final ValueChanged<MallProduct> onProductTap;
  final ValueChanged<MallProduct> onProductAdd;
  final ValueChanged<MallProduct> onProductFavorite;
  final String emptyText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkSectionHeader(
          title: title,
          subtitle: subtitle,
          action: action,
          onAction: onAction,
        ),
        if (products.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: _InlineEmpty(text: emptyText),
          )
        else
          _HorizontalProducts(
            products: products,
            compact: compact,
            favoriteIds: favoriteIds,
            cartQuantities: cartQuantities,
            onProductTap: onProductTap,
            onProductAdd: onProductAdd,
            onProductFavorite: onProductFavorite,
          ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.favorite,
    required this.onTap,
    required this.onAdd,
    required this.onFavorite,
    this.width = 178,
    this.compact = false,
  });

  final MallProduct product;
  final int quantity;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(product.category);
    final sceneChips = product.recommendedFor.isEmpty
        ? product.tags
        : product.recommendedFor;
    final chips = <String>[
      ...sceneChips.take(2),
      if (product.supportDeviceLink) 'App联动',
    ];
    final imageHeight = compact ? 68.h : 82.h;
    final chipAreaHeight = compact ? 24.h : 34.h;
    final chipLimit = compact ? 2 : 3;

    return SizedBox(
      width: width.w,
      child: InkCard(
        padding: EdgeInsets.all(compact ? 9.r : 11.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: _ProductVisual(product: product)),
                  Positioned(
                    left: 6.w,
                    top: 6.h,
                    child: _MiniPill(
                      label: product.badge.isEmpty
                          ? product.category.label
                          : product.badge,
                      color: accent,
                    ),
                  ),
                  if (product.isSmartDevice)
                    Positioned(
                      left: 6.w,
                      bottom: 6.h,
                      child: _MiniPill(
                        label: '智能',
                        icon: Icons.settings_input_antenna_rounded,
                        color: InkPalette.lake,
                      ),
                    ),
                  if (quantity > 0)
                    Positioned(
                      right: 6.w,
                      bottom: 6.h,
                      child: _MiniPill(
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
                          color: InkPalette.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? InkPalette.cinnabar
                              : InkPalette.muted,
                          size: 16.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 5.h : 7.h),
            Text(
              product.name,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: compact ? 12.sp : 12.5.sp,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 3.h : 4.h),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent, size: 13.w),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    product.scene,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.muted,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 4.h : 5.h),
            SizedBox(
              height: chipAreaHeight,
              child: Wrap(
                spacing: 5.w,
                runSpacing: 4.h,
                children: [
                  for (final chip in chips.take(chipLimit))
                    _MiniPill(label: chip, color: accent),
                ],
              ),
            ),
            SizedBox(height: compact ? 5.h : 6.h),
            Row(
              children: [
                Expanded(
                  child: _PriceText(
                    price: product.price,
                    memberPrice: product.memberPrice,
                  ),
                ),
                _CircleAddButton(onTap: onAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioPackageCard extends StatelessWidget {
  const ScenarioPackageCard({
    super.key,
    required this.package,
    required this.onTap,
    required this.onBuy,
  });

  final MallScenarioPackage package;
  final VoidCallback onTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final color = _scenarioColor(package);
    final totalItems = package.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return SizedBox(
      width: 286.w,
      child: InkCard(
        padding: EdgeInsets.all(13.r),
        onTap: onTap,
        borderColor: color.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const InkCommercialVisual(
                  kind: InkVisualTileKind.spot,
                  width: 76,
                  height: 76,
                  radius: 18,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniPill(
                        label: package.tags.isEmpty
                            ? package.scene
                            : package.tags.first,
                        icon: Icons.auto_awesome_rounded,
                        color: color,
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        package.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        package.scene,
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
              ],
            ),
            SizedBox(height: 11.h),
            Row(
              children: [
                _PackageMetric(
                  label: '包含',
                  value: '${package.items.length}类 / $totalItems件',
                  color: color,
                ),
                SizedBox(width: 8.w),
                _PackageMetric(
                  label: '适合',
                  value: package.suitableFor.take(2).join('、'),
                  color: InkPalette.moss,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              package.mainBenefit,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 12.sp,
                height: 1.32,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 9.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final tag in package.tags.take(3))
                  _MiniPill(label: tag, color: color),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _PackagePriceStack(
                  originalPrice: package.originalPrice,
                  packagePrice: package.packagePrice,
                  memberPrice: package.memberPrice,
                ),
                const Spacer(),
                _SavingBadge(amount: package.savingAmount),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _DevicePrimaryButton(
                    label: '查看套餐',
                    icon: Icons.article_rounded,
                    color: color,
                    onTap: onTap,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _DeviceSecondaryButton(
                    label: '立即购买',
                    icon: Icons.flash_on_rounded,
                    color: color,
                    onTap: onBuy,
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

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({
    required this.products,
    required this.favoriteIds,
    required this.cartQuantities,
    required this.onProductTap,
    required this.onProductAdd,
    required this.onProductFavorite,
    this.compact = false,
  });

  final List<MallProduct> products;
  final Set<String> favoriteIds;
  final Map<String, int> cartQuantities;
  final ValueChanged<MallProduct> onProductTap;
  final ValueChanged<MallProduct> onProductAdd;
  final ValueChanged<MallProduct> onProductFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 210.h : 248.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            compact: compact,
            width: compact ? 154 : 178,
            quantity: cartQuantities[product.id] ?? 0,
            favorite: favoriteIds.contains(product.id),
            onTap: () => onProductTap(product),
            onAdd: () => onProductAdd(product),
            onFavorite: () => onProductFavorite(product),
          );
        },
      ),
    );
  }
}

class _CategoryEntryTile extends StatelessWidget {
  const _CategoryEntryTile({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final MallCategoryEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(entry.category);

    return InkPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: active ? color : InkPalette.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: active ? color : InkPalette.line.withValues(alpha: 0.86),
          ),
          boxShadow: active ? [AppShadows.cardShadow] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: active
                    ? InkPalette.white.withValues(alpha: 0.16)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _categoryIcon(entry.category),
                color: active ? InkPalette.white : color,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? InkPalette.white : InkPalette.text,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? InkPalette.white.withValues(alpha: 0.76)
                          : InkPalette.muted,
                      fontSize: 10.5.sp,
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

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final MallProduct product;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
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
                  InkPalette.ink.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: InkPalette.white.withValues(alpha: 0.86),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(product.category),
                color: color,
                size: 28.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.price,
    required this.memberPrice,
    this.dark = false,
  });

  final int price;
  final int memberPrice;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? InkPalette.reed : InkPalette.cinnabar;
    final secondary = dark
        ? InkPalette.white.withValues(alpha: 0.64)
        : InkPalette.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¥$memberPrice',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primary,
            fontSize: 17.sp,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          '原价 ¥$price',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: secondary,
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w800,
            decoration: memberPrice < price ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}

class _PackageMetric extends StatelessWidget {
  const _PackageMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: 43.h),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            SizedBox(height: 3.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackagePriceStack extends StatelessWidget {
  const _PackagePriceStack({
    required this.originalPrice,
    required this.packagePrice,
    required this.memberPrice,
  });

  final int originalPrice;
  final int packagePrice;
  final int memberPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '会员 ¥$memberPrice',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: InkPalette.cinnabar,
            fontSize: 17.sp,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '套餐 ¥$packagePrice',
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '原价 ¥$originalPrice',
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 10.5.sp,
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

class _SavingBadge extends StatelessWidget {
  const _SavingBadge({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 32.h, maxWidth: 86.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: InkPalette.cinnabar.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: InkPalette.cinnabar.withValues(alpha: 0.18)),
      ),
      child: Text(
        '省 ¥$amount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: InkPalette.cinnabar,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 54.w, minHeight: 36.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.reed,
              fontSize: 13.sp,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              color: InkPalette.white.withValues(alpha: 0.78),
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
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
      constraints: BoxConstraints(maxWidth: 132.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: dark
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
                color: dark ? InkPalette.white : color,
                fontSize: 10.5.sp,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSupportChip extends StatelessWidget {
  const _DeviceSupportChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? InkPalette.moss : InkPalette.muted;
    return Container(
      constraints: BoxConstraints(maxWidth: 92.w, minHeight: 25.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: enabled ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            color: color,
            size: 12.w,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePrimaryButton extends StatelessWidget {
  const _DevicePrimaryButton({
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
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13.r),
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

class _DeviceSecondaryButton extends StatelessWidget {
  const _DeviceSecondaryButton({
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13.r),
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

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
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
        constraints: BoxConstraints(minHeight: 36.h, maxWidth: 88.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: InkPalette.white, size: 15.w),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 11.5.sp,
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

class _CircleAddButton extends StatelessWidget {
  const _CircleAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      icon: Icons.add_shopping_cart_rounded,
      color: InkPalette.pine,
      onTap: onTap,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: color, size: 18.w),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          const InkIconMark(
            icon: Icons.search_off_rounded,
            color: InkPalette.lake,
            size: 38,
            iconSize: 19,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: InkPalette.muted,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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

Color _scenarioColor(MallScenarioPackage package) {
  final text = '${package.name}${package.scene}${package.tags.join()}';
  if (text.contains('夜')) return InkPalette.lake;
  if (text.contains('野')) return InkPalette.moss;
  if (text.contains('黑坑')) return InkPalette.reed;
  if (text.contains('竞技')) return InkPalette.pine;
  if (text.contains('会员')) return InkPalette.reed;
  if (text.contains('智能')) return InkPalette.lake;
  if (text.contains('专业')) return InkPalette.pine;
  return InkPalette.moss;
}

bool _supportsFishingMode(MallProduct product) {
  switch (product.category) {
    case MallProductCategory.smartFloat:
    case MallProductCategory.smartTackleBox:
    case MallProductCategory.smartPlatform:
    case MallProductCategory.smartUmbrella:
    case MallProductCategory.fishFinder:
    case MallProductCategory.nightLight:
      return true;
    case MallProductCategory.smartDevice:
    case MallProductCategory.sensor:
    case MallProductCategory.oxygen:
      return product.features.any((feature) => feature.contains('作钓'));
    case MallProductCategory.bait:
    case MallProductCategory.rod:
    case MallProductCategory.fishingLine:
    case MallProductCategory.accessory:
    case MallProductCategory.membership:
    case MallProductCategory.fishingVenue:
      return false;
  }
}

bool _supportsDeviceInterlock(MallProduct product) {
  if (product.category == MallProductCategory.smartFloat ||
      product.category == MallProductCategory.smartTackleBox ||
      product.category == MallProductCategory.smartUmbrella ||
      product.category == MallProductCategory.nightLight) {
    return true;
  }
  return product.deviceCompatible.length > 1;
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
