import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/domain/app_domain_models.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/home/providers/iot_device_provider.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final statsState = ref.watch(userStatsProvider);
    final devices = ref.watch(iotDevicesProvider);
    const profileUser = ProfileMockData.user;
    final userError = userState.maybeWhen(
      error: (error, _) => error,
      orElse: () => null,
    );
    final statsError = statsState.maybeWhen(
      error: (error, _) => error,
      orElse: () => null,
    );
    final isLoggedIn =
        AuthSession.isLoggedIn && !_isUnauthorizedProfileError(userError);
    final visibleDevices = isLoggedIn ? devices : const <IotDeviceState>[];
    final devicesSummary = ProfileDevicesSummary.fromDevices(visibleDevices);
    final isLoading =
        isLoggedIn && (userState.isLoading || statsState.isLoading);
    final hasNetworkError =
        isLoggedIn &&
        (_isProfileNetworkError(userError) ||
            _isProfileNetworkError(statsError));
    final member = isLoggedIn
        ? profileUser.member
        : ProfileMockData.inactiveMember;
    final user = userState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final stats = statsState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    return InkPage(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 92.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InkTopBar(title: '我的', subtitle: '用户资产 · 智能装备 · 订单服务'),
            if (!isLoggedIn)
              _ProfileContentPadding(
                motionIndex: 0,
                top: 8,
                child: LoginPrompt(
                  onLogin: () => _goProfileRoute(context, AppRouteNames.login),
                ),
              ),
            if (isLoading)
              _ProfileContentPadding(
                motionIndex: 1,
                top: 8,
                child: LoadingSkeleton(
                  title: '正在同步资产中心',
                  message: '正在加载会员权益、智能装备、订单和作钓数据。',
                  primaryLabel: '刷新状态',
                  onPrimary: () => _refreshProfile(ref),
                ),
              ),
            if (hasNetworkError)
              _ProfileContentPadding(
                motionIndex: 1,
                top: 8,
                child: ProfileStateCard(
                  icon: Icons.wifi_off_rounded,
                  title: '网络错误，资料同步失败',
                  message: '当前无法同步云端资料，已保留本地预览内容。',
                  color: InkPalette.reed,
                  primaryLabel: '重新加载',
                  onPrimary: () => _refreshProfile(ref),
                  secondaryLabel: '稍后再试',
                  onSecondary: () =>
                      AppFeedback.showMessage(context, '可以稍后再刷新资料'),
                ),
              ),
            _ProfileContentPadding(
              motionIndex: 2,
              top: 5,
              child: ProfileHeader(
                nickname: isLoggedIn ? user?.nickname ?? '江湖钓客' : '未登录用户',
                identityText: isLoggedIn
                    ? 'ID ${user?.phone ?? '13800000000'} · 智能作钓档案'
                    : '登录后同步云端智能作钓档案',
                avatarUrl: isLoggedIn ? user?.avatarUrl : null,
                memberLevel: isLoggedIn
                    ? user?.levelTag ?? profileUser.level
                    : '待登录',
                tags: isLoggedIn
                    ? [
                        ...?user?.interests,
                        if (userState.isLoading) '资料同步中',
                        if (userState.hasError) '离线资料',
                        '信用 92',
                      ]
                    : ['登录同步', '装备资产', '会员权益'],
                creditValue: isLoggedIn ? '92' : '--',
                profileProgress: isLoggedIn ? '72%' : '--',
                membershipValue: member.status == ProfileMemberStatus.active
                    ? 'Pro'
                    : member.status == ProfileMemberStatus.expired
                    ? '过期'
                    : '未开通',
                onEdit: () => isLoggedIn
                    ? _showProfileEditSheet(context)
                    : _goProfileRoute(context, AppRouteNames.login),
              ),
            ),
            _ProfileSectionHeader(
              title: '智能装备',
              subtitle: '只看当前状态',
              action: '管理',
              onAction: () => _showDeviceServiceSheet(context, visibleDevices),
            ),
            _ProfileContentPadding(
              motionIndex: 4,
              top: 0,
              child: MyDeviceSummaryCard(
                devices: visibleDevices,
                summary: devicesSummary,
                onSync: () {
                  ref.read(iotDevicesProvider.notifier).syncSnapshot();
                  AppFeedback.showMessage(context, '智能装备状态已同步');
                },
                onManage: () =>
                    _showDeviceServiceSheet(context, visibleDevices),
              ),
            ),
            _ProfileSectionHeader(
              title: '作钓数据',
              subtitle: '鱼获、钓点和活跃天数',
              action: '报告',
              onAction: () => _showFishingAssetSheet(
                context,
                ProfileMockData.fishingStats.entries[1],
              ),
            ),
            _ProfileContentPadding(
              motionIndex: 8,
              top: 0,
              child: FishingAssetSection(
                totalFish: stats?.totalFish ?? 256,
                spotsExplored: stats?.spotsExplored ?? 68,
                daysActive: stats?.daysActive ?? 128,
                isLoading: statsState.isLoading,
                hasError: statsState.hasError,
                isEmpty: !isLoggedIn,
                onRefresh: () => _refreshProfile(ref),
                onAssetTap: (item) => _showFishingAssetSheet(context, item),
              ),
            ),
            _ProfileContentPadding(
              motionIndex: 9,
              top: 10,
              child: _ProfileServiceDock(
                member: member,
                onAll: () => _showProfileMoreSheet(context, member),
                onMember: () => _showMembershipSheet(context, member),
                onOrder: () => _showOrderSheet(
                  context,
                  ProfileMockData.ordersSummary.entries.first,
                ),
                onReservation: () => _showReservationSheet(
                  context,
                  ProfileMockData.appointments.entries.first,
                ),
                onWallet: () => _showWalletSheet(
                  context,
                  ProfileMockData.coupons.entries.first,
                ),
                onSupport: () => _showSupportSheet(
                  context,
                  ProfileMockData.deviceServices.last,
                ),
              ),
            ),
            _ProfileContentPadding(
              motionIndex: 10,
              top: 10,
              child: SettingsEntry(
                onTap: () => _pushProfileRoute(context, AppRouteNames.settings),
              ),
            ),
            if (isLoggedIn)
              _ProfileContentPadding(
                motionIndex: 11,
                top: 10,
                child: InkSecondaryButton(
                  label: '退出登录',
                  icon: Icons.logout_rounded,
                  color: InkPalette.cinnabar,
                  onTap: () async {
                    await ref.read(authRepositoryProvider).logout();
                    if (context.mounted) {
                      _goProfileRoute(context, AppRouteNames.login);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showProfileMoreSheet(BuildContext context, ProfileMemberState member) {
  showInkActionSheet(
    context,
    title: '更多',
    subtitle: '订单 / 预约 / 钱包 / 售后',
    icon: Icons.account_balance_wallet_rounded,
    color: InkPalette.lake,
    actions: [
      InkSheetAction(
        icon: Icons.workspace_premium_rounded,
        title: '会员权益',
        subtitle: member.summary,
        color: InkPalette.reed,
        onTap: () => _showMembershipSheet(context, member),
      ),
      InkSheetAction(
        icon: Icons.receipt_long_rounded,
        title: '我的订单',
        subtitle: '查看待付款、发货和售后状态',
        color: InkPalette.pine,
        onTap: () => _showOrderSheet(
          context,
          ProfileMockData.ordersSummary.entries.first,
        ),
      ),
      InkSheetAction(
        icon: Icons.event_available_rounded,
        title: '钓场预约',
        subtitle: '查看预约、活动和收藏钓点',
        color: InkPalette.moss,
        onTap: () => _showReservationSheet(
          context,
          ProfileMockData.appointments.entries.first,
        ),
      ),
      InkSheetAction(
        icon: Icons.confirmation_number_rounded,
        title: '优惠券与积分',
        subtitle: '查看优惠券、积分和收藏',
        color: InkPalette.reed,
        onTap: () =>
            _showWalletSheet(context, ProfileMockData.coupons.entries.first),
      ),
      InkSheetAction(
        icon: Icons.support_agent_rounded,
        title: '设备售后',
        subtitle: '保修、维修、固件和配件服务',
        color: InkPalette.lake,
        onTap: () =>
            _showSupportSheet(context, ProfileMockData.deviceServices.last),
      ),
    ],
  );
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.nickname,
    required this.identityText,
    required this.avatarUrl,
    required this.memberLevel,
    required this.tags,
    required this.creditValue,
    required this.profileProgress,
    required this.membershipValue,
    required this.onEdit,
  });

  final String nickname;
  final String identityText;
  final String? avatarUrl;
  final String memberLevel;
  final List<String> tags;
  final String creditValue;
  final String profileProgress;
  final String membershipValue;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: InkPalette.white.withValues(alpha: 0.97),
      borderColor: InkPalette.lake.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(avatarUrl: avatarUrl),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: InkPalette.text,
                              fontSize: 19.sp,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        InkChip(
                          label: memberLevel,
                          active: true,
                          color: InkPalette.pine,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      identityText,
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
                      spacing: 6.w,
                      runSpacing: 5.h,
                      children: [
                        for (final tag in tags.take(3))
                          _ProfileTag(label: tag, color: _tagColor(tag)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  value: creditValue,
                  label: '信用分',
                  icon: Icons.verified_rounded,
                  color: InkPalette.moss,
                ),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: _HeaderMetric(
                  value: profileProgress,
                  label: '档案完整度',
                  icon: Icons.assignment_turned_in_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: _HeaderMetric(
                  value: membershipValue,
                  label: '会员权益',
                  icon: Icons.workspace_premium_rounded,
                  color: InkPalette.pine,
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          InkSecondaryButton(
            label: '编辑资料',
            icon: Icons.edit_rounded,
            color: InkPalette.lake,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.member,
    required this.onOpen,
    required this.onBenefit,
  });

  final ProfileMemberState member;
  final VoidCallback onOpen;
  final VoidCallback onBenefit;

  @override
  Widget build(BuildContext context) {
    final isActive = member.status == ProfileMemberStatus.active;
    final isExpired = member.status == ProfileMemberStatus.expired;
    final badge = switch (member.status) {
      ProfileMemberStatus.inactive => '未开通',
      ProfileMemberStatus.active => '已开通',
      ProfileMemberStatus.expired => '已过期',
    };
    final title = isActive ? member.name : '江湖钓客 Pro';
    final subtitle = switch (member.status) {
      ProfileMemberStatus.inactive => '开启 Pro，解锁更完整的智能作钓体验',
      ProfileMemberStatus.active =>
        '到期时间 ${member.expireAt} · ${member.summary}',
      ProfileMemberStatus.expired => '会员已过期，续费后恢复智能作钓权益',
    };
    final primaryLabel = switch (member.status) {
      ProfileMemberStatus.inactive => '立即开通',
      ProfileMemberStatus.active => '查看权益',
      ProfileMemberStatus.expired => '立即续费',
    };
    final secondaryLabel = isActive ? '续费' : '权益说明';
    final badgeColor = isExpired ? InkPalette.reed : InkPalette.moss;

    return InkPressable(
      onTap: onBenefit,
      pressedScale: 0.985,
      rippleColor: InkPalette.reed,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF0F766E), Color(0xFF2563EB)],
          ),
          boxShadow: [
            BoxShadow(
              color: InkPalette.pine.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: Offset(0, 12.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: InkPalette.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: InkPalette.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: InkPalette.reed,
                    size: 21.w,
                  ),
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
                          color: InkPalette.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.white.withValues(alpha: 0.74),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _WhitePill(label: badge, color: badgeColor),
              ],
            ),
            if (isActive) ...[
              SizedBox(height: 9.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: InkPalette.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: InkPalette.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: InkPalette.moss,
                      size: 17.w,
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        '当前权益：高级报告、多设备、90 天历史、专属客服',
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
            ],
            SizedBox(height: 9.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ProfileMockData.proBenefits.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 7.h,
                crossAxisSpacing: 7.w,
                childAspectRatio: 3.7,
              ),
              itemBuilder: (context, index) {
                final benefit = ProfileMockData.proBenefits[index];
                return _ProBenefitTile(benefit: benefit);
              },
            ),
            SizedBox(height: 10.h),
            if (!isActive)
              UpgradePrompt(
                title: isExpired ? '江湖钓客 Pro 已过期' : '未开通江湖钓客 Pro',
                message: subtitle,
                icon: isExpired
                    ? Icons.event_busy_rounded
                    : Icons.workspace_premium_rounded,
                primaryLabel: primaryLabel,
                onPrimary: onOpen,
                secondaryLabel: secondaryLabel,
                onSecondary: onBenefit,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: InkPrimaryButton(
                      label: primaryLabel,
                      icon: Icons.bolt_rounded,
                      color: InkPalette.reed,
                      onTap: onBenefit,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: InkSecondaryButton(
                      label: secondaryLabel,
                      icon: Icons.receipt_long_rounded,
                      color: InkPalette.lake,
                      onTap: onOpen,
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

class MyDeviceSummaryCard extends StatelessWidget {
  const MyDeviceSummaryCard({
    super.key,
    required this.devices,
    required this.summary,
    required this.onSync,
    required this.onManage,
  });

  final List<IotDeviceState> devices;
  final ProfileDevicesSummary summary;
  final VoidCallback onSync;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final core = summary.coreDevice;
    final deviceTypes = devices
        .where(_isCoreDevice)
        .map((item) => item.type)
        .toSet()
        .toList(growable: false);

    return InkCard(
      padding: EdgeInsets.zero,
      borderColor: summary.abnormal > 0 || summary.lowBattery > 0
          ? InkPalette.reed.withValues(alpha: 0.24)
          : InkPalette.lake.withValues(alpha: 0.18),
      onTap: onManage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  InkPalette.lake.withValues(alpha: 0.14),
                  InkPalette.pine.withValues(alpha: 0.08),
                  InkPalette.white.withValues(alpha: 0.96),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TechIcon(
                  icon: Icons.settings_input_antenna_rounded,
                  color: InkPalette.lake,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的智能装备',
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${summary.total} 台设备｜${summary.online} 台在线｜${summary.lowBattery} 台低电量',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InkPalette.muted,
                          fontSize: 11.2.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: InkPalette.lake,
                            size: 14.w,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '最近同步：${summary.lastSyncAt}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: InkPalette.lake,
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
                SizedBox(width: 7.w),
                _StatusCapsule(
                  label: summary.abnormal > 0 ? '${summary.abnormal} 异常' : '稳定',
                  color: summary.abnormal > 0
                      ? InkPalette.reed
                      : InkPalette.moss,
                ),
              ],
            ),
          ),
          if (summary.total == 0)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
              child: ProfileStateCard(
                icon: Icons.add_link_rounded,
                title: '还没有绑定智能装备',
                message: '绑定智能装备，开启完整作钓体验',
                color: InkPalette.lake,
                primaryLabel: '立即绑定设备',
                onPrimary: onManage,
                secondaryLabel: '查看支持设备',
                onSecondary: onManage,
              ),
            )
          else ...[
            if (summary.abnormal > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                child: _SubtleEmphasis(
                  color: InkPalette.reed,
                  child: ProfileStateCard(
                    icon: Icons.warning_amber_rounded,
                    title: '设备异常需要处理',
                    message: '${summary.abnormal} 台设备存在信号、校准或状态提醒，建议先同步并检查设备。',
                    color: InkPalette.reed,
                    primaryLabel: '查看异常设备',
                    onPrimary: onManage,
                    secondaryLabel: '同步状态',
                    onSecondary: onSync,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: InkPalette.mist.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: InkPalette.lake.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    _DeviceTypeIcon(type: core.type, size: 38),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            core.title,
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
                            '${core.telemetryLabel} ${core.telemetryValue} · ${core.workingState}',
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
                      core.isActive ? '在线' : '待机',
                      style: TextStyle(
                        color: core.isActive
                            ? InkPalette.pine
                            : InkPalette.faint,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 0),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                  childAspectRatio: 1.42,
                ),
                children: [
                  _DeviceStat(
                    value: '${summary.total}',
                    label: '已绑定',
                    icon: Icons.hub_rounded,
                    color: InkPalette.lake,
                  ),
                  _DeviceStat(
                    value: '${summary.online}',
                    label: '在线设备',
                    icon: Icons.sensors_rounded,
                    color: InkPalette.pine,
                  ),
                  _DeviceStat(
                    value: '${summary.offline}',
                    label: '离线设备',
                    icon: Icons.power_settings_new_rounded,
                    color: summary.offline > 0
                        ? InkPalette.faint
                        : InkPalette.moss,
                  ),
                  _DeviceStat(
                    value: '${summary.abnormal}',
                    label: '异常设备',
                    icon: Icons.warning_amber_rounded,
                    color: summary.abnormal > 0
                        ? InkPalette.reed
                        : InkPalette.moss,
                    highlight: summary.abnormal > 0,
                  ),
                  _DeviceStat(
                    value: '${summary.lowBattery}',
                    label: '低电量',
                    icon: Icons.battery_alert_rounded,
                    color: summary.lowBattery > 0
                        ? InkPalette.reed
                        : InkPalette.moss,
                    highlight: summary.lowBattery > 0,
                  ),
                  _DeviceStat(
                    value: '${summary.averageSignal}%',
                    label: '平均信号',
                    icon: Icons.network_check_rounded,
                    color: InkPalette.lake,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 0),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final type in deviceTypes)
                    _DeviceChip(label: _deviceTypeName(type), type: type),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 15.h),
              child: Row(
                children: [
                  Expanded(
                    child: InkPrimaryButton(
                      label: '管理设备',
                      icon: Icons.tune_rounded,
                      color: InkPalette.lake,
                      onTap: onManage,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: InkSecondaryButton(
                      label: '同步状态',
                      icon: Icons.sync_rounded,
                      color: InkPalette.pine,
                      onTap: onSync,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderShortcutGrid extends StatelessWidget {
  const OrderShortcutGrid({
    super.key,
    required this.summary,
    required this.onOrderTap,
  });

  final ProfileOrdersSummary summary;
  final ValueChanged<ProfileShortcutItem> onOrderTap;

  @override
  Widget build(BuildContext context) {
    return ProfileAssetGroup(
      icon: Icons.receipt_long_rounded,
      title: '订单资产',
      subtitle: summary.total == 0
          ? '订单、物流和售后会同步到这里'
          : '全部 ${summary.total} 单 · 待处理 ${summary.pendingTotal} 单',
      status: summary.total == 0
          ? '暂无'
          : summary.refundAfterSale > 0
          ? '有售后'
          : '正常',
      color: InkPalette.lake,
      entries: summary.entries,
      onTap: onOrderTap,
      state: summary.total == 0
          ? ProfileStateCard(
              icon: Icons.receipt_long_outlined,
              title: '还没有订单',
              message: '购买智能设备、配件或钓场服务后，订单状态会在这里同步。',
              color: InkPalette.lake,
              primaryLabel: '去商城看看',
              onPrimary: () => _goProfileRoute(context, AppRouteNames.mall),
              secondaryLabel: '查看钓场服务',
              onSecondary: () =>
                  _goProfileRoute(context, AppRouteNames.explore),
            )
          : null,
    );
  }
}

class DeviceServiceSection extends StatelessWidget {
  const DeviceServiceSection({
    super.key,
    required this.deviceCount,
    required this.onTap,
  });

  final int deviceCount;
  final ValueChanged<ProfileShortcutItem> onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileAssetGroup(
      icon: Icons.build_circle_outlined,
      title: '设备售后服务',
      subtitle: deviceCount == 0
          ? '绑定设备后可查看保修和维修服务'
          : '保修 4 台 · 维修 1 单 · 固件提醒 1 项',
      status: deviceCount == 0 ? '待绑定' : '优先处理',
      color: InkPalette.reed,
      entries: ProfileMockData.deviceServices,
      onTap: onTap,
      state: deviceCount == 0
          ? ProfileStateCard(
              icon: Icons.add_link_rounded,
              title: '暂无可服务设备',
              message: '绑定智能装备，开启完整作钓体验',
              color: InkPalette.reed,
              primaryLabel: '立即绑定设备',
              onPrimary: () => _goProfileRoute(context, AppRouteNames.mall),
              secondaryLabel: '联系客服',
              onSecondary: () => onTap(ProfileMockData.deviceServices.last),
            )
          : null,
    );
  }
}

class ReservationEventSection extends StatelessWidget {
  const ReservationEventSection({
    super.key,
    required this.appointments,
    required this.events,
    required this.onExplore,
    required this.onEvent,
  });

  final ProfileAppointmentSummary appointments;
  final ProfileEventsSummary events;
  final VoidCallback onExplore;
  final ValueChanged<ProfileShortcutItem> onEvent;

  @override
  Widget build(BuildContext context) {
    return ProfileAssetGroup(
      icon: Icons.event_seat_rounded,
      title: '钓场预约与赛事',
      subtitle: appointments.isEmpty
          ? '预约、钓位和赛事会同步到这里'
          : '预约 ${appointments.activeAppointments} · 赛事 ${events.activeEvents} · 活动券 ${appointments.couponCount}',
      status: appointments.isEmpty ? '暂无' : '已确认',
      color: InkPalette.pine,
      entries: appointments.entries,
      onTap: (item) {
        if (item.title.contains('钓场') || item.title.contains('钓位')) {
          onExplore();
          return;
        }
        onEvent(item);
      },
      state: appointments.isEmpty
          ? ProfileStateCard(
              icon: Icons.event_seat_rounded,
              title: '还没有钓场预约',
              message: '预约钓场、报名赛事或收藏钓位后，相关资产会汇总到这里。',
              color: InkPalette.pine,
              primaryLabel: '查找钓场',
              onPrimary: onExplore,
              secondaryLabel: '查看附近钓点',
              onSecondary: onExplore,
            )
          : null,
    );
  }
}

class FishingAssetSection extends StatelessWidget {
  const FishingAssetSection({
    super.key,
    required this.totalFish,
    required this.spotsExplored,
    required this.daysActive,
    required this.isLoading,
    required this.hasError,
    required this.isEmpty,
    required this.onRefresh,
    required this.onAssetTap,
  });

  final int totalFish;
  final int spotsExplored;
  final int daysActive;
  final bool isLoading;
  final bool hasError;
  final bool isEmpty;
  final VoidCallback onRefresh;
  final ValueChanged<ProfileShortcutItem> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final summary = ProfileMockData.fishingStats.mergeRuntime(
      totalFish: isEmpty ? 0 : totalFish,
      spotsExplored: isEmpty ? 0 : spotsExplored,
      daysActive: isEmpty ? 0 : daysActive,
    );

    return ProfileAssetGroup(
      icon: Icons.analytics_rounded,
      title: isLoading ? '作钓数据同步中' : '作钓报告与记录',
      subtitle: isEmpty
          ? '开始作钓后自动生成报告'
          : hasError
          ? '当前展示本地缓存数据'
          : '报告 ${summary.reportCount} 份 · 渔获 ${summary.catches} 条 · 设备记录 ${summary.equipmentLogs}',
      status: isLoading
          ? '同步中'
          : isEmpty
          ? '待开始'
          : hasError
          ? '网络异常'
          : '可分析',
      color: hasError ? InkPalette.reed : InkPalette.lake,
      entries: summary.entries,
      onTap: onAssetTap,
      state: isLoading
          ? LoadingSkeleton(
              title: '正在同步作钓数据',
              message: '正在加载作钓记录、渔获、报告和装备使用日志。',
              primaryLabel: '刷新状态',
              onPrimary: onRefresh,
            )
          : hasError
          ? ProfileStateCard(
              icon: Icons.cloud_off_rounded,
              title: '网络错误，作钓数据加载失败',
              message: '当前无法同步作钓记录和报告，可以稍后重试。',
              color: InkPalette.reed,
              primaryLabel: '重新加载',
              onPrimary: onRefresh,
              secondaryLabel: '开始作钓',
              onSecondary: () =>
                  _pushProfileRoute(context, AppRouteNames.creationModal),
            )
          : isEmpty
          ? ProfileStateCard(
              icon: Icons.add_circle_outline_rounded,
              title: '还没有作钓记录',
              message: '开始第一次作钓，系统会自动生成你的作钓报告',
              color: InkPalette.lake,
              primaryLabel: '开始作钓',
              onPrimary: () =>
                  _pushProfileRoute(context, AppRouteNames.creationModal),
              secondaryLabel: '查看钓场',
              onSecondary: () =>
                  _goProfileRoute(context, AppRouteNames.explore),
            )
          : null,
    );
  }
}

class WalletAssetSection extends StatelessWidget {
  const WalletAssetSection({
    super.key,
    required this.coupons,
    required this.onTap,
  });

  final ProfileCouponsSummary coupons;
  final ValueChanged<ProfileShortcutItem> onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileAssetGroup(
      icon: Icons.account_balance_wallet_rounded,
      title: '用户权益资产',
      subtitle: coupons.availableCoupons == 0
          ? '优惠券、积分和收藏会同步到这里'
          : '优惠券 ${coupons.availableCoupons} 张 · 积分 ${coupons.points} · 收藏 ${coupons.favorites}',
      status: coupons.availableCoupons == 0 ? '暂无券' : '可使用',
      color: InkPalette.reed,
      entries: coupons.entries,
      onTap: onTap,
      compact: true,
      state: coupons.availableCoupons == 0
          ? ProfileStateCard(
              icon: Icons.confirmation_number_outlined,
              title: '暂无可用优惠券',
              message: '完成订单、参与活动或开通 Pro 后，优惠券会自动进入账户。',
              color: InkPalette.reed,
              primaryLabel: '去商城领券',
              onPrimary: () => _goProfileRoute(context, AppRouteNames.mall),
              secondaryLabel: '查看会员权益',
              onSecondary: () =>
                  _showMembershipSheet(context, ProfileMockData.inactiveMember),
            )
          : null,
    );
  }
}

class SettingsEntry extends StatelessWidget {
  const SettingsEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      onTap: onTap,
      child: Row(
        children: [
          const _TechIcon(icon: Icons.tune_rounded, color: InkPalette.ink),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设置与账号安全',
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '通知、隐私、设备权限和缓存管理',
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
          Icon(
            Icons.chevron_right_rounded,
            color: InkPalette.muted,
            size: 22.w,
          ),
        ],
      ),
    );
  }
}

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ProfileStateCard(
      icon: Icons.login_rounded,
      title: '登录后同步资产中心',
      message: '登录后同步你的智能装备、作钓记录、订单和会员权益',
      color: InkPalette.lake,
      primaryLabel: '登录 / 注册',
      onPrimary: onLogin,
      secondaryLabel: '先看看功能',
      onSecondary: () => AppFeedback.showMessage(context, '可继续浏览当前演示内容'),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: InkPalette.lake.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TechIcon(
                icon: Icons.cloud_sync_rounded,
                color: InkPalette.lake,
              ),
              SizedBox(width: 12.w),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 11.5.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const _SkeletonBar(widthFactor: 0.92),
          SizedBox(height: 7.h),
          const _SkeletonBar(widthFactor: 0.68),
          SizedBox(height: 12.h),
          InkSecondaryButton(
            label: primaryLabel,
            icon: Icons.refresh_rounded,
            color: InkPalette.lake,
            onTap: onPrimary,
          ),
        ],
      ),
    );
  }
}

class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String message;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: InkPalette.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: InkPalette.reed, size: 20.w),
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
                        color: InkPalette.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.white.withValues(alpha: 0.74),
                        fontSize: 11.5.sp,
                        height: 1.32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _ProfileActionButtons(
            primaryLabel: primaryLabel,
            primaryIcon: Icons.bolt_rounded,
            primaryColor: InkPalette.reed,
            onPrimary: onPrimary,
            secondaryLabel: secondaryLabel,
            secondaryIcon: Icons.receipt_long_rounded,
            secondaryColor: InkPalette.lake,
            onSecondary: onSecondary,
          ),
        ],
      ),
    );
  }
}

