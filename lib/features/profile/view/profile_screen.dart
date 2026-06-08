import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/data/auth_repository.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(currentUserProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final stats = ref
        .watch(userStatsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

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
              title: '我的',
              subtitle: '个人空间 · 数据沉淀 · 服务管理',
              actions: [
                InkRoundButton(
                  icon: Icons.settings_outlined,
                  onTap: () => context.push(AppRouteNames.settings),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
              child: _ProfileHero(
                name: user?.nickname ?? '江湖钓客',
                phone: user?.phone ?? '13800000000',
                level: user?.levelTag ?? 'Lv.23',
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: InkMetric(
                      value: '${stats?.totalFish ?? 256}',
                      label: '钓获记录',
                      icon: Icons.set_meal_rounded,
                      color: InkPalette.pine,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: InkMetric(
                      value: '${stats?.spotsExplored ?? 68}',
                      label: '探索钓点',
                      icon: Icons.place_rounded,
                      color: InkPalette.lake,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: InkMetric(
                      value: '${stats?.daysActive ?? 128}',
                      label: '活跃天数',
                      icon: Icons.calendar_month_rounded,
                      color: InkPalette.moss,
                    ),
                  ),
                ],
              ),
            ),
            const InkSectionHeader(title: '我的记录', subtitle: '出钓、渔获、收藏与挑战'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: _RecordGrid(),
            ),
            const InkSectionHeader(title: '江湖成就', subtitle: '称号、勋章、图鉴和挑战进度'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: const _ProfileAchievementPanel(),
            ),
            const InkSectionHeader(title: '我的卡片', subtitle: '可同步到首页的信息模块'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: _HomeCards(),
            ),
            const InkSectionHeader(title: '装备与服务', subtitle: '设备绑定、订单和售后'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  InkCard(
                    onTap: () => _showProfileDeviceSheet(context),
                    child: InkInfoRow(
                      icon: Icons.sensors_rounded,
                      title: '智能浮漂 FC-01',
                      subtitle: '已连接 1 台 · 电量 78%',
                      trailing: '管理',
                      color: InkPalette.pine,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  InkCard(
                    onTap: () => context.push(AppRouteNames.mall),
                    child: const InkInfoRow(
                      icon: Icons.receipt_long_rounded,
                      title: '服务订单',
                      subtitle: '待付款 1 · 待发货 2 · 售后 0',
                      trailing: '查看',
                      color: InkPalette.lake,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  InkPrimaryButton(
                    label: '退出登录',
                    icon: Icons.logout_rounded,
                    color: InkPalette.cinnabar,
                    onTap: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (context.mounted) context.go(AppRouteNames.login);
                    },
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.phone,
    required this.level,
  });

  final String name;
  final String phone;
  final String level;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: () => _showProfilePassportSheet(context, name, level),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: SizedBox(
          height: 214.h,
          child: Stack(
            children: [
              const Positioned.fill(
                child: InkLandscapeHero(height: 214, bright: false),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        InkPalette.ink.withValues(alpha: 0.08),
                        InkPalette.ink.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16.w,
                top: 15.h,
                right: 16.w,
                child: Row(
                  children: [
                    Container(
                      width: 70.w,
                      height: 70.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: InkPalette.paper,
                        border: Border.all(
                          color: InkPalette.white.withValues(alpha: 0.86),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: InkPalette.ink.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: InkPalette.pine,
                        size: 40.w,
                      ),
                    ),
                    SizedBox(width: 13.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: InkPalette.white,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    fontFamilyFallback: brushFontFallback,
                                  ),
                                ),
                              ),
                              InkChip(
                                label: level,
                                active: true,
                                color: InkPalette.reed,
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '江湖护照 · ID $phone',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: InkPalette.white.withValues(alpha: 0.90),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: [
                              _HeroHonorChip(
                                icon: Icons.workspace_premium_rounded,
                                label: '雨后巡水者',
                                color: InkPalette.reed,
                              ),
                              _HeroHonorChip(
                                icon: Icons.verified_rounded,
                                label: '信用 92',
                                color: InkPalette.moss,
                              ),
                            ],
                          ),
                          SizedBox(height: 9.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: 0.72,
                              minHeight: 7.h,
                              color: InkPalette.reed,
                              backgroundColor: InkPalette.white.withValues(
                                alpha: 0.22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    const InkSeal(text: '江\n湖'),
                  ],
                ),
              ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Row(
                  children: const [
                    Expanded(
                      child: _PassportStat(value: '8', label: '称号'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _PassportStat(value: '12', label: '徽章'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _PassportStat(value: '36', label: '图鉴'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHonorChip extends StatelessWidget {
  const _HeroHonorChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: InkPalette.white, size: 13.w),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: InkPalette.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportStat extends StatelessWidget {
  const _PassportStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: InkPalette.white,
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

class _RecordGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _records.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 8.w,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final item = _records[index];
          return InkActionTile(
            icon: item.$1,
            label: item.$2,
            color: item.$3,
            onTap: () => _showRecordSheet(context, item.$2, item.$1, item.$3),
          );
        },
      ),
    );
  }
}

class _ProfileAchievementPanel extends StatelessWidget {
  const _ProfileAchievementPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkCard(
          onTap: () => _showHonorTitleSheet(context),
          padding: EdgeInsets.all(13.r),
          child: Column(
            children: [
              const InkInfoRow(
                icon: Icons.workspace_premium_rounded,
                title: '当前称号 · 雨后巡水者',
                subtitle: '雨后出钓命中率高于 70%，已佩戴在个人主页',
                trailing: '更换',
                color: InkPalette.reed,
              ),
              SizedBox(height: 12.h),
              Row(
                children: const [
                  Expanded(
                    child: InkMetric(
                      value: '8/24',
                      label: '称号收集',
                      icon: Icons.military_tech_rounded,
                      color: InkPalette.reed,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkMetric(
                      value: '72%',
                      label: '护照进度',
                      icon: Icons.verified_user_rounded,
                      color: InkPalette.moss,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        InkCard(
          onTap: () => _showBadgeWallSheet(context),
          padding: EdgeInsets.all(13.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InkInfoRow(
                icon: Icons.emoji_events_rounded,
                title: '勋章墙',
                subtitle: '本月新增 3 枚，优先展示稀有和近期获得',
                trailing: '12枚',
                color: InkPalette.pine,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  for (var i = 0; i < _honorBadges.take(4).length; i++) ...[
                    Expanded(child: _BadgeMedallion(badge: _honorBadges[i])),
                    if (i != 3) SizedBox(width: 8.w),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        InkCard(
          onTap: () => _showFishAtlasSheet(context),
          padding: EdgeInsets.all(13.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InkInfoRow(
                icon: Icons.menu_book_rounded,
                title: '鱼种图鉴',
                subtitle: '记录鱼种、季节、水域、钓法和最大尺寸',
                trailing: '36/128',
                color: InkPalette.lake,
              ),
              SizedBox(height: 12.h),
              for (var i = 0; i < _fishAtlasPreview.length; i++) ...[
                _FishAtlasRow(item: _fishAtlasPreview[i]),
                if (i != _fishAtlasPreview.length - 1) SizedBox(height: 8.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({required this.badge});

  final _HonorBadge badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                badge.color.withValues(alpha: 0.26),
                badge.color.withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(color: badge.color.withValues(alpha: 0.42)),
          ),
          child: Icon(badge.icon, color: badge.color, size: 24.w),
        ),
        SizedBox(height: 6.h),
        Text(
          badge.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: InkPalette.text,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FishAtlasRow extends StatelessWidget {
  const _FishAtlasRow({required this.item});

  final _FishAtlasItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          InkIconMark(icon: item.icon, color: item.color, size: 34),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.meta,
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
          InkChip(label: item.level, active: true, color: item.color),
        ],
      ),
    );
  }
}

class _HomeCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkCard(
      onTap: () => _showHomeCardSheet(context),
      child: Column(
        children: const [
          InkInfoRow(
            icon: Icons.dashboard_customize_rounded,
            title: '首页卡片布局',
            subtitle: '天气、鱼情、钓点、设备、订单已启用',
            trailing: '已显示 6/8',
            color: InkPalette.pine,
          ),
          SizedBox(height: 12),
          InkInfoRow(
            icon: Icons.auto_graph_rounded,
            title: '个人鱼情模型',
            subtitle: '结合你的渔获、玩法和设备数据优化建议',
            trailing: '训练中',
            color: InkPalette.moss,
          ),
        ],
      ),
    );
  }
}

const _records = [
  (Icons.menu_book_rounded, '钓鱼记录', InkPalette.pine),
  (Icons.set_meal_rounded, '渔获记录', InkPalette.lake),
  (Icons.emoji_events_rounded, '低概率挑战', InkPalette.reed),
  (Icons.place_rounded, '收藏钓点', InkPalette.moss),
];

class _HonorTitle {
  const _HonorTitle({
    required this.name,
    required this.condition,
    required this.progress,
    required this.color,
  });

  final String name;
  final String condition;
  final String progress;
  final Color color;
}

class _HonorBadge {
  const _HonorBadge({
    required this.icon,
    required this.name,
    required this.desc,
    required this.color,
  });

  final IconData icon;
  final String name;
  final String desc;
  final Color color;
}

class _FishAtlasItem {
  const _FishAtlasItem({
    required this.icon,
    required this.name,
    required this.meta,
    required this.level,
    required this.color,
  });

  final IconData icon;
  final String name;
  final String meta;
  final String level;
  final Color color;
}

const _honorTitles = [
  _HonorTitle(
    name: '雨后巡水者',
    condition: '雨后 24 小时内完成 12 次有效出钓，命中率高于 70%',
    progress: '已佩戴',
    color: InkPalette.reed,
  ),
  _HonorTitle(
    name: '夜钓守灯人',
    condition: '夜间出钓 10 次且安全提醒全部确认',
    progress: '8/10',
    color: InkPalette.lake,
  ),
  _HonorTitle(
    name: '草边细作',
    condition: '草边水域鲫鱼/鲤鱼记录累计 30 条',
    progress: '24/30',
    color: InkPalette.moss,
  ),
];

const _honorBadges = [
  _HonorBadge(
    icon: Icons.water_drop_rounded,
    name: '识水',
    desc: '连续 7 次记录水色和鱼口反馈',
    color: InkPalette.lake,
  ),
  _HonorBadge(
    icon: Icons.workspace_premium_rounded,
    name: '首鳜',
    desc: '首次解锁鳜鱼图鉴',
    color: InkPalette.reed,
  ),
  _HonorBadge(
    icon: Icons.nights_stay_rounded,
    name: '守夜',
    desc: '完成 5 次安全夜钓记录',
    color: InkPalette.pine,
  ),
  _HonorBadge(
    icon: Icons.volunteer_activism_rounded,
    name: '互助',
    desc: '帮助 8 位钓友完成钓点判断',
    color: InkPalette.moss,
  ),
  _HonorBadge(
    icon: Icons.auto_graph_rounded,
    name: '复盘',
    desc: '连续 14 天补全鱼获复盘',
    color: InkPalette.cinnabar,
  ),
];

const _fishAtlasPreview = [
  _FishAtlasItem(
    icon: Icons.set_meal_rounded,
    name: '鳜鱼',
    meta: '最大 42cm · 雨后回水湾 · 亮片慢收',
    level: '稀有',
    color: InkPalette.reed,
  ),
  _FishAtlasItem(
    icon: Icons.set_meal_rounded,
    name: '翘嘴',
    meta: '最大 58cm · 清晨浅滩 · 米诺搜索',
    level: '常见',
    color: InkPalette.lake,
  ),
  _FishAtlasItem(
    icon: Icons.set_meal_rounded,
    name: '鲫鱼',
    meta: '最大 0.9斤 · 夜间灯影 · 腥饵守底',
    level: '稳定',
    color: InkPalette.moss,
  ),
];

void _showHonorTitleSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '我的称号',
    subtitle: '称号会显示在个人主页、社区动态和鱼获卡片上',
    icon: Icons.military_tech_rounded,
    color: InkPalette.reed,
    children: [
      for (var i = 0; i < _honorTitles.length; i++) ...[
        InkCard(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          color: _honorTitles[i].color.withValues(alpha: 0.10),
          borderColor: _honorTitles[i].color.withValues(alpha: 0.22),
          child: InkInfoRow(
            icon: Icons.workspace_premium_rounded,
            title: _honorTitles[i].name,
            subtitle: _honorTitles[i].condition,
            trailing: _honorTitles[i].progress,
            color: _honorTitles[i].color,
          ),
        ),
        if (i != _honorTitles.length - 1) SizedBox(height: 8.h),
      ],
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.check_circle_rounded,
        title: '佩戴当前称号',
        subtitle: '把「雨后巡水者」展示到主页和社区动态',
        color: InkPalette.reed,
      ),
      InkSheetAction(
        icon: Icons.route_rounded,
        title: '查看称号路线',
        subtitle: '按出钓习惯推荐下一个可解锁称号',
        color: InkPalette.lake,
      ),
    ],
  );
}

void _showBadgeWallSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '勋章墙',
    subtitle: '每枚勋章都来自真实记录、互助行为或低概率挑战',
    icon: Icons.emoji_events_rounded,
    color: InkPalette.pine,
    children: [
      Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: [
          for (final badge in _honorBadges)
            SizedBox(
              width: 92.w,
              child: _BadgeMedallion(badge: badge),
            ),
        ],
      ),
      SizedBox(height: 12.h),
      for (var i = 0; i < _honorBadges.take(3).length; i++) ...[
        InkInfoRow(
          icon: _honorBadges[i].icon,
          title: _honorBadges[i].name,
          subtitle: _honorBadges[i].desc,
          color: _honorBadges[i].color,
        ),
        if (i != 2) SizedBox(height: 8.h),
      ],
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.ios_share_rounded,
        title: '生成勋章海报',
        subtitle: '把本月新增勋章做成水墨分享卡',
        color: InkPalette.reed,
      ),
      InkSheetAction(
        icon: Icons.auto_awesome_rounded,
        title: '推荐下一枚',
        subtitle: '根据近期出钓记录推荐最容易解锁的勋章',
        color: InkPalette.lake,
      ),
    ],
  );
}

void _showFishAtlasSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '鱼种图鉴',
    subtitle: '已解锁 36/128，图鉴会反哺首页鱼情模型',
    icon: Icons.menu_book_rounded,
    color: InkPalette.lake,
    children: [
      Row(
        children: const [
          Expanded(
            child: InkMetric(
              value: '36',
              label: '已解锁',
              icon: Icons.check_circle_rounded,
              color: InkPalette.lake,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(
              value: '9',
              label: '稀有鱼种',
              icon: Icons.workspace_premium_rounded,
              color: InkPalette.reed,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(
              value: '128',
              label: '总图鉴',
              icon: Icons.menu_book_rounded,
              color: InkPalette.moss,
            ),
          ),
        ],
      ),
      SizedBox(height: 12.h),
      for (var i = 0; i < _fishAtlasPreview.length; i++) ...[
        _FishAtlasRow(item: _fishAtlasPreview[i]),
        if (i != _fishAtlasPreview.length - 1) SizedBox(height: 8.h),
      ],
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.add_a_photo_rounded,
        title: '补录鱼种',
        subtitle: '从历史鱼获中补全鱼种、尺寸和钓法',
        color: InkPalette.pine,
      ),
      InkSheetAction(
        icon: Icons.travel_explore_rounded,
        title: '查看未解锁',
        subtitle: '按季节、水域和钓法推荐下一个目标鱼',
        color: InkPalette.reed,
      ),
    ],
  );
}

void _showProfilePassportSheet(
  BuildContext context,
  String name,
  String level,
) {
  showInkActionSheet(
    context,
    title: name,
    subtitle: '$level · 山水之间的个人钓客档案',
    icon: Icons.person_rounded,
    color: InkPalette.pine,
    actions: const [
      InkSheetAction(
        icon: Icons.verified_user_rounded,
        title: '钓友信用',
        subtitle: '由真实订单、设备归还和社区互助组成',
        color: InkPalette.moss,
      ),
      InkSheetAction(
        icon: Icons.auto_graph_rounded,
        title: '个人鱼情模型',
        subtitle: '结合历史鱼获和设备数据优化建议',
        color: InkPalette.lake,
      ),
      InkSheetAction(
        icon: Icons.ios_share_rounded,
        title: '生成个人主页',
        subtitle: '分享战绩、钓点贡献和装备信用',
        color: InkPalette.reed,
      ),
    ],
  );
}

void _showRecordSheet(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
) {
  showInkActionSheet(
    context,
    title: title,
    subtitle: '按时间、水域、鱼种和玩法沉淀为可分析数据',
    icon: icon,
    color: color,
    actions: const [
      InkSheetAction(
        icon: Icons.timeline_rounded,
        title: '时间轴',
        subtitle: '按出钓日期查看记录',
        color: InkPalette.pine,
      ),
      InkSheetAction(
        icon: Icons.map_rounded,
        title: '地图分布',
        subtitle: '查看常去水域和高光钓点',
        color: InkPalette.lake,
      ),
      InkSheetAction(
        icon: Icons.analytics_rounded,
        title: '数据分析',
        subtitle: '鱼种、天气、钓法与成功率关系',
        color: InkPalette.moss,
      ),
    ],
  );
}

void _showHomeCardSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '首页卡片布局',
    subtitle: '当前启用天气、鱼情、附近钓点、设备、排行和推荐内容',
    icon: Icons.dashboard_customize_rounded,
    color: InkPalette.pine,
    actions: const [
      InkSheetAction(
        icon: Icons.drag_indicator_rounded,
        title: '调整排序',
        subtitle: '把最常用的模块放到首页前面',
        color: InkPalette.pine,
      ),
      InkSheetAction(
        icon: Icons.visibility_rounded,
        title: '显示控制',
        subtitle: '隐藏订单、设备或社区模块',
        color: InkPalette.lake,
      ),
    ],
  );
}

void _showProfileDeviceSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '智能浮漂 FC-01',
    subtitle: '已连接 1 台 · 电量 78% · 数据同步正常',
    icon: Icons.sensors_rounded,
    color: InkPalette.pine,
    children: [
      Row(
        children: const [
          Expanded(
            child: InkMetric(value: '18.6°C', label: '水温'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(value: '1.25m', label: '水深'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(value: '78%', label: '电量'),
          ),
        ],
      ),
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.sync_rounded,
        title: '同步设备',
        subtitle: '刷新最近一次水情数据',
        color: InkPalette.lake,
      ),
      InkSheetAction(
        icon: Icons.settings_rounded,
        title: '设备管理',
        subtitle: '校准、解绑、售后和固件升级',
        color: InkPalette.moss,
      ),
    ],
  );
}
