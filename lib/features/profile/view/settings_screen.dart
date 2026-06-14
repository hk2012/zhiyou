import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/data/auth_repository.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _fishAlertEnabled = true;
  bool _locationEnabled = true;
  bool _weatherThemeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return InkPage(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).viewPadding.bottom + 24.h,
        ),
        children: [
          InkTopBar(
            title: '设置',
            subtitle: '账号、隐私、主题和设备偏好',
            onBack: () => context.pop(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
            child: _SettingsHero(),
          ),
          const InkSectionHeader(title: '账号', subtitle: '安全、认证和钓点隐私'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.security_rounded,
                  color: InkPalette.pine,
                  title: '账号与安全',
                  subtitle: '手机号、密码、登录设备',
                  onTap: () => _comingSoon('账号与安全'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.privacy_tip_rounded,
                  color: InkPalette.lake,
                  title: '隐私设置',
                  subtitle: '公开资料、黑名单、钓点可见范围',
                  onTap: () => _comingSoon('隐私设置'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.badge_rounded,
                  color: InkPalette.reed,
                  title: '实名认证',
                  subtitle: '提升交易、租赁和活动可信度',
                  onTap: () => _comingSoon('实名认证'),
                ),
              ],
            ),
          ),
          const InkSectionHeader(title: '偏好', subtitle: '消息、水情、位置和动态主题'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              children: [
                _switchTile(
                  icon: Icons.notifications_active_rounded,
                  color: InkPalette.pine,
                  title: '消息通知',
                  subtitle: '活动、订单、评论与系统提醒',
                  value: _pushEnabled,
                  onChanged: (value) => setState(() => _pushEnabled = value),
                ),
                SizedBox(height: 10.h),
                _switchTile(
                  icon: Icons.campaign_rounded,
                  color: InkPalette.reed,
                  title: '鱼情提醒',
                  subtitle: '设备异常和鱼讯变化提醒',
                  value: _fishAlertEnabled,
                  onChanged: (value) =>
                      setState(() => _fishAlertEnabled = value),
                ),
                SizedBox(height: 10.h),
                _switchTile(
                  icon: Icons.location_on_rounded,
                  color: InkPalette.lake,
                  title: '位置服务',
                  subtitle: '用于推荐附近钓点和天气数据',
                  value: _locationEnabled,
                  onChanged: (value) =>
                      setState(() => _locationEnabled = value),
                ),
                SizedBox(height: 10.h),
                _switchTile(
                  icon: Icons.dark_mode_rounded,
                  color: InkPalette.moss,
                  title: '动态天气主题',
                  subtitle: '昼夜、雨雾、晴日主题跟随天气切换',
                  value: _weatherThemeEnabled,
                  onChanged: (value) =>
                      setState(() => _weatherThemeEnabled = value),
                ),
              ],
            ),
          ),
          const InkSectionHeader(title: '通用', subtitle: '缓存、语言、字体和设备数据'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.cleaning_services_rounded,
                  color: InkPalette.pine,
                  title: '清理缓存',
                  subtitle: '当前缓存约 128 MB',
                  trailing: '128 MB',
                  onTap: _clearCache,
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.language_rounded,
                  color: InkPalette.lake,
                  title: '语言',
                  subtitle: '简体中文，兼容跨区域钓旅内容',
                  trailing: '简体中文',
                  onTap: () => _comingSoon('语言设置'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.text_fields_rounded,
                  color: InkPalette.reed,
                  title: '字体大小',
                  subtitle: '夜钓、户外强光和攻略阅读优化',
                  trailing: '标准',
                  onTap: () => _comingSoon('字体大小'),
                ),
              ],
            ),
          ),
          const InkSectionHeader(title: '关于', subtitle: '协议、隐私政策、帮助和反馈'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.info_rounded,
                  color: InkPalette.pine,
                  title: '关于江湖钓客',
                  subtitle: '产品版本、设计规范和服务说明',
                  trailing: '1.0.0',
                  onTap: () => _comingSoon('关于江湖钓客'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.description_rounded,
                  color: InkPalette.lake,
                  title: '用户协议',
                  subtitle: '平台内容、交易和社区规则',
                  onTap: () => _comingSoon('用户协议'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.policy_rounded,
                  color: InkPalette.moss,
                  title: '隐私政策',
                  subtitle: '位置、钓点、设备和订单数据说明',
                  onTap: () => _comingSoon('隐私政策'),
                ),
                SizedBox(height: 10.h),
                _menuTile(
                  icon: Icons.support_agent_rounded,
                  color: InkPalette.reed,
                  title: '帮助与反馈',
                  subtitle: '客服、问题反馈、意见建议',
                  onTap: () => _comingSoon('帮助与反馈'),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              children: [
                _accountActionButton(
                  label: '切换账号',
                  icon: Icons.switch_account_rounded,
                  color: InkPalette.pine,
                  onTap: () =>
                      _confirmAccountAction(context, switchAccount: true),
                ),
                SizedBox(height: 10.h),
                _accountActionButton(
                  label: '退出登录',
                  icon: Icons.logout_rounded,
                  color: InkPalette.cinnabar,
                  onTap: () =>
                      _confirmAccountAction(context, switchAccount: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
      child: Row(
        children: [
          _SettingsIcon(icon: icon, color: color),
          SizedBox(width: 12.w),
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color,
            inactiveTrackColor: InkPalette.line,
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
      onTap: onTap,
      child: InkInfoRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing ?? '进入',
        color: color,
      ),
    );
  }

  Widget _accountActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkPressable(
      onTap: onTap,
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18.w),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(String feature) {
    _showSettingsPanel(feature);
  }

  void _showSettingsPanel(String feature) {
    final rows = _settingRowsFor(feature);
    final spec = _settingPanelSpecFor(feature);
    showInkActionSheet(
      context,
      title: feature,
      subtitle: spec.subtitle,
      icon: spec.icon,
      color: spec.color,
      children: [
        _SettingStatusCard(spec: spec),
        SizedBox(height: 10.h),
        _SettingPreviewGrid(rows: rows),
      ],
      actions: rows
          .map(
            (row) => InkSheetAction(
              icon: row.icon,
              title: row.title,
              subtitle: row.subtitle,
              color: spec.color,
              onTap: () => AppFeedback.showMessage(context, '${row.title}已保存'),
            ),
          )
          .toList(),
    );
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    AppFeedback.showMessage(context, '缓存已清理');
  }

  Future<void> _confirmAccountAction(
    BuildContext context, {
    required bool switchAccount,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switchAccount ? '切换账号' : '退出登录'),
        content: Text(switchAccount ? '将退出当前账号并返回登录页。' : '确认退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _logout(context);
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(currentUserProvider);
    ref.invalidate(userStatsProvider);
    if (context.mounted) context.go(AppRouteNames.login);
  }
}

class _SettingsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              color: InkPalette.pine.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: InkPalette.pine.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(Icons.tune_rounded, color: InkPalette.pine, size: 28.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '现代产品规范',
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    fontFamilyFallback: brushFontFallback,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '通知、隐私、主题、设备和服务设置都保持同一套视觉语言。',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 12.sp,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const InkSeal(text: '设\n定'),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Icon(icon, color: color, size: 20.w),
    );
  }
}

class _SettingFeatureData {
  const _SettingFeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _SettingPanelSpec {
  const _SettingPanelSpec({
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.status,
    required this.title,
    required this.description,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryValue,
    required this.secondaryLabel,
  });

  final IconData icon;
  final Color color;
  final String subtitle;
  final String status;
  final String title;
  final String description;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryValue;
  final String secondaryLabel;
}

class _SettingStatusCard extends StatelessWidget {
  const _SettingStatusCard({required this.spec});

  final _SettingPanelSpec spec;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: spec.color.withValues(alpha: 0.09),
      borderColor: spec.color.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkIconMark(icon: spec.icon, color: spec.color, size: 42),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
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
                      spec.status,
                      style: TextStyle(
                        color: spec.color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            spec.description,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 12.sp,
              height: 1.42,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InkMetric(
                  value: spec.primaryValue,
                  label: spec.primaryLabel,
                  icon: Icons.done_all_rounded,
                  color: spec.color,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkMetric(
                  value: spec.secondaryValue,
                  label: spec.secondaryLabel,
                  icon: Icons.tune_rounded,
                  color: InkPalette.lake,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingPreviewGrid extends StatelessWidget {
  const _SettingPreviewGrid({required this.rows});

  final List<_SettingFeatureData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          InkCard(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            color: InkPalette.paper.withValues(alpha: 0.72),
            child: InkInfoRow(
              icon: rows[i].icon,
              title: rows[i].title,
              subtitle: rows[i].subtitle,
              trailing: i == 0 ? '推荐' : '可调',
              color: i == 0 ? InkPalette.pine : InkPalette.lake,
            ),
          ),
          if (i != rows.length - 1) SizedBox(height: 8.h),
        ],
      ],
    );
  }
}

_SettingPanelSpec _settingPanelSpecFor(String feature) {
  if (feature.contains('账号')) {
    return const _SettingPanelSpec(
      icon: Icons.security_rounded,
      color: InkPalette.pine,
      subtitle: '登录方式、设备记录和关键操作保护',
      status: '安全评分 86 · 未发现异常设备',
      title: '账号安全控制台',
      description: '把手机号、密码、验证码、登录设备和交易二次校验放在一个入口，用户能快速判断账号是否安全。',
      primaryValue: '2台',
      primaryLabel: '可信设备',
      secondaryValue: '验证码',
      secondaryLabel: '二次校验',
    );
  }
  if (feature.contains('隐私')) {
    return const _SettingPanelSpec(
      icon: Icons.privacy_tip_rounded,
      color: InkPalette.lake,
      subtitle: '资料、位置、钓点和数据共享范围',
      status: '钓点脱敏已开启 · 精确坐标不公开',
      title: '钓点隐私护栏',
      description: '发布鱼获、分享路线和展示主页时，默认保护精确坐标，只保留对钓友有价值的大致水域信息。',
      primaryValue: '脱敏',
      primaryLabel: '默认分享',
      secondaryValue: '3项',
      secondaryLabel: '可见范围',
    );
  }
  if (feature.contains('认证')) {
    return const _SettingPanelSpec(
      icon: Icons.badge_rounded,
      color: InkPalette.reed,
      subtitle: '交易、活动报名和服务信用认证',
      status: '资料待提交 · 可先查看认证权益',
      title: '实名认证流程',
      description: '认证页应该强调可信交易、活动安全和服务履约，不把用户困在复杂表单里。',
      primaryValue: '3步',
      primaryLabel: '认证流程',
      secondaryValue: '信用+',
      secondaryLabel: '权益提升',
    );
  }
  if (feature.contains('语言')) {
    return const _SettingPanelSpec(
      icon: Icons.language_rounded,
      color: InkPalette.lake,
      subtitle: '中文内容优先，兼容跨区域钓旅',
      status: '当前简体中文 · 内容单位自动跟随地区',
      title: '语言与地区',
      description: '语言设置不只切换文字，还要处理鱼种名、长度重量单位、天气表达和本地服务内容。',
      primaryValue: '中文',
      primaryLabel: '当前语言',
      secondaryValue: '公制',
      secondaryLabel: '默认单位',
    );
  }
  if (feature.contains('字体')) {
    return const _SettingPanelSpec(
      icon: Icons.text_fields_rounded,
      color: InkPalette.reed,
      subtitle: '夜钓、户外强光和攻略阅读优化',
      status: '标准字号 · 支持大字预览',
      title: '可读性调节',
      description: '字体设置要服务真实户外场景，重点保证强光、夜钓、湿手操作时还能看清关键信息。',
      primaryValue: '标准',
      primaryLabel: '当前字号',
      secondaryValue: '夜钓',
      secondaryLabel: '增强场景',
    );
  }
  if (feature.contains('反馈')) {
    return const _SettingPanelSpec(
      icon: Icons.support_agent_rounded,
      color: InkPalette.reed,
      subtitle: '客服、问题反馈和产品建议',
      status: '平均响应 12 分钟 · 可附页面与设备信息',
      title: '帮助与反馈中心',
      description: '反馈入口要能自动带上页面、设备、网络和水情上下文，减少用户描述成本。',
      primaryValue: '12分',
      primaryLabel: '响应预估',
      secondaryValue: '4类',
      secondaryLabel: '问题分类',
    );
  }
  if (feature.contains('政策')) {
    return const _SettingPanelSpec(
      icon: Icons.policy_rounded,
      color: InkPalette.moss,
      subtitle: '位置、钓点、设备和订单数据说明',
      status: '重点条款已拆分 · 支持快速定位',
      title: '隐私政策阅读器',
      description: '隐私政策应该按数据类型拆开，用户能直接看到位置、设备、订单、社区内容分别怎么使用。',
      primaryValue: '6类',
      primaryLabel: '数据说明',
      secondaryValue: '可撤回',
      secondaryLabel: '授权状态',
    );
  }
  if (feature.contains('协议')) {
    return const _SettingPanelSpec(
      icon: Icons.description_rounded,
      color: InkPalette.lake,
      subtitle: '平台内容、交易和社区规则',
      status: '核心规则已摘要 · 适合移动端阅读',
      title: '用户协议摘要',
      description: '协议页需要先给用户看得懂的重点摘要，再提供完整文本和历史版本。',
      primaryValue: '5节',
      primaryLabel: '规则摘要',
      secondaryValue: '版本1.0',
      secondaryLabel: '当前协议',
    );
  }
  return const _SettingPanelSpec(
    icon: Icons.info_rounded,
    color: InkPalette.pine,
    subtitle: '版本、设计规范和服务说明',
    status: '江湖钓客 1.0.0 · 现代智能版',
    title: '关于江湖钓客',
    description: '关于页展示产品定位、版本信息、设计语言、服务能力和联系方式，形成一个可信的品牌说明。',
    primaryValue: '1.0.0',
    primaryLabel: '当前版本',
    secondaryValue: '现代',
    secondaryLabel: '视觉风格',
  );
}

List<_SettingFeatureData> _settingRowsFor(String feature) {
  if (feature.contains('账号')) {
    return const [
      _SettingFeatureData(
        icon: Icons.phone_iphone_rounded,
        title: '手机号登录',
        subtitle: '用于验证码登录、找回账号和重要安全提醒。',
      ),
      _SettingFeatureData(
        icon: Icons.devices_rounded,
        title: '登录设备',
        subtitle: '记录最近登录设备，异常设备支持提醒和强制下线。',
      ),
      _SettingFeatureData(
        icon: Icons.lock_rounded,
        title: '安全校验',
        subtitle: '涉及交易、押金、实名认证时需要二次确认。',
      ),
    ];
  }
  if (feature.contains('隐私')) {
    return const [
      _SettingFeatureData(
        icon: Icons.location_off_rounded,
        title: '钓点脱敏',
        subtitle: '分享战绩时默认隐藏精确坐标，只展示大致水域。',
      ),
      _SettingFeatureData(
        icon: Icons.visibility_off_rounded,
        title: '资料可见范围',
        subtitle: '昵称、等级、战绩、装备和订单数据可分开控制。',
      ),
      _SettingFeatureData(
        icon: Icons.block_rounded,
        title: '黑名单',
        subtitle: '屏蔽私信、评论和动态互动，减少无效打扰。',
      ),
    ];
  }
  if (feature.contains('认证')) {
    return const [
      _SettingFeatureData(
        icon: Icons.badge_rounded,
        title: '身份资料',
        subtitle: '实名认证用于平台交易、活动报名和服务商信用。',
      ),
      _SettingFeatureData(
        icon: Icons.verified_user_rounded,
        title: '认证权益',
        subtitle: '认证后可提升二手交易、装备租赁、活动报名可信度。',
      ),
    ];
  }
  if (feature.contains('语言')) {
    return const [
      _SettingFeatureData(
        icon: Icons.check_circle_rounded,
        title: '简体中文',
        subtitle: '当前选中，适合国内钓友和中文内容生态。',
      ),
      _SettingFeatureData(
        icon: Icons.public_rounded,
        title: 'English / 日本語',
        subtitle: '为跨区域钓旅和国际向导服务预留内容结构。',
      ),
    ];
  }
  if (feature.contains('字体')) {
    return const [
      _SettingFeatureData(
        icon: Icons.text_fields_rounded,
        title: '标准',
        subtitle: '适合大多数列表、卡片和攻略阅读场景。',
      ),
      _SettingFeatureData(
        icon: Icons.format_size_rounded,
        title: '大字体',
        subtitle: '夜钓、户外强光和长文攻略阅读时更舒服。',
      ),
    ];
  }
  if (feature.contains('反馈')) {
    return const [
      _SettingFeatureData(
        icon: Icons.support_agent_rounded,
        title: '客服入口',
        subtitle: '订单、售后、账号和设备问题可以归类提交。',
      ),
      _SettingFeatureData(
        icon: Icons.bug_report_rounded,
        title: '问题反馈',
        subtitle: '记录页面、设备、接口或数据不准确的问题。',
      ),
      _SettingFeatureData(
        icon: Icons.lightbulb_rounded,
        title: '产品建议',
        subtitle: '例如新玩法、新鱼种、新钓场和首页卡片建议。',
      ),
    ];
  }
  return const [
    _SettingFeatureData(
      icon: Icons.info_rounded,
      title: '版本信息',
      subtitle: '江湖钓客 1.0.0，当前为现代智能开发版本。',
    ),
    _SettingFeatureData(
      icon: Icons.gavel_rounded,
      title: '平台规则',
      subtitle: '用户协议、隐私政策和内容规范统一归档。',
    ),
  ];
}