class ProfileStateCard extends StatelessWidget {
  const ProfileStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkIconMark(icon: icon, color: color, size: 40, iconSize: 20),
              SizedBox(width: 11.w),
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
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message,
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
            ],
          ),
          SizedBox(height: 12.h),
          _ProfileActionButtons(
            primaryLabel: primaryLabel,
            primaryIcon: Icons.arrow_forward_rounded,
            primaryColor: color,
            onPrimary: onPrimary,
            secondaryLabel: hasSecondary ? secondaryLabel : null,
            secondaryIcon: Icons.more_horiz_rounded,
            secondaryColor: color,
            onSecondary: onSecondary,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButtons extends StatelessWidget {
  const _ProfileActionButtons({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.primaryColor,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryColor,
    this.onSecondary,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final Color primaryColor;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final Color? secondaryColor;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel != null && onSecondary != null
        ? InkSecondaryButton(
            label: secondaryLabel!,
            icon: secondaryIcon,
            color: secondaryColor ?? primaryColor,
            onTap: onSecondary,
          )
        : null;
    final primary = InkPrimaryButton(
      label: primaryLabel,
      icon: primaryIcon,
      color: primaryColor,
      onTap: onPrimary,
    );

    if (secondary == null) return primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 312.w) {
          return Column(
            children: [
              primary,
              SizedBox(height: 8.h),
              secondary,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: primary),
            SizedBox(width: 10.w),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return _PulsingSkeletonBar(widthFactor: widthFactor);
  }
}

class _PulsingSkeletonBar extends StatefulWidget {
  const _PulsingSkeletonBar({required this.widthFactor});

  final double widthFactor;

  @override
  State<_PulsingSkeletonBar> createState() => _PulsingSkeletonBarState();
}

class _PulsingSkeletonBarState extends State<_PulsingSkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _alpha = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alpha,
      builder: (context, _) {
        return FractionallySizedBox(
          widthFactor: widget.widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: InkPalette.lake.withValues(alpha: _alpha.value),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }
}

class _SubtleEmphasis extends StatefulWidget {
  const _SubtleEmphasis({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_SubtleEmphasis> createState() => _SubtleEmphasisState();
}

class _SubtleEmphasisState extends State<_SubtleEmphasis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) {
        final value = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.06 + value * 0.06),
                blurRadius: 14 + value * 5,
                spreadRadius: value,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class ProfileAssetGroup extends StatelessWidget {
  const ProfileAssetGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    required this.entries,
    required this.onTap,
    this.compact = false,
    this.state,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final List<ProfileShortcutItem> entries;
  final ValueChanged<ProfileShortcutItem> onTap;
  final bool compact;
  final Widget? state;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.zero,
      borderColor: color.withValues(alpha: 0.16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            ),
            child: Row(
              children: [
                _TechIcon(icon: icon, color: color),
                SizedBox(width: 12.w),
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
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
                SizedBox(width: 8.w),
                _StatusCapsule(label: status, color: color),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
            child:
                state ??
                Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      _AssetEntryRow(
                        item: entries[i],
                        prominent: i == 0,
                        compact: compact,
                        onTap: () => onTap(entries[i]),
                      ),
                      if (i != entries.length - 1) SizedBox(height: 8.h),
                    ],
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

class _AssetEntryRow extends StatelessWidget {
  const _AssetEntryRow({
    required this.item,
    required this.prominent,
    required this.compact,
    required this.onTap,
  });

  final ProfileShortcutItem item;
  final bool prominent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = prominent ? 68.h : (compact ? 56.h : 60.h);

    return InkPressable(
      onTap: onTap,
      pressedScale: 0.985,
      rippleColor: item.color,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: prominent
              ? item.color.withValues(alpha: 0.10)
              : InkPalette.paper.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(prominent ? 17.r : 14.r),
          border: Border.all(
            color: item.color.withValues(alpha: prominent ? 0.20 : 0.10),
          ),
        ),
        child: Row(
          children: [
            InkIconMark(
              icon: item.icon,
              color: item.color,
              size: prominent ? 38 : 32,
              iconSize: prominent ? 18 : 16,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: prominent ? 14.5.sp : 13.5.sp,
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
                      fontSize: 11.2.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: prominent ? 15.sp : 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.status.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  _MiniStatus(label: item.status, color: item.color),
                ],
              ],
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.chevron_right_rounded,
              color: InkPalette.faint,
              size: 18.w,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileServiceDock extends StatelessWidget {
  const _ProfileServiceDock({
    required this.member,
    required this.onAll,
    required this.onMember,
    required this.onOrder,
    required this.onReservation,
    required this.onWallet,
    required this.onSupport,
  });

  final ProfileMemberState member;
  final VoidCallback onAll;
  final VoidCallback onMember;
  final VoidCallback onOrder;
  final VoidCallback onReservation;
  final VoidCallback onWallet;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProfileServiceItem(
        icon: Icons.workspace_premium_rounded,
        title: '会员',
        subtitle: member.status == ProfileMemberStatus.active ? 'Pro' : '权益',
        color: InkPalette.reed,
        onTap: onMember,
      ),
      _ProfileServiceItem(
        icon: Icons.receipt_long_rounded,
        title: '订单',
        subtitle: '物流/售后',
        color: InkPalette.pine,
        onTap: onOrder,
      ),
      _ProfileServiceItem(
        icon: Icons.event_available_rounded,
        title: '预约',
        subtitle: '钓位/活动',
        color: InkPalette.moss,
        onTap: onReservation,
      ),
      _ProfileServiceItem(
        icon: Icons.confirmation_number_rounded,
        title: '钱包',
        subtitle: '券/积分',
        color: InkPalette.lake,
        onTap: onWallet,
      ),
      _ProfileServiceItem(
        icon: Icons.support_agent_rounded,
        title: '售后',
        subtitle: '设备服务',
        color: InkPalette.reed,
        onTap: onSupport,
      ),
      _ProfileServiceItem(
        icon: Icons.dashboard_customize_rounded,
        title: '全部',
        subtitle: '资产服务',
        color: InkPalette.pine,
        onTap: onAll,
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
                kind: InkVisualTileKind.achievement,
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
                      '资产',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '会员 / 订单 / 预约 / 钱包 / 售后',
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
                onTap: onAll,
                child: Text(
                  '全部',
                  style: TextStyle(
                    color: InkPalette.lake,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 520 ? 2 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                  childAspectRatio: constraints.maxWidth < 520 ? 1.34 : 1.58,
                ),
                itemBuilder: (context, index) => InkEntrance(
                  delay: Duration(milliseconds: 30 * index),
                  offset: 6,
                  child: _ProfileServiceTile(item: items[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileServiceTile extends StatelessWidget {
  const _ProfileServiceTile({required this.item});

  final _ProfileServiceItem item;

  @override
  Widget build(BuildContext context) {
    return InkPressable(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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

class _ProfileServiceItem {
  const _ProfileServiceItem({
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

class _ProfileContentPadding extends StatelessWidget {
  const _ProfileContentPadding({
    required this.child,
    this.top = 9,
    this.motionIndex = 0,
  });

  final Widget child;
  final double top;
  final int motionIndex;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: EdgeInsets.fromLTRB(18.w, top.h, 18.w, 0),
      child: child,
    );

    return _ProfileEntrance(index: motionIndex, child: padded);
  }
}

class _ProfileEntrance extends StatefulWidget {
  const _ProfileEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_ProfileEntrance> createState() => _ProfileEntranceState();
}

class _ProfileEntranceState extends State<_ProfileEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curved);

    final delayMs = (widget.index.clamp(0, 8) * 18).round();
    if (delayMs == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return InkSectionHeader(
      title: title,
      subtitle: subtitle,
      action: action,
      onAction: onAction,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final provider = _avatarProvider(avatarUrl);

    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [InkPalette.mist, InkPalette.white],
        ),
        border: Border.all(
          color: InkPalette.pine.withValues(alpha: 0.26),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: InkPalette.lake.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: Offset(0, 7.h),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: provider == null
          ? Icon(Icons.person_rounded, color: InkPalette.pine, size: 30.w)
          : Image(image: provider, fit: BoxFit.cover),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 110.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15.w),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 10.2.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProBenefitTile extends StatelessWidget {
  const _ProBenefitTile({required this.benefit});

  final ProfileBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: InkPalette.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(benefit.icon, color: InkPalette.white, size: 15.w),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              benefit.label,
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
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({required this.label, this.color = InkPalette.white});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TechIcon extends StatelessWidget {
  const _TechIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: color, size: 21.w),
    );
  }
}

class _StatusCapsule extends StatelessWidget {
  const _StatusCapsule({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 72.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 66.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 9.8.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeviceTypeIcon extends StatelessWidget {
  const _DeviceTypeIcon({required this.type, required this.size});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _deviceColor(type);

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, InkPalette.lake, 0.36)!],
        ),
        borderRadius: BorderRadius.circular((size * 0.34).r),
      ),
      child: Icon(
        _deviceIcon(type),
        color: InkPalette.white,
        size: (size * 0.48).w,
      ),
    );
  }
}

class _DeviceStat extends StatelessWidget {
  const _DeviceStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withValues(alpha: highlight ? 0.32 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16.w),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2.h),
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
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({required this.label, required this.type});

  final String label;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _deviceColor(type);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_deviceIcon(type), color: color, size: 13.w),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMockData {
  const ProfileMockData._();

  static const user = ProfileUserMock(
    id: 'demo_profile_001',
    nickname: '江湖钓客',
    avatar: '',
    level: 'Pro 会员',
    tags: ['路亚', '台钓', '信用 92'],
    member: ProfileMemberState(
      status: ProfileMemberStatus.active,
      name: '江湖钓客 Pro',
      expireAt: '2026-12-31',
      summary: '高级报告、多设备绑定、90 天历史数据',
    ),
  );

  static const inactiveMember = ProfileMemberState(
    status: ProfileMemberStatus.inactive,
    name: '江湖钓客 Pro',
    expireAt: '',
    summary: '开启 Pro，解锁更完整的智能作钓体验',
  );

  static const expiredMember = ProfileMemberState(
    status: ProfileMemberStatus.expired,
    name: '江湖钓客 Pro',
    expireAt: '2026-03-31',
    summary: '会员已过期，续费后恢复高级报告和设备服务权益',
  );

  static const proBenefits = [
    ProfileBenefit(label: '高级作钓报告', icon: Icons.analytics_rounded),
    ProfileBenefit(label: '多设备绑定', icon: Icons.hub_rounded),
    ProfileBenefit(label: '90 天历史数据', icon: Icons.history_rounded),
    ProfileBenefit(label: '鱼情分析', icon: Icons.auto_graph_rounded),
    ProfileBenefit(label: '钓场优惠', icon: Icons.place_rounded),
    ProfileBenefit(label: '商城会员价', icon: Icons.shopping_bag_rounded),
    ProfileBenefit(label: '设备延保', icon: Icons.verified_user_rounded),
    ProfileBenefit(label: '专属客服', icon: Icons.support_agent_rounded),
  ];

  static const fallbackDevice = IotDeviceState(
    id: 'profile_fallback_float',
    title: '智能鱼漂',
    type: 'float',
    sceneRole: '鱼口捕捉',
    telemetryLabel: '咬口频率',
    telemetryValue: '--',
    workingState: '未绑定',
    batteryLevel: 0,
    signalLevel: 0,
    isActive: false,
    riskLabel: '未绑定',
    actionHint: '绑定智能设备后显示实时状态。',
  );

  static const ordersSummary = ProfileOrdersSummary(
    total: 12,
    pendingPayment: 1,
    pendingShipment: 2,
    pendingReceipt: 1,
    refundAfterSale: 1,
  );

  static const emptyOrdersSummary = ProfileOrdersSummary(
    total: 0,
    pendingPayment: 0,
    pendingShipment: 0,
    pendingReceipt: 0,
    refundAfterSale: 0,
  );

  static const deviceServices = [
    ProfileShortcutItem(
      title: '设备保修',
      value: '4台',
      subtitle: '智能鱼漂、钓箱、钓台、钓伞在保',
      status: '可查保期',
      icon: Icons.verified_user_rounded,
      color: InkPalette.pine,
    ),
    ProfileShortcutItem(
      title: '维修进度',
      value: '1单',
      subtitle: '钓台水平校准工单处理中',
      status: '处理中',
      icon: Icons.build_rounded,
      color: InkPalette.reed,
    ),
    ProfileShortcutItem(
      title: '固件升级问题',
      value: '1项',
      subtitle: '钓伞环境提醒固件可更新',
      status: '待升级',
      icon: Icons.system_update_alt_rounded,
      color: InkPalette.lake,
    ),
    ProfileShortcutItem(
      title: '绑定问题',
      value: '0',
      subtitle: '设备解绑、换绑和账号归属',
      status: '正常',
      icon: Icons.link_rounded,
      color: InkPalette.moss,
    ),
    ProfileShortcutItem(
      title: '配件购买',
      value: '6类',
      subtitle: '电池、漂尾、伞骨和钓箱耗材',
      status: '会员价',
      icon: Icons.shopping_bag_rounded,
      color: InkPalette.reed,
    ),
    ProfileShortcutItem(
      title: '联系客服',
      value: '7x12',
      subtitle: '订单、售后和设备问题优先响应',
      status: '在线',
      icon: Icons.support_agent_rounded,
      color: InkPalette.lake,
    ),
  ];

  static const appointments = ProfileAppointmentSummary(
    activeAppointments: 2,
    seatRecords: 18,
    eventRegistrations: 1,
    couponCount: 3,
    favoriteSpots: 26,
  );

  static const events = ProfileEventsSummary(activeEvents: 1);

  static const emptyAppointments = ProfileAppointmentSummary(
    activeAppointments: 0,
    seatRecords: 0,
    eventRegistrations: 0,
    couponCount: 0,
    favoriteSpots: 0,
  );

  static const emptyEvents = ProfileEventsSummary(activeEvents: 0);

  static const fishingStats = ProfileFishingStats(
    records: 128,
    reportCount: 6,
    catches: 256,
    equipmentLogs: 42,
    spots: 68,
    analyses: 12,
  );

  static const coupons = ProfileCouponsSummary(
    availableCoupons: 5,
    couponValue: '¥138',
    points: 2487,
    growth: 632,
    favorites: 126,
    browsing: 36,
  );

  static const emptyCoupons = ProfileCouponsSummary(
    availableCoupons: 0,
    couponValue: '0',
    points: 0,
    growth: 0,
    favorites: 0,
    browsing: 0,
  );

  static DomainUserAssetSummary buildDomainAssetSummary({
    required String userId,
    required List<IotDeviceState> devices,
  }) {
    final deviceSummary = DomainDeviceSummary.fromDevices(
      devices.map((device) => device.toDomainDevice()).toList(growable: false),
    );
    return DomainUserAssetSummary(
      userId: userId,
      devices: deviceSummary,
      ordersTotal: ordersSummary.total,
      activeBookings: appointments.activeAppointments,
      fishingRecords: fishingStats.records,
      availableCoupons: coupons.availableCoupons,
      points: coupons.points,
      favorites: coupons.favorites,
      membership: user.member.toDomainMembership(
        benefits: proBenefits.map((item) => item.label).toList(growable: false),
      ),
    );
  }
}

class ProfileUserMock {
  const ProfileUserMock({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.level,
    required this.tags,
    required this.member,
  });

  final String id;
  final String nickname;
  final String avatar;
  final String level;
  final List<String> tags;
  final ProfileMemberState member;
}

enum ProfileMemberStatus { inactive, active, expired }

class ProfileMemberState {
  const ProfileMemberState({
    required this.status,
    required this.name,
    required this.expireAt,
    required this.summary,
  });

  final ProfileMemberStatus status;
  final String name;
  final String expireAt;
  final String summary;

  DomainMembership toDomainMembership({List<String> benefits = const []}) {
    return DomainMembership(
      planId: 'jianghu_pro',
      name: name,
      status: _toDomainMembershipStatus(status),
      expireAt: expireAt,
      benefits: benefits,
      summary: summary,
    );
  }
}

class ProfileBenefit {
  const ProfileBenefit({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class ProfileOrdersSummary {
  const ProfileOrdersSummary({
    required this.total,
    required this.pendingPayment,
    required this.pendingShipment,
    required this.pendingReceipt,
    required this.refundAfterSale,
  });

  final int total;
  final int pendingPayment;
  final int pendingShipment;
  final int pendingReceipt;
  final int refundAfterSale;

  int get pendingTotal =>
      pendingPayment + pendingShipment + pendingReceipt + refundAfterSale;

  bool get isEmpty => total == 0;

  List<ProfileShortcutItem> get entries {
    if (isEmpty) return const [];
    return [
      ProfileShortcutItem(
        title: '全部订单',
        value: '$total',
        subtitle: '商品订单、设备服务订单和钓场订单',
        status: '查看',
        icon: Icons.receipt_long_rounded,
        color: InkPalette.lake,
      ),
      ProfileShortcutItem(
        title: '待付款',
        value: '$pendingPayment',
        subtitle: '装备订单待支付',
        status: pendingPayment > 0 ? '待处理' : '清爽',
        icon: Icons.payments_rounded,
        color: InkPalette.reed,
      ),
      ProfileShortcutItem(
        title: '待发货',
        value: '$pendingShipment',
        subtitle: '钓具配件准备出库',
        status: pendingShipment > 0 ? '备货中' : '无',
        icon: Icons.local_shipping_rounded,
        color: InkPalette.lake,
      ),
      ProfileShortcutItem(
        title: '待收货',
        value: '$pendingReceipt',
        subtitle: '物流跟踪与签收确认',
        status: pendingReceipt > 0 ? '在途' : '无',
        icon: Icons.inventory_2_rounded,
        color: InkPalette.pine,
      ),
      ProfileShortcutItem(
        title: '退款 / 售后',
        value: '$refundAfterSale',
        subtitle: '退款、换货、维修售后统一处理',
        status: refundAfterSale > 0 ? '跟进中' : '正常',
        icon: Icons.support_agent_rounded,
        color: InkPalette.moss,
      ),
    ];
  }
}

class ProfileAppointmentSummary {
  const ProfileAppointmentSummary({
    required this.activeAppointments,
    required this.seatRecords,
    required this.eventRegistrations,
    required this.couponCount,
    required this.favoriteSpots,
  });

  final int activeAppointments;
  final int seatRecords;
  final int eventRegistrations;
  final int couponCount;
  final int favoriteSpots;

  bool get isEmpty =>
      activeAppointments == 0 &&
      seatRecords == 0 &&
      eventRegistrations == 0 &&
      couponCount == 0 &&
      favoriteSpots == 0;

  List<ProfileShortcutItem> get entries {
    if (isEmpty) return const [];
    return [
      ProfileShortcutItem(
        title: '我的钓场预约',
        value: '$activeAppointments',
        subtitle: '老码头 · 路灯边界 · 明日 07:30',
        status: '已确认',
        icon: Icons.event_seat_rounded,
        color: InkPalette.pine,
      ),
      ProfileShortcutItem(
        title: '我的钓位记录',
        value: '$seatRecords',
        subtitle: '常用钓位、入场记录和安全备注',
        status: '可复盘',
        icon: Icons.location_on_rounded,
        color: InkPalette.lake,
      ),
      ProfileShortcutItem(
        title: '我的赛事报名',
        value: '$eventRegistrations',
        subtitle: '周末路亚赛报名中',
        status: '报名中',
        icon: Icons.emoji_events_rounded,
        color: InkPalette.reed,
      ),
      ProfileShortcutItem(
        title: '我的活动券',
        value: '$couponCount',
        subtitle: '钓场夜钓、包场和赛事券',
        status: '可使用',
        icon: Icons.confirmation_number_rounded,
        color: InkPalette.moss,
      ),
      ProfileShortcutItem(
        title: '我的钓场收藏',
        value: '$favoriteSpots',
        subtitle: '常去水域、口碑钓场和安全点位',
        status: '已同步',
        icon: Icons.bookmark_rounded,
        color: InkPalette.lake,
      ),
    ];
  }
}

class ProfileEventsSummary {
  const ProfileEventsSummary({required this.activeEvents});

  final int activeEvents;
}

class ProfileFishingStats {
  const ProfileFishingStats({
    required this.records,
    required this.reportCount,
    required this.catches,
    required this.equipmentLogs,
    required this.spots,
    required this.analyses,
  });

  final int records;
  final int reportCount;
  final int catches;
  final int equipmentLogs;
  final int spots;
  final int analyses;

  ProfileFishingStats mergeRuntime({
    required int totalFish,
    required int spotsExplored,
    required int daysActive,
  }) {
    return ProfileFishingStats(
      records: daysActive,
      reportCount: reportCount,
      catches: totalFish,
      equipmentLogs: equipmentLogs,
      spots: spotsExplored,
      analyses: analyses,
    );
  }

  List<ProfileShortcutItem> get entries => [
    ProfileShortcutItem(
      title: '我的作钓记录',
      value: '$records',
      subtitle: '出钓时间、天气、水情和鱼口窗口',
      status: '持续沉淀',
      icon: Icons.calendar_month_rounded,
      color: InkPalette.pine,
    ),
    ProfileShortcutItem(
      title: '作钓报告',
      value: '$reportCount',
      subtitle: '高级报告会汇总鱼情、设备和钓场表现',
      status: '重点',
      icon: Icons.analytics_rounded,
      color: InkPalette.reed,
    ),
    ProfileShortcutItem(
      title: '我的渔获',
      value: '$catches',
      subtitle: '鱼种、尺寸、钓法和图鉴解锁',
      status: '已入库',
      icon: Icons.set_meal_rounded,
      color: InkPalette.lake,
    ),
    ProfileShortcutItem(
      title: '我的装备使用记录',
      value: '$equipmentLogs',
      subtitle: '鱼漂、钓箱、钓台、钓伞使用日志',
      status: 'IoT',
      icon: Icons.settings_input_antenna_rounded,
      color: InkPalette.pine,
    ),
    ProfileShortcutItem(
      title: '我的钓点收藏',
      value: '$spots',
      subtitle: '收藏钓点、常去水域和安全点位',
      status: '地图',
      icon: Icons.place_rounded,
      color: InkPalette.moss,
    ),
    ProfileShortcutItem(
      title: '我的数据分析',
      value: '$analyses',
      subtitle: '鱼情趋势、命中率和设备关联分析',
      status: 'Pro',
      icon: Icons.auto_graph_rounded,
      color: InkPalette.reed,
    ),
  ];
}

class ProfileCouponsSummary {
  const ProfileCouponsSummary({
    required this.availableCoupons,
    required this.couponValue,
    required this.points,
    required this.growth,
    required this.favorites,
    required this.browsing,
  });

  final int availableCoupons;
  final String couponValue;
  final int points;
  final int growth;
  final int favorites;
  final int browsing;

  List<ProfileShortcutItem> get entries => [
    ProfileShortcutItem(
      title: '优惠券',
      value: couponValue,
      subtitle: '$availableCoupons 张可用，覆盖商城和钓场',
      status: '可用',
      icon: Icons.confirmation_number_rounded,
      color: InkPalette.reed,
    ),
    ProfileShortcutItem(
      title: '积分 / 成长值',
      value: '$points',
      subtitle: '成长值 $growth，可兑换配件和活动券',
      status: '成长中',
      icon: Icons.stars_rounded,
      color: InkPalette.pine,
    ),
    ProfileShortcutItem(
      title: '收藏',
      value: '$favorites',
      subtitle: '钓点、装备、商品和攻略收藏',
      status: '已同步',
      icon: Icons.bookmark_rounded,
      color: InkPalette.lake,
    ),
    ProfileShortcutItem(
      title: '浏览记录',
      value: '$browsing',
      subtitle: '最近查看的钓场、装备和报告',
      status: '最近',
      icon: Icons.history_rounded,
      color: InkPalette.moss,
    ),
  ];
}

class ProfileDevicesSummary {
  const ProfileDevicesSummary({
    required this.total,
    required this.online,
    required this.offline,
    required this.lowBattery,
    required this.abnormal,
    required this.averageSignal,
    required this.lastSyncAt,
    required this.coreDevice,
  });

  final int total;
  final int online;
  final int offline;
  final int lowBattery;
  final int abnormal;
  final int averageSignal;
  final String lastSyncAt;
  final IotDeviceState coreDevice;

  DomainDeviceSummary toDomainDeviceSummary() {
    return DomainDeviceSummary(
      total: total,
      online: online,
      offline: offline,
      lowBattery: lowBattery,
      abnormal: abnormal,
      lastSyncAt: DateTime.now(),
    );
  }

  factory ProfileDevicesSummary.fromDevices(List<IotDeviceState> devices) {
    final coreDevices = devices.where(_isCoreDevice).toList(growable: false);
    final effectiveDevices = coreDevices.isEmpty ? devices : coreDevices;
    if (effectiveDevices.isEmpty) {
      return const ProfileDevicesSummary(
        total: 0,
        online: 0,
        offline: 0,
        lowBattery: 0,
        abnormal: 0,
        averageSignal: 0,
        lastSyncAt: '暂无同步',
        coreDevice: ProfileMockData.fallbackDevice,
      );
    }
    final total = effectiveDevices.length;
    final online = effectiveDevices.where((device) => device.isActive).length;
    final lowBattery = effectiveDevices
        .where((device) => device.batteryLevel <= 75)
        .length;
    final abnormal = effectiveDevices.where(_isAbnormalDevice).length;
    final averageSignal = total == 0
        ? 0
        : effectiveDevices
                  .map((device) => device.signalLevel)
                  .reduce((a, b) => a + b) ~/
              total;
    final coreDevice = effectiveDevices.firstWhere(
      (device) => device.type == 'float',
      orElse: () => effectiveDevices.first,
    );

    return ProfileDevicesSummary(
      total: total,
      online: online,
      offline: total - online,
      lowBattery: lowBattery,
      abnormal: abnormal,
      averageSignal: averageSignal,
      lastSyncAt: '2 分钟前',
      coreDevice: coreDevice,
    );
  }
}

DomainMembershipStatus _toDomainMembershipStatus(ProfileMemberStatus status) {
  return switch (status) {
    ProfileMemberStatus.inactive => DomainMembershipStatus.inactive,
    ProfileMemberStatus.active => DomainMembershipStatus.active,
    ProfileMemberStatus.expired => DomainMembershipStatus.expired,
  };
}

class ProfileShortcutItem {
  const ProfileShortcutItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.status = '',
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String status;
}

void _showProfileEditSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '编辑智能作钓档案',
    subtitle: '头像、昵称、常用钓法和公开标签会影响社区展示与推荐模型。',
    icon: Icons.edit_rounded,
    color: InkPalette.lake,
    children: const [
      InkInfoRow(
        icon: Icons.person_rounded,
        title: '资料完整度 72%',
        subtitle: '补充头像、常去水域和目标鱼种后可提升推荐准确度',
        color: InkPalette.pine,
      ),
      SizedBox(height: 10),
      InkInfoRow(
        icon: Icons.privacy_tip_rounded,
        title: '隐私可控',
        subtitle: '钓点精确坐标默认不公开，只展示水域类型和城市',
        color: InkPalette.moss,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.tune_rounded,
        title: '进入资料设置',
        subtitle: '修改头像、昵称、标签和隐私范围',
        color: InkPalette.lake,
        onTap: () => _pushProfileRoute(context, AppRouteNames.settings),
      ),
    ],
  );
}

void _showMembershipSheet(BuildContext context, ProfileMemberState member) {
  final statusText = switch (member.status) {
    ProfileMemberStatus.inactive => '未开通',
    ProfileMemberStatus.active => '已开通 · 到期 ${member.expireAt}',
    ProfileMemberStatus.expired => '已过期 · 建议续费恢复权益',
  };

  showInkActionSheet(
    context,
    title: '${member.name} 权益',
    subtitle: '$statusText · ${member.summary}',
    icon: Icons.workspace_premium_rounded,
    color: InkPalette.reed,
    children: [
      for (var i = 0; i < ProfileMockData.proBenefits.length; i++) ...[
        InkInfoRow(
          icon: ProfileMockData.proBenefits[i].icon,
          title: ProfileMockData.proBenefits[i].label,
          subtitle: _benefitDescription(ProfileMockData.proBenefits[i].label),
          color: i.isEven ? InkPalette.lake : InkPalette.pine,
        ),
        if (i != ProfileMockData.proBenefits.length - 1) SizedBox(height: 10.h),
      ],
    ],
    actions: [
      InkSheetAction(
        icon: Icons.shopping_bag_rounded,
        title: member.status == ProfileMemberStatus.active
            ? '续费 Pro'
            : '立即开通 Pro',
        subtitle: '查看会员专享商品、优惠券和设备服务包',
        color: InkPalette.reed,
        onTap: () => _goProfileRoute(context, AppRouteNames.mall),
      ),
    ],
  );
}

void _showDeviceServiceSheet(
  BuildContext context,
  List<IotDeviceState> devices,
) {
  final summary = ProfileDevicesSummary.fromDevices(devices);
  final coreDevices = devices.where(_isCoreDevice).toList(growable: false);

  showInkActionSheet(
    context,
    title: '我的智能装备',
    subtitle:
        '${summary.total} 台设备｜${summary.online} 台在线｜${summary.lowBattery} 台低电量 · 最近同步 ${summary.lastSyncAt}',
    icon: Icons.settings_input_antenna_rounded,
    color: InkPalette.lake,
    children: [
      if (coreDevices.isEmpty)
        ProfileStateCard(
          icon: Icons.add_link_rounded,
          title: '还没有绑定智能装备',
          message: '绑定智能装备，开启完整作钓体验',
          color: InkPalette.lake,
          primaryLabel: '立即绑定设备',
          onPrimary: () => _goProfileRoute(context, AppRouteNames.mall),
          secondaryLabel: '查看支持设备',
          onSecondary: () => _goProfileRoute(context, AppRouteNames.mall),
        )
      else
        for (final device in coreDevices) ...[
          _DeviceSheetRow(device: device),
          if (device != coreDevices.last) SizedBox(height: 8.h),
        ],
    ],
    actions: [
      InkSheetAction(
        icon: Icons.sync_rounded,
        title: '同步全部设备',
        subtitle: '刷新鱼漂、钓箱、钓台、钓伞最近状态',
        color: InkPalette.lake,
        onTap: () => AppFeedback.showMessage(context, '已下发多设备同步任务'),
      ),
      InkSheetAction(
        icon: Icons.build_circle_outlined,
        title: '售后与固件',
        subtitle: '校准、维修、解绑和 OTA 升级',
        color: InkPalette.moss,
        onTap: () => _goProfileRoute(context, AppRouteNames.mall),
      ),
    ],
  );
}

void _showOrderSheet(BuildContext context, ProfileShortcutItem item) {
  showInkActionSheet(
    context,
    title: item.title,
    subtitle: '${item.subtitle} · 当前数量 ${item.value}',
    icon: item.icon,
    color: item.color,
    children: [
      InkInfoRow(
        icon: Icons.receipt_long_rounded,
        title: '订单状态已归入服务资产',
        subtitle: '后续可接真实订单、物流、发票和售后进度',
        color: item.color,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.shopping_bag_rounded,
        title: '进入商城订单',
        subtitle: '查看全部商品订单和设备服务订单',
        color: item.color,
        onTap: () => _goProfileRoute(context, AppRouteNames.mall),
      ),
    ],
  );
}

void _showReservationSheet(BuildContext context, ProfileShortcutItem item) {
  showInkActionSheet(
    context,
    title: item.title,
    subtitle: '${item.value} · ${item.subtitle}',
    icon: item.icon,
    color: item.color,
    children: [
      InkInfoRow(
        icon: item.icon,
        title: item.status.isEmpty ? '钓场资产已记录' : item.status,
        subtitle: '预约、钓位、赛事、活动券和收藏会统一沉淀到个人资产。',
        color: item.color,
      ),
      SizedBox(height: 10),
      const InkInfoRow(
        icon: Icons.security_rounded,
        title: '赛事安全提示',
        subtitle: '钓台校准、钓伞风速提醒和夜钓撤离路线已准备',
        color: InkPalette.lake,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.place_rounded,
        title: '打开钓场',
        subtitle: '查看附近钓场、钓位和赛事活动',
        color: InkPalette.pine,
        onTap: () => _goProfileRoute(context, AppRouteNames.explore),
      ),
    ],
  );
}

void _showFishingAssetSheet(BuildContext context, ProfileShortcutItem item) {
  showInkActionSheet(
    context,
    title: item.title,
    subtitle: '${item.value} · ${item.subtitle}',
    icon: item.icon,
    color: item.color,
    children: [
      InkInfoRow(
        icon: Icons.auto_graph_rounded,
        title: '作钓数据资产',
        subtitle: '记录越完整，首页适钓指数和设备建议越准确',
        color: item.color,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.add_circle_rounded,
        title: '新增作钓记录',
        subtitle: '发布鱼获、补充天气、水情和设备数据',
        color: item.color,
        onTap: () => _pushProfileRoute(context, AppRouteNames.creationModal),
      ),
    ],
  );
}

void _showWalletSheet(BuildContext context, ProfileShortcutItem item) {
  showInkActionSheet(
    context,
    title: item.title,
    subtitle: '${item.value} · ${item.subtitle}',
    icon: item.icon,
    color: item.color,
    children: [
      InkInfoRow(
        icon: Icons.account_balance_wallet_rounded,
        title: '资产可用于商城和钓场服务',
        subtitle: '优惠券、积分、收藏会服务会员转化和复购',
        color: item.color,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.shopping_bag_rounded,
        title: '去商城使用',
        subtitle: '查看可兑换权益和会员商品',
        color: item.color,
        onTap: () => _goProfileRoute(context, AppRouteNames.mall),
      ),
    ],
  );
}

void _showSupportSheet(BuildContext context, ProfileShortcutItem item) {
  showInkActionSheet(
    context,
    title: item.title,
    subtitle: '${item.value} · ${item.subtitle}',
    icon: item.icon,
    color: item.color,
    children: [
      InkInfoRow(
        icon: Icons.support_agent_rounded,
        title: '服务入口已聚合',
        subtitle: '后续可接入工单、客服会话、保修卡和固件升级记录',
        color: item.color,
      ),
    ],
    actions: [
      InkSheetAction(
        icon: Icons.tune_rounded,
        title: '服务设置',
        subtitle: '管理通知、隐私、缓存和设备权限',
        color: item.color,
        onTap: () => _pushProfileRoute(context, AppRouteNames.settings),
      ),
    ],
  );
}

void _refreshProfile(WidgetRef ref) {
  ref.invalidate(currentUserProvider);
  ref.invalidate(userStatsProvider);
}

void _goProfileRoute(BuildContext context, String route) {
  FocusManager.instance.primaryFocus?.unfocus();
  context.go(route);
}

void _pushProfileRoute(BuildContext context, String route) {
  FocusManager.instance.primaryFocus?.unfocus();
  context.push(route);
}

bool _isUnauthorizedProfileError(Object? error) {
  if (error == null) return false;
  final text = error.toString().toLowerCase();
  return text.contains('401') ||
      text.contains('unauthorized') ||
      text.contains('unauthenticated') ||
      text.contains('未登录') ||
      text.contains('登录');
}

bool _isProfileNetworkError(Object? error) {
  if (error == null || _isUnauthorizedProfileError(error)) return false;
  return true;
}

class _DeviceSheetRow extends StatelessWidget {
  const _DeviceSheetRow({required this.device});

  final IotDeviceState device;

  @override
  Widget build(BuildContext context) {
    final color = _deviceColor(device.type);

    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: device.isActive
          ? InkPalette.paper.withValues(alpha: 0.72)
          : InkPalette.paper.withValues(alpha: 0.46),
      borderColor: color.withValues(alpha: 0.16),
      child: Row(
        children: [
          _DeviceTypeIcon(type: device.type, size: 38),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.title,
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
                  '${_deviceTypeName(device.type)} · ${device.workingState}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.2.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                device.telemetryValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '${device.batteryLevel}% · ${device.signalLevel}%',
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 10.5.sp,
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

ImageProvider? _avatarProvider(String? avatarUrl) {
  if (avatarUrl == null ||
      avatarUrl.isEmpty ||
      avatarUrl.contains('example.com')) {
    return null;
  }
  return NetworkImage(avatarUrl);
}

Color _tagColor(String label) {
  if (label.contains('信用')) return InkPalette.moss;
  if (label.contains('路亚')) return InkPalette.lake;
  if (label.contains('台钓')) return InkPalette.pine;
  if (label.contains('离线')) return InkPalette.reed;
  return InkPalette.pine;
}

IconData _deviceIcon(String type) {
  return switch (type) {
    'float' => Icons.sensors_rounded,
    'sonar' => Icons.radar_rounded,
    'box' => Icons.inventory_2_rounded,
    'umbrella' => Icons.beach_access_rounded,
    'platform' => Icons.layers_rounded,
    _ => Icons.settings_input_antenna_rounded,
  };
}

String _deviceTypeName(String type) {
  return switch (type) {
    'float' => '智能鱼漂',
    'sonar' => '智能探鱼器',
    'box' => '智能钓箱',
    'umbrella' => '智能钓伞',
    'platform' => '智能钓台',
    _ => '智能设备',
  };
}

Color _deviceColor(String type) {
  return switch (type) {
    'float' => InkPalette.pine,
    'sonar' => InkPalette.lake,
    'box' => InkPalette.moss,
    'umbrella' => InkPalette.reed,
    'platform' => InkPalette.lake,
    _ => InkPalette.pine,
  };
}

bool _isCoreDevice(IotDeviceState device) {
  return const {'float', 'box', 'platform', 'umbrella'}.contains(device.type);
}

bool _isAbnormalDevice(IotDeviceState device) {
  return device.riskLabel == '提醒' ||
      device.riskLabel == '待校准' ||
      device.riskLabel == '异常';
}

String _benefitDescription(String label) {
  return switch (label) {
    '高级作钓报告' => '生成天气、水情、鱼口和装备联动复盘。',
    '多设备绑定' => '鱼漂、钓箱、钓台、钓伞可统一接入。',
    '90 天历史数据' => '保留更长周期趋势，支持复盘对比。',
    '鱼情分析' => '结合钓点、鱼获和设备数据输出建议。',
    '钓场优惠' => '热门钓场预约和活动报名享会员优惠。',
    '商城会员价' => '智能设备、耗材和配件享专属价格。',
    '设备延保' => '核心装备延长保修并保留服务记录。',
    '专属客服' => '订单、售后和设备问题优先响应。',
    _ => 'Pro 权益可提升完整智能作钓体验。',
  };
}
