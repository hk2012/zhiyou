import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/home_recommendation_models.dart';
import '../data/home_recommendation_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _scenarioIndex = 0;
  bool _isRefreshing = false;

  _FishingMockScenario get _scenario => _mockScenarios[_scenarioIndex];

  Future<void> _refreshScenario() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  void _selectScenario(int index) {
    if (_scenarioIndex == index) return;
    setState(() => _scenarioIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenario;

    return InkPage(
      child: RefreshIndicator(
        color: InkPalette.pine,
        backgroundColor: InkPalette.white,
        onRefresh: _refreshScenario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 116.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeTopBar(
                scenario: scenario,
                isRefreshing: _isRefreshing,
                onRefresh: _refreshScenario,
              ),
              _ScenarioRail(
                scenarios: _mockScenarios,
                activeIndex: _scenarioIndex,
                onSelected: _selectScenario,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Column(
                  key: ValueKey(scenario.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isRefreshing)
                      Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                        child: const _RefreshingBanner(),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                      child: _DecisionHeroCard(
                        scenario: scenario,
                        onDetails: () =>
                            _showScenarioDetailSheet(context, scenario),
                        onPrimary: () => context.go(AppRouteNames.explore),
                        onPlan: () => _showPlanSheet(context, scenario),
                      ),
                    ),
                    InkSectionHeader(
                      title: '今日出钓计划',
                      subtitle: scenario.planSubtitle,
                      action: '现场修正',
                      onAction: () => _showFieldTuneSheet(context, scenario),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _TodayPlanCard(
                        scenario: scenario,
                        onOpenPlan: () => _showPlanSheet(context, scenario),
                        onTune: () => _showFieldTuneSheet(context, scenario),
                      ),
                    ),
                    const InkSectionHeader(
                      title: '一键行动',
                      subtitle: '从出发、到水边、钓后记录形成闭环',
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _CoreActionGrid(
                        scenario: scenario,
                        onNavigate: () => context.go(AppRouteNames.explore),
                        onTune: () => _showFieldTuneSheet(context, scenario),
                        onGear: () => _showGearSheet(context, scenario),
                        onCatch: () =>
                            context.push(AppRouteNames.creationModal),
                      ),
                    ),
                    InkSectionHeader(
                      title: '推荐依据',
                      subtitle: '让 AI 结论可被信任',
                      action: '全部',
                      onAction: () =>
                          _showScenarioDetailSheet(context, scenario),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _EvidenceCard(scenario: scenario),
                    ),
                    const InkSectionHeader(
                      title: '鱼种与钓法矩阵',
                      subtitle: '新手看建议，老手看概率',
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _FishMethodMatrix(scenario: scenario),
                    ),
                    InkSectionHeader(
                      title: '附近钓点',
                      subtitle: '按当前场景重新排序',
                      action: '地图',
                      onAction: () => context.go(AppRouteNames.explore),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _SpotRecommendationList(scenario: scenario),
                    ),
                    const InkSectionHeader(
                      title: '辅助信号',
                      subtitle: '设备、安全、真实鱼获轻量提示',
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _AuxiliarySignalList(
                        scenario: scenario,
                        onDevice: () => _showDeviceSheet(context, scenario),
                      ),
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

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.scenario,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final _FishingMockScenario scenario;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InkBrand(compact: true),
              const Spacer(),
              InkRoundButton(
                icon: Icons.notifications_none_rounded,
                badge: scenario.alertBadge,
                onTap: () => _showNotificationSheet(context, scenario),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          InkPressable(
            onTap: onRefresh,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 56.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: InkPalette.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: InkPalette.line),
                boxShadow: [
                  BoxShadow(
                    color: InkPalette.ink.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkIconMark(
                    icon: Icons.location_on_rounded,
                    color: scenario.accent,
                    size: 38,
                    iconSize: 18,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          scenario.updateText,
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
                  AnimatedRotation(
                    turns: isRefreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 720),
                    child: Icon(
                      isRefreshing
                          ? Icons.sync_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: InkPalette.muted,
                      size: 18.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioRail extends StatelessWidget {
  const _ScenarioRail({
    required this.scenarios,
    required this.activeIndex,
    required this.onSelected,
  });

  final List<_FishingMockScenario> scenarios;
  final int activeIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: scenarios.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final scenario = scenarios[index];
          return InkChip(
            icon: scenario.railIcon,
            label: scenario.railLabel,
            active: index == activeIndex,
            color: scenario.accent,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _RefreshingBanner extends StatelessWidget {
  const _RefreshingBanner();

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color: InkPalette.pine.withValues(alpha: 0.92),
      borderColor: InkPalette.pine.withValues(alpha: 0.22),
      child: Row(
        children: [
          const InkTaijiLoader(size: 24, label: ''),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              '正在重算天气、水情和近期鱼口...',
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
    );
  }
}

class _DecisionHeroCard extends StatelessWidget {
  const _DecisionHeroCard({
    required this.scenario,
    required this.onDetails,
    required this.onPrimary,
    required this.onPlan,
  });

  final _FishingMockScenario scenario;
  final VoidCallback onDetails;
  final VoidCallback onPrimary;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onDetails,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                scenario.heroAsset,
                fit: BoxFit.cover,
                alignment: scenario.heroAlignment,
                errorBuilder: (context, error, stackTrace) {
                  return const InkLandscapeHero(height: 314, bright: true);
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      InkPalette.ink.withValues(alpha: 0.16),
                      scenario.accent.withValues(alpha: 0.42),
                      InkPalette.ink.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 7.w,
                          runSpacing: 7.h,
                          children: [
                            _FrostTag(
                              icon: scenario.weatherIcon,
                              label: scenario.weather,
                            ),
                            _FrostTag(
                              icon: Icons.water_drop_rounded,
                              label: scenario.waterTemp,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _DecisionScoreRing(
                        score: scenario.score,
                        label: scenario.scoreLabel,
                        color: scenario.accent,
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),
                  _HeroReadabilityPanel(
                    scenario: scenario,
                    onPrimary: onPrimary,
                    onPlan: onPlan,
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

class _HeroReadabilityPanel extends StatelessWidget {
  const _HeroReadabilityPanel({
    required this.scenario,
    required this.onPrimary,
    required this.onPlan,
  });

  final _FishingMockScenario scenario;
  final VoidCallback onPrimary;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: InkPalette.ink.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: InkPalette.ink.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario.conclusion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.white,
              fontSize: 32.sp,
              height: 1.02,
              fontWeight: FontWeight.w900,
              fontFamily: 'MaShanZheng',
              fontFamilyFallback: brushFontFallback,
              shadows: const [
                Shadow(
                  color: Color(0xAA000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            '主攻：${scenario.target}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.white,
              fontSize: 19.sp,
              height: 1.16,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 8)],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            scenario.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.white.withValues(alpha: 0.96),
              fontSize: 13.5.sp,
              height: 1.48,
              fontWeight: FontWeight.w800,
              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
            ),
          ),
          SizedBox(height: 13.h),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.schedule_rounded,
                  label: '最佳窗口',
                  value: scenario.bestTime,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.place_rounded,
                  label: '推荐水域',
                  value: scenario.spotHint,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.block_rounded,
                  label: '不要做',
                  value: scenario.avoid,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: InkPrimaryButton(
                  label: scenario.primaryAction,
                  icon: Icons.near_me_rounded,
                  color: scenario.accent,
                  onTap: onPrimary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: InkPrimaryButton(
                  label: '钓法方案',
                  icon: Icons.auto_awesome_rounded,
                  color: InkPalette.lake,
                  onTap: onPlan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrostTag extends StatelessWidget {
  const _FrostTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: InkPalette.pine, size: 14.w),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionScoreRing extends StatelessWidget {
  const _DecisionScoreRing({
    required this.score,
    required this.label,
    required this.color,
  });

  final int score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = score.clamp(0, 100) / 100;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 820),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 74.w,
          height: 74.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: InkPalette.ink.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _DecisionScorePainter(progress: value, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: 24.sp,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    style: TextStyle(
                      color: InkPalette.white.withValues(alpha: 0.88),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecisionScorePainter extends CustomPainter {
  const _DecisionScorePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final bg = Paint()
      ..color = InkPalette.ink.withValues(alpha: 0.84)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bg);

    final ring = Paint()
      ..color = InkPalette.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 5, ring);

    final active = Paint()
      ..shader = SweepGradient(
        colors: [color, Color.lerp(color, InkPalette.white, 0.28)!, color],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -1.5708,
      6.28318 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _DecisionScorePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: InkPalette.ink.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: InkPalette.white, size: 13.w),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.white.withValues(alpha: 0.90),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.white,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 5)],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({
    required this.scenario,
    required this.onOpenPlan,
    required this.onTune,
  });

  final _FishingMockScenario scenario;
  final VoidCallback onOpenPlan;
  final VoidCallback onTune;

  @override
  Widget build(BuildContext context) {
    final opening = scenario.steps.first;
    final last = scenario.steps.last;

    return InkGlassCard(
      padding: EdgeInsets.all(13.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scenario.planTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkChip(
                label: scenario.modeLabel,
                active: false,
                color: scenario.accent,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(11.r),
            decoration: BoxDecoration(
              color: scenario.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: scenario.accent.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                InkIconMark(
                  icon: Icons.play_arrow_rounded,
                  color: scenario.accent,
                  size: 38,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '现在先做：${opening.title}',
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
                        '${opening.subtitle} · ${opening.badge} 后判断',
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
          ),
          SizedBox(height: 11.h),
          _PlanMiniMetaRow(scenario: scenario),
          SizedBox(height: 11.h),
          for (var i = 0; i < scenario.steps.length; i++) ...[
            _PlanStepRow(
              step: scenario.steps[i],
              index: i + 1,
              isFirst: i == 0,
              isLast: i == scenario.steps.length - 1,
            ),
            if (i != scenario.steps.length - 1) SizedBox(height: 9.h),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InkPrimaryButton(
                  label: '开始计划',
                  icon: Icons.flag_rounded,
                  color: scenario.accent,
                  onTap: onOpenPlan,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: InkPressable(
                  onTap: onTune,
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: InkPalette.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: InkPalette.ink.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: InkPalette.pine,
                          size: 18.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '现场修正',
                          style: TextStyle(
                            color: InkPalette.pine,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '止损规则：${last.title}，${last.subtitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.cinnabar,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMiniMetaRow extends StatelessWidget {
  const _PlanMiniMetaRow({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.schedule_rounded, '窗口', scenario.bestTime, scenario.accent),
      (Icons.place_rounded, '站位', scenario.spotHint, InkPalette.lake),
      (Icons.inventory_2_rounded, '装备', scenario.gearShort, InkPalette.reed),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: items[i].$4.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: items[i].$4.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(items[i].$1, color: items[i].$4, size: 13.w),
                      SizedBox(width: 4.w),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: InkPalette.muted,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    items[i].$3,
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
          ),
          if (i != items.length - 1) SizedBox(width: 8.w),
        ],
      ],
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({
    required this.step,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final _PlanStep step;
  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: step.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: step.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: step.color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
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
                  step.subtitle,
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: InkPalette.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: step.color.withValues(alpha: 0.18)),
            ),
            child: Text(
              isFirst
                  ? '先做'
                  : isLast
                  ? '止损'
                  : step.badge,
              style: TextStyle(
                color: step.color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreActionGrid extends StatelessWidget {
  const _CoreActionGrid({
    required this.scenario,
    required this.onNavigate,
    required this.onTune,
    required this.onGear,
    required this.onCatch,
  });

  final _FishingMockScenario scenario;
  final VoidCallback onNavigate;
  final VoidCallback onTune;
  final VoidCallback onGear;
  final VoidCallback onCatch;

  @override
  Widget build(BuildContext context) {
    final tuneAction = _CoreAction(
      icon: Icons.tune_rounded,
      title: '现场修正',
      subtitle: '到水边先校准水色 / 风口 / 人流 / 鱼层',
      badge: '到点必做',
      metric: '4项',
      color: InkPalette.lake,
      onTap: onTune,
    );
    final gearAction = _CoreAction(
      icon: Icons.inventory_2_rounded,
      title: '装备清单',
      subtitle: scenario.gearShort,
      badge: '出发前',
      metric: '核对',
      color: InkPalette.reed,
      onTap: onGear,
    );
    final catchAction = _CoreAction(
      icon: Icons.add_photo_alternate_rounded,
      title: '记录鱼获',
      subtitle: '拍照、鱼种、钓法与水情，反哺鱼情模型',
      badge: '钓后',
      metric: '+经验',
      color: InkPalette.moss,
      onTap: onCatch,
    );
    final stages = [
      _CoreAction(
        icon: Icons.near_me_rounded,
        title: '导航',
        subtitle: scenario.navigationHint,
        badge: '路上',
        metric: scenario.spotHint,
        color: scenario.accent,
        onTap: onNavigate,
      ),
      tuneAction,
      gearAction,
      catchAction,
    ];

    return Column(
      children: [
        _CorePrimaryActionCard(scenario: scenario, onTap: onNavigate),
        SizedBox(height: 10.h),
        _CoreActionStageStrip(items: stages),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _CoreActionTile(action: tuneAction)),
            SizedBox(width: 10.w),
            Expanded(child: _CoreActionTile(action: gearAction)),
          ],
        ),
        SizedBox(height: 10.h),
        _CoreActionTile(action: catchAction, wide: true),
      ],
    );
  }
}

class _CorePrimaryActionCard extends StatelessWidget {
  const _CorePrimaryActionCard({required this.scenario, required this.onTap});

  final _FishingMockScenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(13.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scenario.accent,
              Color.lerp(scenario.accent, InkPalette.lake, 0.46)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: scenario.accent.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkIconMark(
                  icon: Icons.near_me_rounded,
                  color: InkPalette.white,
                  size: 42,
                  iconSize: 19,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下一步：${scenario.primaryAction}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${scenario.location} · ${scenario.navigationHint}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.white.withValues(alpha: 0.78),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: InkPalette.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: InkPalette.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: InkPalette.white,
                    size: 18.w,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _CorePrimaryMeta(
                    icon: Icons.schedule_rounded,
                    label: '窗口',
                    value: scenario.bestTime,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _CorePrimaryMeta(
                    icon: Icons.place_rounded,
                    label: '站位',
                    value: scenario.spotHint,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _CorePrimaryMeta(
                    icon: scenario.safetyIcon,
                    label: '安全',
                    value: scenario.safetyLevel,
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

class _CorePrimaryMeta extends StatelessWidget {
  const _CorePrimaryMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: InkPalette.white, size: 12.w),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: InkPalette.white.withValues(alpha: 0.72),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _CoreActionStageStrip extends StatelessWidget {
  const _CoreActionStageStrip({required this.items});

  final List<_CoreAction> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _CoreActionStageItem(action: items[i], active: i == 0),
          ),
          if (i != items.length - 1)
            Container(
              width: 12.w,
              height: 1.5.h,
              color: InkPalette.line.withValues(alpha: 0.82),
            ),
        ],
      ],
    );
  }
}

class _CoreActionStageItem extends StatelessWidget {
  const _CoreActionStageItem({required this.action, required this.active});

  final _CoreAction action;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active
              ? action.color.withValues(alpha: 0.11)
              : InkPalette.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? action.color.withValues(alpha: 0.20)
                : InkPalette.line.withValues(alpha: 0.76),
          ),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: action.color, size: 15.w),
            SizedBox(height: 3.h),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? action.color : InkPalette.text,
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

class _CoreActionTile extends StatelessWidget {
  const _CoreActionTile({required this.action, this.wide = false});

  final _CoreAction action;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      onTap: action.onTap,
      child: Row(
        children: [
          InkIconMark(icon: action.icon, color: action.color, size: 42),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
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
                  action.subtitle,
                  maxLines: wide ? 2 : 1,
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  action.badge,
                  style: TextStyle(
                    color: action.color,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                action.metric,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkInfoRow(
                  icon: Icons.verified_rounded,
                  title: '推荐置信度',
                  subtitle: '${scenario.confidence} · ${scenario.dataSource}',
                  color: scenario.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (var i = 0; i < scenario.evidence.length; i++) ...[
            _EvidenceRow(item: scenario.evidence[i]),
            if (i != scenario.evidence.length - 1) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});

  final _EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          InkIconMark(icon: item.icon, color: item.color, size: 34),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
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
                  item.subtitle,
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
            item.trailing,
            style: TextStyle(
              color: item.color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FishMethodMatrix extends StatelessWidget {
  const _FishMethodMatrix({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scenario.fishMethods.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) {
        return _FishMethodCard(method: scenario.fishMethods[index]);
      },
    );
  }
}

class _FishMethodCard extends StatelessWidget {
  const _FishMethodCard({required this.method});

  final _FishMethod method;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${method.fish} · ${method.method}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${method.probability}%',
            style: TextStyle(
              color: method.color,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            method.advice,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.5.sp,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: method.probability / 100,
              minHeight: 6.h,
              color: method.color,
              backgroundColor: InkPalette.line.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotRecommendationList extends StatelessWidget {
  const _SpotRecommendationList({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < scenario.spots.length; i++) ...[
          _SpotCard(
            spot: scenario.spots[i],
            accent: scenario.accent,
            onTap: () =>
                _showSpotDetailSheet(context, scenario, scenario.spots[i]),
          ),
          if (i != scenario.spots.length - 1) SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({
    required this.spot,
    required this.accent,
    required this.onTap,
  });

  final _SpotMock spot;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(10.r),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 92.w,
            height: 70.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: const InkMiniMap(height: 70),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      spot.distance,
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7.h),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 5.h,
                  children: spot.tags
                      .map(
                        (tag) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: spot.score / 100,
                          minHeight: 6.h,
                          color: accent,
                          backgroundColor: InkPalette.line.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${spot.score}分',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuxiliarySignalList extends StatelessWidget {
  const _AuxiliarySignalList({required this.scenario, required this.onDevice});

  final _FishingMockScenario scenario;
  final VoidCallback onDevice;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        children: [
          InkInfoRow(
            icon: Icons.sensors_rounded,
            title: scenario.deviceTitle,
            subtitle: scenario.deviceSubtitle,
            trailing: scenario.deviceState,
            color: scenario.accent,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InkMetric(
                  value: scenario.waterTemp.replaceAll('水温 ', ''),
                  label: '水温',
                  icon: Icons.water_drop_rounded,
                  color: scenario.accent,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkMetric(
                  value: scenario.depth,
                  label: '水深',
                  icon: Icons.stacked_line_chart_rounded,
                  color: InkPalette.lake,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          InkSafetyAlertCard(
            icon: scenario.safetyIcon,
            title: scenario.safetyTitle,
            subtitle: scenario.safetySubtitle,
            color: scenario.safetyColor,
            onTap: onDevice,
          ),
          SizedBox(height: 10.h),
          InkPressable(
            onTap: onDevice,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '查看设备与安全详情',
                  style: TextStyle(
                    color: InkPalette.pine,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: InkPalette.pine,
                  size: 16.w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showScenarioDetailSheet(
  BuildContext context,
  _FishingMockScenario scenario,
) {
  showInkActionSheet(
    context,
    title: '${scenario.railLabel} · 推荐拆解',
    subtitle: scenario.summary,
    icon: Icons.psychology_alt_rounded,
    color: scenario.accent,
    showLandscape: true,
    children: [
      Row(
        children: [
          Expanded(
            child: InkMetric(
              value: '${scenario.score}分',
              label: scenario.scoreLabel,
              icon: Icons.auto_graph_rounded,
              color: scenario.accent,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(
              value: scenario.confidence,
              label: '置信度',
              icon: Icons.verified_rounded,
              color: InkPalette.lake,
            ),
          ),
        ],
      ),
    ],
    actions: [
      for (final item in scenario.evidence)
        InkSheetAction(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          color: item.color,
        ),
    ],
  );
}

void _showPlanSheet(BuildContext context, _FishingMockScenario scenario) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.28),
    builder: (sheetContext) {
      return _FishingPlanSheet(
        scenario: scenario,
        onTune: () {
          Navigator.of(sheetContext).pop();
          _showFieldTuneSheet(context, scenario);
        },
        onSave: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${scenario.railLabel}方案已保存到今日计划'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    },
  );
}

class _FishingPlanSheet extends StatefulWidget {
  const _FishingPlanSheet({
    required this.scenario,
    required this.onTune,
    required this.onSave,
  });

  final _FishingMockScenario scenario;
  final VoidCallback onTune;
  final VoidCallback onSave;

  @override
  State<_FishingPlanSheet> createState() => _FishingPlanSheetState();
}

class _FishingPlanSheetState extends State<_FishingPlanSheet> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 820), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: SizedBox(
          height: height,
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
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
                _PlanSheetHeader(scenario: widget.scenario),
                SizedBox(height: 12.h),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: _loading
                        ? _PlanLoadingView(
                            key: const ValueKey('loading'),
                            scenario: widget.scenario,
                          )
                        : _PlanReadyContent(
                            key: const ValueKey('ready'),
                            scenario: widget.scenario,
                          ),
                  ),
                ),
                if (!_loading) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkPrimaryButton(
                          label: '保存计划',
                          icon: Icons.bookmark_add_rounded,
                          color: widget.scenario.accent,
                          onTap: widget.onSave,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkPrimaryButton(
                          label: '现场修正',
                          icon: Icons.tune_rounded,
                          color: InkPalette.lake,
                          onTap: widget.onTune,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSheetHeader extends StatelessWidget {
  const _PlanSheetHeader({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkIconMark(
          icon: Icons.auto_awesome_rounded,
          color: scenario.accent,
          size: 42,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 钓法方案',
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '${scenario.target} · ${scenario.bestTime} · ${scenario.spotHint}',
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
          label: scenario.scoreLabel,
          active: true,
          color: scenario.accent,
        ),
      ],
    );
  }
}

class _PlanLoadingView extends StatelessWidget {
  const _PlanLoadingView({super.key, required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('读取场景', '天气、水温、水深、窗口期'),
      ('匹配目标', scenario.target),
      ('生成动作', '装备、开局、换层、止损'),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 142.w,
          height: 142.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                InkPalette.lake.withValues(alpha: 0.92),
                InkPalette.ink.withValues(alpha: 0.96),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scenario.accent.withValues(alpha: 0.28),
                blurRadius: 34,
                offset: Offset(0, 14.h),
              ),
            ],
          ),
          child: const Center(child: InkTaijiLoader(size: 116, label: '')),
        ),
        SizedBox(height: 18.h),
        Text(
          '正在生成可执行钓法',
          style: TextStyle(
            color: InkPalette.text,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          '先给能执行的方案，再解释为什么',
          style: TextStyle(
            color: InkPalette.muted,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 18.h),
        for (final row in rows) ...[
          _PlanLoadingRow(
            title: row.$1,
            subtitle: row.$2,
            color: scenario.accent,
          ),
          SizedBox(height: 9.h),
        ],
      ],
    );
  }
}

class _PlanLoadingRow extends StatelessWidget {
  const _PlanLoadingRow({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 12.5.sp,
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
    );
  }
}

class _PlanReadyContent extends StatelessWidget {
  const _PlanReadyContent({super.key, required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    final opening = scenario.steps.first;
    final search = scenario.steps.length > 1
        ? scenario.steps[1]
        : scenario.steps.first;
    final adjustment = scenario.steps.last;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanStatsStrip(scenario: scenario),
          SizedBox(height: 12.h),
          _PlanBlock(
            index: '1',
            icon: Icons.inventory_2_rounded,
            title: '装备清单',
            subtitle: scenario.gearDetail,
            footer: scenario.gearChecklist,
            badge: '出发前',
            color: InkPalette.reed,
          ),
          SizedBox(height: 10.h),
          _PlanBlock(
            index: '2',
            icon: Icons.flag_rounded,
            title: '开局打法',
            subtitle: '${opening.title}：${opening.subtitle}',
            footer: '${search.title}：${search.subtitle}',
            badge: search.badge,
            color: scenario.accent,
          ),
          SizedBox(height: 10.h),
          _PlanBlock(
            index: '3',
            icon: Icons.swap_vert_rounded,
            title: '无口调整',
            subtitle: '${adjustment.title}：${adjustment.subtitle}',
            footer: '不要做：${scenario.avoid}',
            badge: adjustment.badge,
            color: InkPalette.cinnabar,
          ),
          SizedBox(height: 10.h),
          _PlanBlock(
            index: '4',
            icon: scenario.safetyIcon,
            title: '安全与止损',
            subtitle: scenario.safetySubtitle,
            footer: '到点后用现场修正刷新水色、风口、人流和鱼层。',
            badge: scenario.safetyLevel,
            color: scenario.safetyColor,
          ),
        ],
      ),
    );
  }
}

class _PlanStatsStrip extends StatelessWidget {
  const _PlanStatsStrip({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlanMiniStat(
            label: '主攻',
            value: scenario.target,
            color: scenario.accent,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _PlanMiniStat(
            label: '窗口',
            value: scenario.bestTime,
            color: InkPalette.lake,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _PlanMiniStat(
            label: '站位',
            value: scenario.spotHint,
            color: InkPalette.moss,
          ),
        ),
      ],
    );
  }
}

class _PlanMiniStat extends StatelessWidget {
  const _PlanMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 10.5.sp,
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
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBlock extends StatelessWidget {
  const _PlanBlock({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.badge,
    required this.color,
  });

  final String index;
  final IconData icon;
  final String title;
  final String subtitle;
  final String footer;
  final String badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.88),
      borderColor: color.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    index,
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              InkIconMark(icon: icon, color: color, size: 34, iconSize: 18),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkChip(label: badge, active: false, color: color),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            subtitle,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.5.sp,
              height: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            footer,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.5.sp,
              height: 1.38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

void _showFieldTuneSheet(BuildContext context, _FishingMockScenario scenario) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (_) => _FieldTuneSheet(scenario: scenario),
  );
}

class _FieldTuneSheet extends ConsumerStatefulWidget {
  const _FieldTuneSheet({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  ConsumerState<_FieldTuneSheet> createState() => _FieldTuneSheetState();
}

class _FieldTuneSheetState extends ConsumerState<_FieldTuneSheet> {
  late int _waterIndex;
  late int _windIndex;
  late int _crowdIndex;
  late int _layerIndex;
  bool _recalculating = true;
  bool _aiLoading = false;
  FishingAiAnalysis? _aiAnalysis;
  String? _aiError;
  int _calculationRun = 0;

  @override
  void initState() {
    super.initState();
    final defaults = _defaultTuneSelection(widget.scenario);
    _waterIndex = defaults.water;
    _windIndex = defaults.wind;
    _crowdIndex = defaults.crowd;
    _layerIndex = defaults.layer;
    _scheduleRecalculation(const Duration(milliseconds: 560));
  }

  void _scheduleRecalculation(Duration delay) {
    final run = ++_calculationRun;
    setState(() {
      _recalculating = true;
      _aiLoading = false;
      _aiAnalysis = null;
      _aiError = null;
    });
    Future<void>.delayed(delay, () {
      if (!mounted || run != _calculationRun) return;
      setState(() => _recalculating = false);
      _requestAiAnalysis(run);
    });
  }

  Future<void> _requestAiAnalysis(int run) async {
    final result = _result;
    final observations = _selectedAiObservations;
    setState(() => _aiLoading = true);
    try {
      final analysis = await ref
          .read(homeRecommendationRepositoryProvider)
          .analyzeFishing(
            locationName: widget.scenario.location,
            target: widget.scenario.target,
            weather: widget.scenario.weather,
            waterTemperature: widget.scenario.waterTemp,
            depth: widget.scenario.depth,
            bestTime: widget.scenario.bestTime,
            spotHint: widget.scenario.spotHint,
            gear: widget.scenario.gearShort,
            baselineScore: widget.scenario.score,
            adjustedScore: result.score,
            localHeadline: result.headline,
            localStrategy: '${result.stance}；${result.layer}；${result.pace}',
            observations: observations,
          );
      if (!mounted || run != _calculationRun) return;
      setState(() {
        _aiAnalysis = analysis;
        _aiError = null;
        _aiLoading = false;
      });
    } catch (_) {
      if (!mounted || run != _calculationRun) return;
      setState(() {
        _aiError = '本机 AI 后台暂不可用，已保留本地二次分析。';
        _aiLoading = false;
      });
    }
  }

  List<Map<String, String>> get _selectedAiObservations {
    final water = _waterTuneOptions[_waterIndex];
    final wind = _windTuneOptions[_windIndex];
    final crowd = _crowdTuneOptions[_crowdIndex];
    final layer = _layerTuneOptions[_layerIndex];
    return [
      {'label': '水色', 'value': water.label, 'effect': water.effect},
      {'label': '风口', 'value': wind.label, 'effect': wind.effect},
      {'label': '人流', 'value': crowd.label, 'effect': crowd.effect},
      {'label': '鱼层反馈', 'value': layer.label, 'effect': layer.effect},
    ];
  }

  void _selectWater(int index) {
    if (_waterIndex == index) return;
    setState(() => _waterIndex = index);
    _scheduleRecalculation(const Duration(milliseconds: 420));
  }

  void _selectWind(int index) {
    if (_windIndex == index) return;
    setState(() => _windIndex = index);
    _scheduleRecalculation(const Duration(milliseconds: 420));
  }

  void _selectCrowd(int index) {
    if (_crowdIndex == index) return;
    setState(() => _crowdIndex = index);
    _scheduleRecalculation(const Duration(milliseconds: 420));
  }

  void _selectLayer(int index) {
    if (_layerIndex == index) return;
    setState(() => _layerIndex = index);
    _scheduleRecalculation(const Duration(milliseconds: 420));
  }

  void _resetDefaults() {
    final defaults = _defaultTuneSelection(widget.scenario);
    setState(() {
      _waterIndex = defaults.water;
      _windIndex = defaults.wind;
      _crowdIndex = defaults.crowd;
      _layerIndex = defaults.layer;
    });
    _scheduleRecalculation(const Duration(milliseconds: 420));
  }

  void _applyResult() {
    final result = _result;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已按现场二次分析生成：${result.headline}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: InkPalette.ink,
      ),
    );
  }

  _TuneResult get _result {
    final water = _waterTuneOptions[_waterIndex];
    final wind = _windTuneOptions[_windIndex];
    final crowd = _crowdTuneOptions[_crowdIndex];
    final layer = _layerTuneOptions[_layerIndex];
    final diff =
        water.scoreDelta +
        wind.scoreDelta +
        crowd.scoreDelta +
        layer.scoreDelta;
    final score = (widget.scenario.score + diff).clamp(18, 96).round();
    final color = score >= 80
        ? InkPalette.pine
        : score >= 62
        ? InkPalette.lake
        : score >= 46
        ? InkPalette.reed
        : InkPalette.cinnabar;
    final statusLabel = score >= 80
        ? '继续主攻'
        : score >= 62
        ? '修正可钓'
        : score >= 46
        ? '只短试'
        : '建议止损';
    final headline = score >= 80
        ? '原方案有效，按现场小幅微调'
        : score >= 62
        ? '可继续钓，但先改站位和节奏'
        : score >= 46
        ? '只保留一个短窗口，不要长守'
        : '偏差过大，优先换点或收竿';

    return _TuneResult(
      score: score,
      diff: diff,
      color: color,
      statusLabel: statusLabel,
      headline: headline,
      stance: _buildTuneStance(wind, crowd, widget.scenario),
      layer: _buildTuneLayer(layer),
      bait: _buildTuneBait(water, widget.scenario),
      pace: _buildTunePace(water, wind, crowd, layer, score),
      stopLoss: _buildTuneStopLoss(score, layer),
      reasons: [
        '${water.label}：${water.effect}',
        '${wind.label}：${wind.effect}',
        '${crowd.label}：${crowd.effect}',
        '${layer.label}：${layer.effect}',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final height = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: SizedBox(
          height: height,
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 15.h),
            child: Column(
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
                _FieldTuneHeader(scenario: widget.scenario, result: result),
                SizedBox(height: 12.h),
                _TuneBaselineStrip(scenario: widget.scenario, result: result),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TuneMethodCard(),
                        SizedBox(height: 10.h),
                        _TuneInputGroup(
                          index: '1',
                          title: '水色',
                          subtitle: '决定饵色、味型和搜索速度',
                          options: _waterTuneOptions,
                          selectedIndex: _waterIndex,
                          onSelected: _selectWater,
                        ),
                        SizedBox(height: 10.h),
                        _TuneInputGroup(
                          index: '2',
                          title: '风口',
                          subtitle: '决定站位、浪线和鱼层活跃度',
                          options: _windTuneOptions,
                          selectedIndex: _windIndex,
                          onSelected: _selectWind,
                        ),
                        SizedBox(height: 10.h),
                        _TuneInputGroup(
                          index: '3',
                          title: '人流',
                          subtitle: '决定近岸压力和是否需要后撤',
                          options: _crowdTuneOptions,
                          selectedIndex: _crowdIndex,
                          onSelected: _selectCrowd,
                        ),
                        SizedBox(height: 10.h),
                        _TuneInputGroup(
                          index: '4',
                          title: '鱼层反馈',
                          subtitle: '决定先搜哪一层，以及几分钟止损',
                          options: _layerTuneOptions,
                          selectedIndex: _layerIndex,
                          onSelected: _selectLayer,
                        ),
                        SizedBox(height: 12.h),
                        _TuneResultPanel(
                          result: result,
                          recalculating: _recalculating,
                          aiLoading: _aiLoading,
                          aiAnalysis: _aiAnalysis,
                          aiError: _aiError,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: InkPrimaryButton(
                        label: '应用修正',
                        icon: Icons.done_rounded,
                        color: result.color,
                        busy: _recalculating,
                        onTap: _applyResult,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: InkPressable(
                        onTap: _resetDefaults,
                        child: Container(
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: InkPalette.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: InkPalette.ink.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restart_alt_rounded,
                                color: InkPalette.pine,
                                size: 18.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '恢复默认',
                                style: TextStyle(
                                  color: InkPalette.pine,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldTuneHeader extends StatelessWidget {
  const _FieldTuneHeader({required this.scenario, required this.result});

  final _FishingMockScenario scenario;
  final _TuneResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkIconMark(icon: Icons.tune_rounded, color: result.color, size: 42),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '现场二次分析',
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '${scenario.target} · ${scenario.bestTime} · 到点后校准',
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
        InkChip(label: result.statusLabel, active: true, color: result.color),
      ],
    );
  }
}

class _TuneBaselineStrip extends StatelessWidget {
  const _TuneBaselineStrip({required this.scenario, required this.result});

  final _FishingMockScenario scenario;
  final _TuneResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TuneMiniStat(
            label: '原计划',
            value: '${scenario.score}分',
            color: scenario.accent,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _TuneMiniStat(
            label: '二次分',
            value: '${result.score}分',
            color: result.color,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _TuneMiniStat(
            label: '偏差',
            value: result.diffText,
            color: result.diff >= 0 ? InkPalette.moss : InkPalette.cinnabar,
          ),
        ),
      ],
    );
  }
}

class _TuneMiniStat extends StatelessWidget {
  const _TuneMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _TuneMethodCard extends StatelessWidget {
  const _TuneMethodCard();

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.86),
      borderColor: InkPalette.pine.withValues(alpha: 0.14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkIconMark(
            icon: Icons.functions_rounded,
            color: InkPalette.pine,
            size: 36,
            iconSize: 17,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '四因子校准法',
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '出发前计划 + 水色 + 风口 + 人流 + 鱼层反馈，重算站位、饵色、节奏和止损。',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.38,
                    fontWeight: FontWeight.w800,
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

class _TuneInputGroup extends StatelessWidget {
  const _TuneInputGroup({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String index;
  final String title;
  final String subtitle;
  final List<_TuneOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = options[selectedIndex];

    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.84),
      borderColor: selected.color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: selected.color,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    index,
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (var i = 0; i < options.length; i++)
                _TuneChoicePill(
                  option: options[i],
                  active: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
          SizedBox(height: 9.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: selected.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(selected.icon, color: selected.color, size: 15.w),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    selected.effect,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 11.5.sp,
                      height: 1.36,
                      fontWeight: FontWeight.w800,
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

class _TuneChoicePill extends StatelessWidget {
  const _TuneChoicePill({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final _TuneOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active
              ? option.color
              : InkPalette.rice.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? option.color
                : InkPalette.line.withValues(alpha: 0.80),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: active ? InkPalette.white : option.color,
              size: 15.w,
            ),
            SizedBox(width: 5.w),
            Text(
              option.label,
              style: TextStyle(
                color: active ? InkPalette.white : InkPalette.text,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuneResultPanel extends StatelessWidget {
  const _TuneResultPanel({
    required this.result,
    required this.recalculating,
    required this.aiLoading,
    required this.aiAnalysis,
    required this.aiError,
  });

  final _TuneResult result;
  final bool recalculating;
  final bool aiLoading;
  final FishingAiAnalysis? aiAnalysis;
  final String? aiError;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 230),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: recalculating
          ? _TuneLoadingCard(key: const ValueKey('tune-loading'))
          : _TuneReadyCard(
              key: const ValueKey('tune-ready'),
              result: result,
              aiLoading: aiLoading,
              aiAnalysis: aiAnalysis,
              aiError: aiError,
            ),
    );
  }
}

class _TuneLoadingCard extends StatelessWidget {
  const _TuneLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('读取现场偏差', '比对出发前预测与当前水边观察'),
      ('重排鱼层权重', '判断先搜中上层、贴底还是换点'),
      ('生成修正动作', '输出站位、饵色、节奏和止损'),
    ];

    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: InkPalette.ink.withValues(alpha: 0.90),
      borderColor: InkPalette.white.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const InkTaijiLoader(size: 30, label: ''),
              SizedBox(width: 10.w),
              Text(
                '正在二次分析',
                style: TextStyle(
                  color: InkPalette.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          for (final row in rows) ...[
            Text(
              row.$1,
              style: TextStyle(
                color: InkPalette.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              row.$2,
              style: TextStyle(
                color: InkPalette.white.withValues(alpha: 0.72),
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (row != rows.last) SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

class _TuneReadyCard extends StatelessWidget {
  const _TuneReadyCard({
    super.key,
    required this.result,
    required this.aiLoading,
    required this.aiAnalysis,
    required this.aiError,
  });

  final _TuneResult result;
  final bool aiLoading;
  final FishingAiAnalysis? aiAnalysis;
  final String? aiError;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: InkPalette.white.withValues(alpha: 0.90),
      borderColor: result.color.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: result.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: result.color.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${result.score}',
                    style: TextStyle(
                      color: InkPalette.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '重算结论',
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      result.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 14.sp,
                        height: 1.28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              InkChip(
                label: result.diffText,
                active: true,
                color: result.diff >= 0 ? InkPalette.moss : InkPalette.cinnabar,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _TuneResultLine(
            icon: Icons.place_rounded,
            label: '站位',
            value: result.stance,
            color: InkPalette.pine,
          ),
          SizedBox(height: 8.h),
          _TuneResultLine(
            icon: Icons.layers_rounded,
            label: '鱼层',
            value: result.layer,
            color: InkPalette.lake,
          ),
          SizedBox(height: 8.h),
          _TuneResultLine(
            icon: Icons.inventory_2_rounded,
            label: '饵法',
            value: result.bait,
            color: InkPalette.reed,
          ),
          SizedBox(height: 8.h),
          _TuneResultLine(
            icon: Icons.timer_rounded,
            label: '节奏',
            value: result.pace,
            color: InkPalette.moss,
          ),
          SizedBox(height: 8.h),
          _TuneResultLine(
            icon: Icons.flag_rounded,
            label: '止损',
            value: result.stopLoss,
            color: InkPalette.cinnabar,
          ),
          SizedBox(height: 11.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final reason in result.reasons)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: result.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: result.color.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          _AiAnalysisCard(
            loading: aiLoading,
            analysis: aiAnalysis,
            error: aiError,
            color: result.color,
          ),
        ],
      ),
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({
    required this.loading,
    required this.analysis,
    required this.error,
    required this.color,
  });

  final bool loading;
  final FishingAiAnalysis? analysis;
  final String? error;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _AiStatusBox(
        icon: Icons.auto_awesome_rounded,
        title: '正在连接本机 AI 后台',
        subtitle: '用 ChatGPT 模型生成垂钓分析...',
        color: color,
        trailing: const InkTaijiLoader(size: 22, label: ''),
      );
    }

    if (error != null) {
      return _AiStatusBox(
        icon: Icons.cloud_off_rounded,
        title: 'AI 后台未返回',
        subtitle: error!,
        color: InkPalette.cinnabar,
      );
    }

    final item = analysis;
    if (item == null) {
      return _AiStatusBox(
        icon: Icons.auto_awesome_rounded,
        title: 'AI 分析待生成',
        subtitle: '本地重算完成后会自动请求这台 Mac 的后台服务。',
        color: color,
      );
    }

    final statusColor = item.fromOpenAi ? InkPalette.pine : InkPalette.reed;
    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: statusColor.withValues(alpha: item.fromOpenAi ? 0.10 : 0.12),
      borderColor: statusColor.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkIconMark(
                icon: item.fromOpenAi
                    ? Icons.auto_awesome_rounded
                    : Icons.psychology_alt_rounded,
                color: statusColor,
                size: 36,
                iconSize: 18,
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fromOpenAi ? 'ChatGPT 垂钓分析' : '本机规则兜底',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${item.model} · 置信 ${item.confidence}%',
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
              InkChip(
                label: item.fromOpenAi ? 'AI' : '本地',
                active: true,
                color: statusColor,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            item.headline,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.sp,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            item.summary,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.5.sp,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          _TuneResultLine(
            icon: Icons.place_rounded,
            label: 'AI站位',
            value: item.spotStrategy,
            color: InkPalette.pine,
          ),
          SizedBox(height: 7.h),
          _TuneResultLine(
            icon: Icons.set_meal_rounded,
            label: 'AI饵法',
            value: item.baitStrategy,
            color: InkPalette.reed,
          ),
          SizedBox(height: 7.h),
          _TuneResultLine(
            icon: Icons.flag_rounded,
            label: 'AI止损',
            value: item.stopLoss,
            color: InkPalette.cinnabar,
          ),
          SizedBox(height: 9.h),
          Text(
            item.safetyNote,
            style: TextStyle(
              color: InkPalette.cinnabar,
              fontSize: 11.sp,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusBox extends StatelessWidget {
  const _AiStatusBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.18),
      child: Row(
        children: [
          InkIconMark(icon: icon, color: color, size: 34, iconSize: 17),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.sp,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
        ],
      ),
    );
  }
}

class _TuneResultLine extends StatelessWidget {
  const _TuneResultLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16.w),
        SizedBox(width: 7.w),
        SizedBox(
          width: 46.w,
          child: Text(
            label,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.sp,
              height: 1.36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TuneSelection {
  const _TuneSelection({
    required this.water,
    required this.wind,
    required this.crowd,
    required this.layer,
  });

  final int water;
  final int wind;
  final int crowd;
  final int layer;
}

class _TuneOption {
  const _TuneOption({
    required this.label,
    required this.icon,
    required this.scoreDelta,
    required this.effect,
    required this.color,
  });

  final String label;
  final IconData icon;
  final int scoreDelta;
  final String effect;
  final Color color;
}

class _TuneResult {
  const _TuneResult({
    required this.score,
    required this.diff,
    required this.color,
    required this.statusLabel,
    required this.headline,
    required this.stance,
    required this.layer,
    required this.bait,
    required this.pace,
    required this.stopLoss,
    required this.reasons,
  });

  final int score;
  final int diff;
  final Color color;
  final String statusLabel;
  final String headline;
  final String stance;
  final String layer;
  final String bait;
  final String pace;
  final String stopLoss;
  final List<String> reasons;

  String get diffText => diff >= 0 ? '+$diff' : '$diff';
}

const _waterTuneOptions = [
  _TuneOption(
    label: '清水',
    icon: Icons.opacity_rounded,
    scoreDelta: -4,
    effect: '鱼更警惕，换自然色、小轮廓，收慢动作。',
    color: InkPalette.lake,
  ),
  _TuneOption(
    label: '微浑',
    icon: Icons.water_drop_rounded,
    scoreDelta: 6,
    effect: '可视距离刚好，亮色、反光或腥香更容易被发现。',
    color: InkPalette.moss,
  ),
  _TuneOption(
    label: '泥水',
    icon: Icons.water_rounded,
    scoreDelta: -8,
    effect: '视觉弱，改重味、震动、大轮廓，搜索距离缩短。',
    color: InkPalette.cinnabar,
  ),
];

const _windTuneOptions = [
  _TuneOption(
    label: '迎风',
    icon: Icons.air_rounded,
    scoreDelta: 7,
    effect: '浪线带来氧和饵鱼，优先打迎风外沿。',
    color: InkPalette.pine,
  ),
  _TuneOption(
    label: '侧风',
    icon: Icons.swap_horiz_rounded,
    scoreDelta: 3,
    effect: '沿风线扇形搜索，先找有风纹的结构边。',
    color: InkPalette.lake,
  ),
  _TuneOption(
    label: '背风',
    icon: Icons.airline_stops_rounded,
    scoreDelta: -5,
    effect: '水面安静，鱼层可能下移，节奏要慢。',
    color: InkPalette.reed,
  ),
];

const _crowdTuneOptions = [
  _TuneOption(
    label: '安静',
    icon: Icons.volume_off_rounded,
    scoreDelta: 5,
    effect: '近岸压力低，可先打草边、桥影和浅滩边。',
    color: InkPalette.moss,
  ),
  _TuneOption(
    label: '零散',
    icon: Icons.person_pin_circle_rounded,
    scoreDelta: 0,
    effect: '避开脚步声和抛投密集点，保留原计划。',
    color: InkPalette.lake,
  ),
  _TuneOption(
    label: '拥挤',
    icon: Icons.groups_rounded,
    scoreDelta: -9,
    effect: '近岸鱼口会收缩，退到二线结构或深一米。',
    color: InkPalette.cinnabar,
  ),
];

const _layerTuneOptions = [
  _TuneOption(
    label: '见炸水',
    icon: Icons.bubble_chart_rounded,
    scoreDelta: 9,
    effect: '中上层有捕食信号，先快搜再慢控。',
    color: InkPalette.pine,
  ),
  _TuneOption(
    label: '贴底信号',
    icon: Icons.layers_rounded,
    scoreDelta: 4,
    effect: '鱼在底层或离底，钓法转慢守、拖底或轻逗。',
    color: InkPalette.lake,
  ),
  _TuneOption(
    label: '无信号',
    icon: Icons.visibility_off_rounded,
    scoreDelta: -8,
    effect: '鱼层未知，上中下各试一轮，仍无口就止损。',
    color: InkPalette.cinnabar,
  ),
];

_TuneSelection _defaultTuneSelection(_FishingMockScenario scenario) {
  switch (scenario.id) {
    case 'hot_low':
      return const _TuneSelection(water: 0, wind: 2, crowd: 2, layer: 2);
    case 'rain_muddy':
      return const _TuneSelection(water: 2, wind: 1, crowd: 0, layer: 1);
    case 'night_catfish':
      return const _TuneSelection(water: 1, wind: 1, crowd: 1, layer: 1);
    default:
      return const _TuneSelection(water: 1, wind: 0, crowd: 0, layer: 0);
  }
}

String _buildTuneStance(
  _TuneOption wind,
  _TuneOption crowd,
  _FishingMockScenario scenario,
) {
  if (crowd.label == '拥挤') return '后撤到二线结构，避开脚步声和连续抛投区';
  if (wind.label == '迎风') return '迎风浅滩外沿，优先浪线和饵鱼聚集边';
  if (wind.label == '侧风') return '沿风线扇形搜索，落点从结构边向外展开';
  return '${scenario.spotHint}慢等，必要时深一米或贴阴影';
}

String _buildTuneLayer(_TuneOption layer) {
  if (layer.label == '见炸水') return '中上层先打 10 分钟，有追口再慢控停顿';
  if (layer.label == '贴底信号') return '贴底或离底 20cm，少动、慢拖、轻逗';
  return '鱼层未知，上中下各 8 分钟；无反馈立刻换点';
}

String _buildTuneBait(_TuneOption water, _FishingMockScenario scenario) {
  if (water.label == '清水') return '${scenario.gearShort}改自然色，小轮廓，动作放轻';
  if (water.label == '泥水') return '${scenario.gearShort}加重味、震动或大轮廓，贴近鱼走';
  return '${scenario.gearShort}保留，优先亮色、反光或腥香增强发现率';
}

String _buildTunePace(
  _TuneOption water,
  _TuneOption wind,
  _TuneOption crowd,
  _TuneOption layer,
  int score,
) {
  if (score < 46) return '15 分钟内没有明确反馈就止损，不继续硬守';
  if (crowd.label == '拥挤') return '低频抛投、少补窝，换到安静边再加快';
  if (layer.label == '无信号') return '8 分钟一换层，三层都无口就换点';
  if (wind.label == '背风' || water.label == '清水') {
    return '慢拖、停顿、轻逗，减少惊鱼动作';
  }
  return '10 分钟一轮扇形搜索，有追口再缩小落点';
}

String _buildTuneStopLoss(int score, _TuneOption layer) {
  if (score >= 80) return '30 分钟无有效反馈，换鱼层不换钓点';
  if (score >= 62) return '20 分钟无反馈，先换层，再换结构边';
  if (layer.label == '无信号') return '三层各一轮仍无口，直接换点';
  return '只试一个短窗口，弱口不恋战';
}

void _showGearSheet(BuildContext context, _FishingMockScenario scenario) {
  showInkActionSheet(
    context,
    title: '装备与钓法清单',
    subtitle: scenario.gearDetail,
    icon: Icons.inventory_2_rounded,
    color: InkPalette.reed,
    actions: [
      InkSheetAction(
        icon: Icons.checklist_rounded,
        title: '出发前检查',
        subtitle: scenario.gearChecklist,
        color: InkPalette.pine,
        onTap: () => _showGearChecklistSheet(context, scenario),
      ),
      InkSheetAction(
        icon: Icons.storefront_rounded,
        title: '缺装备去商城',
        subtitle: '按当前钓法筛选竿、线、饵、配件',
        color: InkPalette.reed,
        onTap: () => context.push(AppRouteNames.mall),
      ),
    ],
  );
}

void _showGearChecklistSheet(
  BuildContext context,
  _FishingMockScenario scenario,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (_) => _GearChecklistSheet(scenario: scenario),
  );
}

class _GearChecklistSheet extends StatefulWidget {
  const _GearChecklistSheet({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  State<_GearChecklistSheet> createState() => _GearChecklistSheetState();
}

class _GearChecklistSheetState extends State<_GearChecklistSheet> {
  late final List<_GearCheckItem> _items;
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _items = [
      _GearCheckItem(
        icon: Icons.inventory_2_rounded,
        title: '主装备',
        subtitle: widget.scenario.gearDetail,
        color: widget.scenario.accent,
      ),
      _GearCheckItem(
        icon: Icons.checklist_rounded,
        title: '随身小件',
        subtitle: widget.scenario.gearChecklist,
        color: InkPalette.reed,
      ),
      _GearCheckItem(
        icon: widget.scenario.safetyIcon,
        title: '安全防护',
        subtitle: widget.scenario.safetySubtitle,
        color: widget.scenario.safetyColor,
      ),
      _GearCheckItem(
        icon: Icons.sensors_rounded,
        title: '设备状态',
        subtitle: widget.scenario.deviceSubtitle,
        color: InkPalette.lake,
      ),
    ];
    _checked = List<bool>.filled(_items.length, false);
  }

  int get _done => _checked.where((item) => item).length;

  void _toggle(int index) {
    setState(() => _checked[index] = !_checked[index]);
  }

  void _markAll() {
    setState(() {
      for (var i = 0; i < _checked.length; i++) {
        _checked[i] = true;
      }
    });
  }

  void _save() {
    Navigator.of(context).pop();
    AppFeedback.showMessage(
      context,
      _done == _items.length ? '装备检查完成，可以出发' : '已保存装备检查进度',
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    final progress = _done / _items.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: SizedBox(
          height: height,
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
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
                      icon: Icons.checklist_rounded,
                      color: widget.scenario.accent,
                      size: 42,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '出发前检查',
                            style: TextStyle(
                              color: InkPalette.text,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '${widget.scenario.target} · $_done/${_items.length} 已确认',
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
                      label: '${(progress * 100).round()}%',
                      active: true,
                      color: widget.scenario.accent,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7.h,
                    color: widget.scenario.accent,
                    backgroundColor: InkPalette.line.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      return _GearChecklistRow(
                        item: _items[index],
                        checked: _checked[index],
                        onTap: () => _toggle(index),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: InkPressable(
                        onTap: _markAll,
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
                              '全部勾选',
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
                        label: '保存检查',
                        icon: Icons.done_rounded,
                        color: widget.scenario.accent,
                        onTap: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GearCheckItem {
  const _GearCheckItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _GearChecklistRow extends StatelessWidget {
  const _GearChecklistRow({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final _GearCheckItem item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: checked
          ? item.color.withValues(alpha: 0.09)
          : InkPalette.paper.withValues(alpha: 0.72),
      borderColor: item.color.withValues(alpha: checked ? 0.22 : 0.12),
      onTap: onTap,
      child: Row(
        children: [
          InkIconMark(icon: item.icon, color: item.color, size: 38),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: checked ? item.color : InkPalette.white,
              shape: BoxShape.circle,
              border: Border.all(color: item.color.withValues(alpha: 0.38)),
            ),
            child: checked
                ? Icon(Icons.done_rounded, color: InkPalette.white, size: 17.w)
                : null,
          ),
        ],
      ),
    );
  }
}

void _showSpotDetailSheet(
  BuildContext context,
  _FishingMockScenario scenario,
  _SpotMock spot,
) {
  showInkActionSheet(
    context,
    title: spot.title,
    subtitle: '${spot.distance} · ${spot.tags.join(' / ')} · ${spot.score}分',
    icon: Icons.place_rounded,
    color: scenario.accent,
    showLandscape: true,
    actions: [
      InkSheetAction(
        icon: Icons.near_me_rounded,
        title: '开始导航',
        subtitle: '查看停车点、岸边路线和安全提醒',
        color: scenario.accent,
        onTap: () => context.go(AppRouteNames.explore),
      ),
      InkSheetAction(
        icon: Icons.bookmark_add_rounded,
        title: '收藏钓点',
        subtitle: '同步到我的收藏钓点',
        color: InkPalette.moss,
        onTap: () => AppFeedback.showMessage(context, '${spot.title} 已收藏'),
      ),
    ],
  );
}

void _showNotificationSheet(
  BuildContext context,
  _FishingMockScenario scenario,
) {
  showInkActionSheet(
    context,
    title: '智能提醒',
    subtitle: '${scenario.location} · ${scenario.updateText}',
    icon: Icons.notifications_active_rounded,
    color: scenario.accent,
    actions: [
      InkSheetAction(
        icon: scenario.safetyIcon,
        title: scenario.safetyTitle,
        subtitle: scenario.safetySubtitle,
        color: scenario.safetyColor,
        onTap: () => _showSafetySheet(context, scenario),
      ),
      InkSheetAction(
        icon: Icons.sensors_rounded,
        title: scenario.deviceTitle,
        subtitle: scenario.deviceSubtitle,
        color: scenario.accent,
        onTap: () => _showDeviceSheet(context, scenario),
      ),
    ],
  );
}

void _showSafetySheet(BuildContext context, _FishingMockScenario scenario) {
  showInkActionSheet(
    context,
    title: scenario.safetyTitle,
    subtitle: scenario.safetySubtitle,
    icon: scenario.safetyIcon,
    color: scenario.safetyColor,
    children: [
      InkSafetyAlertCard(
        icon: scenario.safetyIcon,
        title: '${scenario.safetyTitle} · ${scenario.safetyLevel}风险',
        subtitle: scenario.safetySubtitle,
        color: scenario.safetyColor,
        onTap: () => AppFeedback.showMessage(context, '已阅读安全提醒'),
      ),
      SizedBox(height: 10.h),
      Row(
        children: [
          Expanded(
            child: InkMetric(
              value: scenario.safetyLevel,
              label: '风险等级',
              icon: scenario.safetyIcon,
              color: scenario.safetyColor,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(
              value: scenario.bestTime,
              label: '建议窗口',
              icon: Icons.schedule_rounded,
              color: scenario.accent,
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      InkCard(
        padding: EdgeInsets.all(11.r),
        color: InkPalette.white.withValues(alpha: 0.82),
        borderColor: scenario.safetyColor.withValues(alpha: 0.18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SafetyLine(
              icon: Icons.route_rounded,
              title: '路线',
              value: scenario.navigationHint,
              color: scenario.accent,
            ),
            SizedBox(height: 8.h),
            _SafetyLine(
              icon: Icons.block_rounded,
              title: '不要做',
              value: scenario.avoid,
              color: InkPalette.cinnabar,
            ),
            SizedBox(height: 8.h),
            _SafetyLine(
              icon: Icons.place_rounded,
              title: '推荐站位',
              value: scenario.spotHint,
              color: InkPalette.moss,
            ),
          ],
        ),
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.map_rounded,
        title: '查看安全路线',
        subtitle: '跳转钓点地图，优先看停车点和撤离路线',
        color: scenario.accent,
        onTap: () => context.go(AppRouteNames.explore),
      ),
      InkSheetAction(
        icon: Icons.notifications_active_rounded,
        title: '保留提醒',
        subtitle: '到窗口前 30 分钟提醒装备和安全事项',
        color: InkPalette.moss,
        onTap: () => AppFeedback.showMessage(context, '已保留出钓安全提醒'),
      ),
    ],
  );
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16.w),
        SizedBox(width: 7.w),
        SizedBox(
          width: 54.w,
          child: Text(
            title,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.sp,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

void _showDeviceSheet(BuildContext context, _FishingMockScenario scenario) {
  showInkActionSheet(
    context,
    title: scenario.deviceTitle,
    subtitle: scenario.deviceSubtitle,
    icon: Icons.sensors_rounded,
    color: scenario.accent,
    children: [
      Row(
        children: [
          Expanded(
            child: InkMetric(value: scenario.depth, label: '水深'),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(
              value: scenario.waterTemp.replaceAll('水温 ', ''),
              label: '水温',
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkMetric(value: scenario.deviceState, label: '设备'),
          ),
        ],
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.sync_rounded,
        title: '立即同步',
        subtitle: '刷新设备最新水情',
        color: InkPalette.lake,
        onTap: () => _showDeviceSyncSheet(context, scenario),
      ),
      InkSheetAction(
        icon: Icons.settings_input_antenna_rounded,
        title: '设备校准',
        subtitle: '校准水深、水温和信号',
        color: InkPalette.moss,
        onTap: () => _showDeviceCalibrationSheet(context, scenario),
      ),
    ],
  );
}

void _showDeviceSyncSheet(BuildContext context, _FishingMockScenario scenario) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (_) => _DeviceSyncSheet(scenario: scenario),
  );
}

class _DeviceSyncSheet extends StatefulWidget {
  const _DeviceSyncSheet({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  State<_DeviceSyncSheet> createState() => _DeviceSyncSheetState();
}

class _DeviceSyncSheetState extends State<_DeviceSyncSheet> {
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 880), () {
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
                    color: widget.scenario.accent,
                    size: 42,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _syncing ? '正在同步设备' : '设备同步完成',
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          _syncing ? '正在读取水温、水深、电量和信号强度' : '已刷新为最新水情，推荐可继续使用',
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
                    : Row(
                        key: const ValueKey('synced'),
                        children: [
                          Expanded(
                            child: InkMetric(
                              value: widget.scenario.depth,
                              label: '水深',
                              icon: Icons.height_rounded,
                              color: InkPalette.lake,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: InkMetric(
                              value: widget.scenario.waterTemp.replaceAll(
                                '水温 ',
                                '',
                              ),
                              label: '水温',
                              icon: Icons.water_drop_rounded,
                              color: widget.scenario.accent,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: InkMetric(
                              value: widget.scenario.deviceState,
                              label: '状态',
                              icon: Icons.sensors_rounded,
                              color: InkPalette.moss,
                            ),
                          ),
                        ],
                      ),
              ),
              if (!_syncing) ...[
                SizedBox(height: 14.h),
                InkPrimaryButton(
                  label: '完成',
                  icon: Icons.done_rounded,
                  color: widget.scenario.accent,
                  onTap: () {
                    Navigator.of(context).pop();
                    AppFeedback.showMessage(context, '设备水情已同步');
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

void _showDeviceCalibrationSheet(
  BuildContext context,
  _FishingMockScenario scenario,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (_) => _DeviceCalibrationSheet(scenario: scenario),
  );
}

class _DeviceCalibrationSheet extends StatefulWidget {
  const _DeviceCalibrationSheet({required this.scenario});

  final _FishingMockScenario scenario;

  @override
  State<_DeviceCalibrationSheet> createState() =>
      _DeviceCalibrationSheetState();
}

class _DeviceCalibrationSheetState extends State<_DeviceCalibrationSheet> {
  double _depthOffset = 0;
  double _tempOffset = 0;
  double _signalLevel = 82;

  void _save() {
    Navigator.of(context).pop();
    AppFeedback.showMessage(context, '设备校准参数已保存');
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
                    icon: Icons.settings_input_antenna_rounded,
                    color: InkPalette.moss,
                    size: 42,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '设备校准',
                          style: TextStyle(
                            color: InkPalette.text,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          '${widget.scenario.deviceTitle} · ${widget.scenario.deviceState}',
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
                ],
              ),
              SizedBox(height: 14.h),
              _CalibrationSlider(
                label: '水深修正',
                value: _depthOffset,
                min: -0.5,
                max: 0.5,
                unit: 'm',
                color: InkPalette.lake,
                onChanged: (value) => setState(() => _depthOffset = value),
              ),
              SizedBox(height: 10.h),
              _CalibrationSlider(
                label: '水温修正',
                value: _tempOffset,
                min: -2,
                max: 2,
                unit: '°C',
                color: widget.scenario.accent,
                onChanged: (value) => setState(() => _tempOffset = value),
              ),
              SizedBox(height: 10.h),
              _CalibrationSlider(
                label: '信号阈值',
                value: _signalLevel,
                min: 40,
                max: 100,
                unit: '%',
                color: InkPalette.moss,
                onChanged: (value) => setState(() => _signalLevel = value),
              ),
              SizedBox(height: 14.h),
              InkPrimaryButton(
                label: '保存校准',
                icon: Icons.done_rounded,
                color: InkPalette.moss,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationSlider extends StatelessWidget {
  const _CalibrationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final signed = value > 0
        ? '+${value.toStringAsFixed(1)}'
        : value.toStringAsFixed(1);

    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.paper.withValues(alpha: 0.72),
      borderColor: color.withValues(alpha: 0.14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$signed$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: InkPalette.line.withValues(alpha: 0.65),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FishingMockScenario {
  const _FishingMockScenario({
    required this.id,
    required this.railLabel,
    required this.railIcon,
    required this.location,
    required this.updateText,
    required this.alertBadge,
    required this.heroAsset,
    required this.heroAlignment,
    required this.weather,
    required this.weatherIcon,
    required this.waterTemp,
    required this.depth,
    required this.score,
    required this.scoreLabel,
    required this.conclusion,
    required this.target,
    required this.summary,
    required this.bestTime,
    required this.spotHint,
    required this.avoid,
    required this.primaryAction,
    required this.navigationHint,
    required this.planTitle,
    required this.planSubtitle,
    required this.modeLabel,
    required this.confidence,
    required this.dataSource,
    required this.gearShort,
    required this.gearDetail,
    required this.gearChecklist,
    required this.deviceTitle,
    required this.deviceSubtitle,
    required this.deviceState,
    required this.safetyIcon,
    required this.safetyTitle,
    required this.safetySubtitle,
    required this.safetyLevel,
    required this.safetyColor,
    required this.accent,
    required this.steps,
    required this.evidence,
    required this.fishMethods,
    required this.spots,
  });

  final String id;
  final String railLabel;
  final IconData railIcon;
  final String location;
  final String updateText;
  final String alertBadge;
  final String heroAsset;
  final Alignment heroAlignment;
  final String weather;
  final IconData weatherIcon;
  final String waterTemp;
  final String depth;
  final int score;
  final String scoreLabel;
  final String conclusion;
  final String target;
  final String summary;
  final String bestTime;
  final String spotHint;
  final String avoid;
  final String primaryAction;
  final String navigationHint;
  final String planTitle;
  final String planSubtitle;
  final String modeLabel;
  final String confidence;
  final String dataSource;
  final String gearShort;
  final String gearDetail;
  final String gearChecklist;
  final String deviceTitle;
  final String deviceSubtitle;
  final String deviceState;
  final IconData safetyIcon;
  final String safetyTitle;
  final String safetySubtitle;
  final String safetyLevel;
  final Color safetyColor;
  final Color accent;
  final List<_PlanStep> steps;
  final List<_EvidenceItem> evidence;
  final List<_FishMethod> fishMethods;
  final List<_SpotMock> spots;
}

class _PlanStep {
  const _PlanStep({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color color;
}

class _EvidenceItem {
  const _EvidenceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
}

class _FishMethod {
  const _FishMethod({
    required this.fish,
    required this.method,
    required this.probability,
    required this.advice,
    required this.color,
  });

  final String fish;
  final String method;
  final int probability;
  final String advice;
  final Color color;
}

class _SpotMock {
  const _SpotMock({
    required this.title,
    required this.distance,
    required this.tags,
    required this.score,
  });

  final String title;
  final String distance;
  final List<String> tags;
  final int score;
}

class _CoreAction {
  const _CoreAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.metric,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final String metric;
  final Color color;
  final VoidCallback onTap;
}

const _mockScenarios = [
  _FishingMockScenario(
    id: 'sunrise_lure',
    railLabel: '晴晨高分',
    railIcon: Icons.wb_sunny_rounded,
    location: '千岛湖 · 东南湖区',
    updateText: '实时鱼情 · 9 分钟前更新',
    alertBadge: '2',
    heroAsset: InkAssets.fishingMap,
    heroAlignment: Alignment.center,
    weather: '多云 23°C',
    weatherIcon: Icons.wb_sunny_rounded,
    waterTemp: '水温 18.6°C',
    depth: '1.8m',
    score: 87,
    scoreLabel: '宜钓',
    conclusion: '今天适合出钓',
    target: '路亚翘嘴',
    summary: '早晚窗口明显，先扫浅滩外沿，再转桥墩阴影；20 分钟无追口就换鱼层。',
    bestTime: '05:30-08:30',
    spotHint: '背风浅滩',
    avoid: '中午守鲤',
    primaryAction: '导航到钓点',
    navigationHint: '3.2km · 18分钟',
    planTitle: '三步打法',
    planSubtitle: '照着做，少走弯路',
    modeLabel: '新手模式',
    confidence: '86%',
    dataSource: '天气 + 水情 + 近7天鱼获',
    gearShort: '亮片 / 米诺',
    gearDetail: 'ML 路亚竿、0.8 PE、10g 银色亮片、浅潜米诺。',
    gearChecklist: '偏光镜、控鱼钳、备用亮片、救生装备。',
    deviceTitle: '智能浮漂 FC-01',
    deviceSubtitle: '在线 · 数据每 20 秒同步 · 电量 78%',
    deviceState: '在线',
    safetyIcon: Icons.verified_user_rounded,
    safetyTitle: '安全风险低',
    safetySubtitle: '风浪小，岸边湿滑点较少，仍建议穿防滑鞋。',
    safetyLevel: '低',
    safetyColor: InkPalette.moss,
    accent: InkPalette.pine,
    steps: [
      _PlanStep(
        title: '先找结构',
        subtitle: '浅滩外沿、桥墩阴影、水草边',
        badge: '10分钟',
        color: InkPalette.pine,
      ),
      _PlanStep(
        title: '亮片快搜',
        subtitle: '有追口再换米诺慢控',
        badge: '20分钟',
        color: InkPalette.lake,
      ),
      _PlanStep(
        title: '无口即换层',
        subtitle: '中上层转 2-3 米水深',
        badge: '别死守',
        color: InkPalette.cinnabar,
      ),
    ],
    evidence: [
      _EvidenceItem(
        icon: Icons.air_rounded,
        title: '2 级微风，适合搜索',
        subtitle: '有风纹，浅滩外沿更容易聚鱼',
        trailing: '+8',
        color: InkPalette.pine,
      ),
      _EvidenceItem(
        icon: Icons.water_drop_rounded,
        title: '水色微浑，亮色更醒目',
        subtitle: '优先银色亮片，弱口再换米诺',
        trailing: '+6',
        color: InkPalette.lake,
      ),
      _EvidenceItem(
        icon: Icons.history_rounded,
        title: '近 7 天翘嘴活跃',
        subtitle: '同类水域早晚窗口命中率更高',
        trailing: '+11',
        color: InkPalette.moss,
      ),
    ],
    fishMethods: [
      _FishMethod(
        fish: '翘嘴',
        method: '路亚',
        probability: 95,
        advice: '主攻，先快搜后慢控',
        color: InkPalette.pine,
      ),
      _FishMethod(
        fish: '鲈鱼',
        method: '路亚',
        probability: 85,
        advice: '桥墩阴影慢抽停顿',
        color: InkPalette.lake,
      ),
      _FishMethod(
        fish: '鲫鱼',
        method: '台钓',
        probability: 67,
        advice: '草边小窝，傍晚更稳',
        color: InkPalette.reed,
      ),
      _FishMethod(
        fish: '鲤鱼',
        method: '守钓',
        probability: 18,
        advice: '不建议死守，可做挑战',
        color: InkPalette.cinnabar,
      ),
    ],
    spots: [
      _SpotMock(
        title: '东南湖区 · 背风浅滩',
        distance: '3.2km',
        tags: ['路亚', '浅滩', '早口'],
        score: 90,
      ),
      _SpotMock(
        title: '石桥湾 · 桥墩阴影',
        distance: '4.8km',
        tags: ['结构', '翘嘴', '停车近'],
        score: 84,
      ),
    ],
  ),
  _FishingMockScenario(
    id: 'hot_low',
    railLabel: '午后低分',
    railIcon: Icons.thermostat_rounded,
    location: '湘湖 · 下孙水域',
    updateText: '午后闷热 · 建议改晚口',
    alertBadge: '1',
    heroAsset: InkAssets.homeLakeHero,
    heroAlignment: Alignment.centerRight,
    weather: '晴热 31°C',
    weatherIcon: Icons.wb_sunny_rounded,
    waterTemp: '水温 25.4°C',
    depth: '1.2m',
    score: 42,
    scoreLabel: '慎钓',
    conclusion: '中午不建议硬钓',
    target: '傍晚鲫鱼',
    summary: '气压优势不足，近岸人流偏多。建议把出发时间后移，傍晚草边小窝更稳。',
    bestTime: '17:40-19:10',
    spotHint: '阴影草边',
    avoid: '正午长守',
    primaryAction: '改晚口路线',
    navigationHint: '先收藏，晚点去',
    planTitle: '低分替代方案',
    planSubtitle: '不硬上，改窗口',
    modeLabel: '避坑模式',
    confidence: '79%',
    dataSource: '天气 + 人流 + 历史空军率',
    gearShort: '短竿 / 拉饵',
    gearDetail: '3.6m 轻量竿、细线小钩、腥香拉饵、少量打窝。',
    gearChecklist: '遮阳、防暑水、夜钓灯、驱蚊用品。',
    deviceTitle: '设备未连接',
    deviceSubtitle: '使用天气与历史数据估算，建议到点后补水深。',
    deviceState: '离线',
    safetyIcon: Icons.local_drink_rounded,
    safetyTitle: '高温提醒',
    safetySubtitle: '午后体感偏热，建议避开 12:00-16:30。',
    safetyLevel: '中',
    safetyColor: InkPalette.cinnabar,
    accent: InkPalette.cinnabar,
    steps: [
      _PlanStep(
        title: '先不出发',
        subtitle: '午后高温，鱼口和体感都不划算',
        badge: '避开',
        color: InkPalette.cinnabar,
      ),
      _PlanStep(
        title: '傍晚打小窝',
        subtitle: '草边阴影，少量勤补',
        badge: '17:40',
        color: InkPalette.reed,
      ),
      _PlanStep(
        title: '只试一小时',
        subtitle: '无口就收，不拖到深夜',
        badge: '止损',
        color: InkPalette.lake,
      ),
    ],
    evidence: [
      _EvidenceItem(
        icon: Icons.compress_rounded,
        title: '气压优势不足',
        subtitle: '午后闷热，开口时间容易后移',
        trailing: '-12',
        color: InkPalette.cinnabar,
      ),
      _EvidenceItem(
        icon: Icons.groups_rounded,
        title: '近岸人流偏多',
        subtitle: '休闲水域干扰高，鱼不贴边',
        trailing: '-8',
        color: InkPalette.reed,
      ),
      _EvidenceItem(
        icon: Icons.nights_stay_rounded,
        title: '晚口仍有机会',
        subtitle: '阴影草边小鲫鱼稳定性更好',
        trailing: '+6',
        color: InkPalette.moss,
      ),
    ],
    fishMethods: [
      _FishMethod(
        fish: '鲫鱼',
        method: '台钓',
        probability: 58,
        advice: '傍晚草边小窝可试',
        color: InkPalette.reed,
      ),
      _FishMethod(
        fish: '白条',
        method: '飞铅',
        probability: 52,
        advice: '有口但目标价值偏低',
        color: InkPalette.lake,
      ),
      _FishMethod(
        fish: '鲤鱼',
        method: '守钓',
        probability: 24,
        advice: '正午不建议死守',
        color: InkPalette.cinnabar,
      ),
      _FishMethod(
        fish: '翘嘴',
        method: '路亚',
        probability: 31,
        advice: '等晚风起再短搜',
        color: InkPalette.moss,
      ),
    ],
    spots: [
      _SpotMock(
        title: '下孙水域 · 柳树阴影',
        distance: '5.6km',
        tags: ['阴影', '鲫鱼', '晚口'],
        score: 62,
      ),
      _SpotMock(
        title: '湘湖支流 · 缓流水草',
        distance: '6.4km',
        tags: ['草边', '短竿', '少人'],
        score: 57,
      ),
    ],
  ),
  _FishingMockScenario(
    id: 'rain_muddy',
    railLabel: '雨后浑水',
    railIcon: Icons.water_drop_rounded,
    location: '钱塘江支流 · 回水湾',
    updateText: '雨后 40 分钟 · 水色偏浑',
    alertBadge: '3',
    heroAsset: InkAssets.fishingMap,
    heroAlignment: Alignment.centerLeft,
    weather: '小雨后 21°C',
    weatherIcon: Icons.cloudy_snowing,
    waterTemp: '水温 20.1°C',
    depth: '2.4m',
    score: 68,
    scoreLabel: '可试',
    conclusion: '雨后可短打',
    target: '近岸鲫鲤',
    summary: '浑水降低视觉警惕，但涨水边线风险上升。只打近岸缓流，别涉水远投。',
    bestTime: '16:20-19:00',
    spotHint: '回水缓流',
    avoid: '涉水远投',
    primaryAction: '看安全路线',
    navigationHint: '2.1km · 绕开湿岸',
    planTitle: '雨后短打策略',
    planSubtitle: '有机会，但先看安全',
    modeLabel: '稳妥模式',
    confidence: '82%',
    dataSource: '降雨 + 水位 + 结构点',
    gearShort: '腥饵 / 重味窝',
    gearDetail: '4.5m 手竿、稍大号线组、腥香饵、少量重味窝料。',
    gearChecklist: '防滑鞋、雨衣、防水包、备用毛巾。',
    deviceTitle: '水位传感器提示',
    deviceSubtitle: '水位 30 分钟上涨 0.18m，近岸泥滑。',
    deviceState: '预警',
    safetyIcon: Icons.warning_amber_rounded,
    safetyTitle: '涨水与湿滑',
    safetySubtitle: '不要站在低洼石板和陡坡边，优先平台位。',
    safetyLevel: '高',
    safetyColor: InkPalette.cinnabar,
    accent: InkPalette.lake,
    steps: [
      _PlanStep(
        title: '先看水线',
        subtitle: '只选平台位和缓坡位',
        badge: '安全',
        color: InkPalette.cinnabar,
      ),
      _PlanStep(
        title: '近岸慢守',
        subtitle: '回水湾内侧，重味小窝',
        badge: '30分钟',
        color: InkPalette.lake,
      ),
      _PlanStep(
        title: '水位再涨就撤',
        subtitle: '不等口，不涉水',
        badge: '撤离',
        color: InkPalette.pine,
      ),
    ],
    evidence: [
      _EvidenceItem(
        icon: Icons.water_rounded,
        title: '雨后水色偏浑',
        subtitle: '近岸鱼警惕下降，味型要更明确',
        trailing: '+7',
        color: InkPalette.lake,
      ),
      _EvidenceItem(
        icon: Icons.trending_up_rounded,
        title: '水位仍在上涨',
        subtitle: '鱼靠边，但安全边界更重要',
        trailing: '-9',
        color: InkPalette.cinnabar,
      ),
      _EvidenceItem(
        icon: Icons.alt_route_rounded,
        title: '回水结构有效',
        subtitle: '缓流处更容易留鱼和聚饵',
        trailing: '+8',
        color: InkPalette.moss,
      ),
    ],
    fishMethods: [
      _FishMethod(
        fish: '鲫鱼',
        method: '腥饵台钓',
        probability: 72,
        advice: '近岸缓流，少量重味窝',
        color: InkPalette.lake,
      ),
      _FishMethod(
        fish: '鲤鱼',
        method: '短守',
        probability: 61,
        advice: '只守平台边，不涉水',
        color: InkPalette.reed,
      ),
      _FishMethod(
        fish: '翘嘴',
        method: '路亚',
        probability: 34,
        advice: '水浑不适合主攻',
        color: InkPalette.cinnabar,
      ),
      _FishMethod(
        fish: '黄颡',
        method: '夜钓',
        probability: 55,
        advice: '天黑后可短试',
        color: InkPalette.moss,
      ),
    ],
    spots: [
      _SpotMock(
        title: '支流回水湾 · 平台位',
        distance: '2.1km',
        tags: ['回水', '平台', '安全'],
        score: 76,
      ),
      _SpotMock(
        title: '老桥内侧 · 缓流边',
        distance: '3.7km',
        tags: ['桥下', '浑水', '鲫鲤'],
        score: 69,
      ),
    ],
  ),
  _FishingMockScenario(
    id: 'night_catfish',
    railLabel: '夜钓窗口',
    railIcon: Icons.nights_stay_rounded,
    location: '城市河道 · 老码头',
    updateText: '夜钓模式 · 20:30 开窗',
    alertBadge: '2',
    heroAsset: InkAssets.homeLakeHero,
    heroAlignment: Alignment.center,
    weather: '阴 24°C',
    weatherIcon: Icons.nights_stay_rounded,
    waterTemp: '水温 22.8°C',
    depth: '2.0m',
    score: 76,
    scoreLabel: '可钓',
    conclusion: '夜钓窗口可用',
    target: '鲶鱼 / 大鲫',
    summary: '灯光边界和桥下阴影有机会。夜钓优先安全与同行，别单人下偏僻岸线。',
    bestTime: '20:30-23:10',
    spotHint: '灯影交界',
    avoid: '单人夜钓',
    primaryAction: '约伴导航',
    navigationHint: '4.1km · 有路灯',
    planTitle: '夜钓安全打法',
    planSubtitle: '先安全，再追口',
    modeLabel: '夜钓模式',
    confidence: '80%',
    dataSource: '夜间鱼获 + 灯光点 + 安全标签',
    gearShort: '夜灯 / 蚯蚓',
    gearDetail: '夜钓灯、头灯、蚯蚓或腥饵、长柄抄网、反光装备。',
    gearChecklist: '头灯电量、同行钓友、驱蚊、防滑鞋、充电宝。',
    deviceTitle: '夜钓安全监测',
    deviceSubtitle: '设备在线 · 位置共享已建议开启。',
    deviceState: '建议',
    safetyIcon: Icons.group_add_rounded,
    safetyTitle: '建议结伴',
    safetySubtitle: '目标点有路灯，但岸边台阶湿滑，不建议单人夜钓。',
    safetyLevel: '中',
    safetyColor: InkPalette.reed,
    accent: InkPalette.moss,
    steps: [
      _PlanStep(
        title: '先选亮暗交界',
        subtitle: '路灯边、桥下阴影外沿',
        badge: '开局',
        color: InkPalette.moss,
      ),
      _PlanStep(
        title: '腥饵慢守',
        subtitle: '小走水处守底，别频繁抬竿',
        badge: '40分钟',
        color: InkPalette.lake,
      ),
      _PlanStep(
        title: '开共享位置',
        subtitle: '约伴、带头灯、23点前收',
        badge: '安全',
        color: InkPalette.reed,
      ),
    ],
    evidence: [
      _EvidenceItem(
        icon: Icons.light_mode_rounded,
        title: '灯影边界明显',
        subtitle: '小鱼聚光，大鱼常在暗侧等口',
        trailing: '+9',
        color: InkPalette.moss,
      ),
      _EvidenceItem(
        icon: Icons.history_rounded,
        title: '近 3 晚有大鲫记录',
        subtitle: '20:30 后口更集中',
        trailing: '+8',
        color: InkPalette.lake,
      ),
      _EvidenceItem(
        icon: Icons.security_rounded,
        title: '夜间安全扣分',
        subtitle: '台阶湿滑，需结伴和照明',
        trailing: '-7',
        color: InkPalette.reed,
      ),
    ],
    fishMethods: [
      _FishMethod(
        fish: '鲶鱼',
        method: '蚯蚓守底',
        probability: 78,
        advice: '桥下阴影，慢守小走水',
        color: InkPalette.moss,
      ),
      _FishMethod(
        fish: '鲫鱼',
        method: '腥饵夜钓',
        probability: 73,
        advice: '灯影交界，轻口要稳',
        color: InkPalette.lake,
      ),
      _FishMethod(
        fish: '鲤鱼',
        method: '短守',
        probability: 46,
        advice: '可以兼顾，不主攻',
        color: InkPalette.reed,
      ),
      _FishMethod(
        fish: '翘嘴',
        method: '小亮片',
        probability: 39,
        advice: '有炸水再短搜',
        color: InkPalette.cinnabar,
      ),
    ],
    spots: [
      _SpotMock(
        title: '老码头 · 路灯边界',
        distance: '4.1km',
        tags: ['夜钓', '有灯', '鲶鱼'],
        score: 82,
      ),
      _SpotMock(
        title: '二号桥 · 阴影外沿',
        distance: '4.9km',
        tags: ['桥下', '大鲫', '结伴'],
        score: 75,
      ),
    ],
  ),
];
