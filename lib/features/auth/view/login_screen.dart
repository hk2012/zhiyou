import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../routes/app_route_names.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _phoneController = TextEditingController(text: '13800000000');
  final _passwordController = TextEditingController(text: '123456');
  final _codeController = TextEditingController(text: '8888');
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _errorText = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final code = _codeController.text.trim();
    final isCodeLogin = _tabController.index == 0;

    if (phone.isEmpty) {
      setState(() => _errorText = '请输入手机号');
      return;
    }
    if (isCodeLogin && code.isEmpty) {
      setState(() => _errorText = '请输入验证码');
      return;
    }
    if (!isCodeLogin && password.isEmpty) {
      setState(() => _errorText = '请输入密码');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .loginWithPassword(
            phone: phone,
            password: isCodeLogin ? '123456' : password,
          );
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      ref.invalidate(userStatsProvider);
      context.go(AppRouteNames.home);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorText = error.message);
    } on DioException catch (error) {
      if (mounted) setState(() => _errorText = _friendlyDioMessage(error));
    } catch (_) {
      if (mounted) setState(() => _errorText = '登录失败，请稍后再试');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyDioMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) return '手机号或密码不正确';
    if (statusCode == 404) return '登录接口未启动，请先启动后端服务';
    if (error.response != null) return '登录失败，请稍后再试';
    return '网络请求失败，请确认后端服务已启动';
  }

  void _mockRegister() {
    AppFeedback.showMessage(context, '演示账号已准备好，可直接登录');
  }

  void _showSocialLoginSheet(_SocialLoginProvider provider) {
    showInkActionSheet(
      context,
      title: provider.title,
      subtitle: '${provider.name}授权后自动绑定当前手机号与钓客档案',
      icon: provider.icon,
      color: provider.color,
      children: [
        Row(
          children: [
            Expanded(
              child: InkMetric(
                value: '安全',
                label: '授权状态',
                icon: Icons.verified_user_rounded,
                color: provider.color,
              ),
            ),
            SizedBox(width: 8.w),
            const Expanded(
              child: InkMetric(
                value: '3项',
                label: '授权范围',
                icon: Icons.rule_rounded,
                color: InkPalette.lake,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        InkCard(
          padding: EdgeInsets.all(12.r),
          color: InkPalette.paper.withValues(alpha: 0.72),
          child: const Column(
            children: [
              InkInfoRow(
                icon: Icons.person_rounded,
                title: '读取基础资料',
                subtitle: '昵称、头像和授权标识，用于创建钓客名片',
                color: InkPalette.pine,
              ),
              SizedBox(height: 8),
              InkInfoRow(
                icon: Icons.phone_iphone_rounded,
                title: '绑定本机手机号',
                subtitle: '交易、设备和安全提醒仍以手机号为主账号',
                color: InkPalette.lake,
              ),
              SizedBox(height: 8),
              InkInfoRow(
                icon: Icons.lock_rounded,
                title: '保护钓点隐私',
                subtitle: '第三方平台不获取你的精确钓点坐标',
                color: InkPalette.moss,
              ),
            ],
          ),
        ),
      ],
      actions: [
        InkSheetAction(
          icon: Icons.login_rounded,
          title: '演示授权登录',
          subtitle: '使用当前演示账号完成一遍授权登录流程',
          color: provider.color,
          onTap: _handleLogin,
        ),
        InkSheetAction(
          icon: Icons.phone_android_rounded,
          title: '绑定手机号',
          subtitle: '验证码校验后合并历史鱼获和收藏钓点',
          color: InkPalette.lake,
          onTap: () => AppFeedback.showMessage(context, '手机号绑定流程已保存为前端方案'),
        ),
        InkSheetAction(
          icon: Icons.policy_rounded,
          title: '查看授权范围',
          subtitle: '展示平台会读取和不会读取的数据',
          color: InkPalette.moss,
          onTap: () => AppFeedback.showMessage(context, '授权范围已展示'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width >= 560 ? 430.0 : double.infinity;

    return Scaffold(
      backgroundColor: InkPalette.rice,
      body: Stack(
        children: [
          const Positioned.fill(child: InkBackdrop(opacity: 0.96)),
          Positioned(
            top: -36.h,
            left: -40.w,
            right: -40.w,
            height: math.max(360.h, media.size.height * 0.48),
            child: const InkLandscapeHero(height: 390, bright: true),
          ),
          Positioned(
            top: media.padding.top + 22.h,
            right: 22.w,
            child: const InkSeal(text: '江湖\n钓客'),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    34.h,
                    20.w,
                    media.viewPadding.bottom + 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      const InkBrand(
                        color: InkPalette.white,
                        subtitleColor: InkPalette.white,
                      ),
                      SizedBox(height: media.size.height < 720 ? 135.h : 190.h),
                      InkGlassCard(
                        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LoginTabs(controller: _tabController),
                            SizedBox(height: 16.h),
                            _LoginInput(
                              controller: _phoneController,
                              icon: Icons.phone_iphone_rounded,
                              hint: '请输入手机号',
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 12.h),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _tabController.index == 0
                                  ? _LoginInput(
                                      key: const ValueKey('code'),
                                      controller: _codeController,
                                      icon: Icons.lock_clock_rounded,
                                      hint: '请输入验证码',
                                      keyboardType: TextInputType.number,
                                      trailing: GestureDetector(
                                        onTap: () => AppFeedback.showMessage(
                                          context,
                                          '验证码已发送：8888',
                                        ),
                                        child: Text(
                                          '获取验证码',
                                          style: TextStyle(
                                            color: InkPalette.pine,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _LoginInput(
                                      key: const ValueKey('password'),
                                      controller: _passwordController,
                                      icon: Icons.lock_outline_rounded,
                                      hint: '请输入密码',
                                      obscureText: _obscurePassword,
                                      trailing: GestureDetector(
                                        onTap: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: InkPalette.muted,
                                          size: 19.w,
                                        ),
                                      ),
                                    ),
                            ),
                            if (_errorText != null) ...[
                              SizedBox(height: 10.h),
                              Text(
                                _errorText!,
                                style: TextStyle(
                                  color: InkPalette.cinnabar,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            SizedBox(height: 18.h),
                            InkPrimaryButton(
                              label: '立即登录',
                              busy: _isSubmitting,
                              onTap: _handleLogin,
                            ),
                            SizedBox(height: 15.h),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _mockRegister,
                                  child: const Text('注册新账号'),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => AppFeedback.showMessage(
                                    context,
                                    '演示密码：123456',
                                  ),
                                  child: const Text('忘记密码'),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            _SocialLoginRow(
                              onProviderTap: _showSocialLoginSheet,
                            ),
                            SizedBox(height: 12.h),
                            Center(
                              child: Text(
                                '登录即代表同意《用户协议》和《隐私政策》',
                                style: TextStyle(
                                  color: InkPalette.faint,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTabs extends StatelessWidget {
  const _LoginTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: InkPalette.paper.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: InkPalette.line),
          ),
          child: Row(
            children: [
              _LoginTabButton(
                label: '验证码登录',
                active: controller.index == 0,
                onTap: () => controller.animateTo(0),
              ),
              _LoginTabButton(
                label: '密码登录',
                active: controller.index == 1,
                onTap: () => controller.animateTo(1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginTabButton extends StatelessWidget {
  const _LoginTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36.h,
          decoration: BoxDecoration(
            color: active ? InkPalette.pine : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? InkPalette.white : InkPalette.muted,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: InkPalette.pine, size: 19.w),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: InkPalette.faint,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SocialLoginRow extends StatelessWidget {
  const _SocialLoginRow({required this.onProviderTap});

  final ValueChanged<_SocialLoginProvider> onProviderTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in _socialLoginProviders) ...[
          InkPressable(
            onTap: () => onProviderTap(item),
            rippleColor: item.color,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(color: item.color.withValues(alpha: 0.28)),
              ),
              child: Icon(item.icon, color: item.color, size: 21.w),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ],
    );
  }
}

class _SocialLoginProvider {
  const _SocialLoginProvider({
    required this.icon,
    required this.name,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String name;
  final String title;
  final Color color;
}

const _socialLoginProviders = [
  _SocialLoginProvider(
    icon: Icons.wechat_rounded,
    name: '微信',
    title: '微信快捷登录',
    color: InkPalette.moss,
  ),
  _SocialLoginProvider(
    icon: Icons.phone_android_rounded,
    name: '本机号码',
    title: '本机号码一键登录',
    color: InkPalette.lake,
  ),
  _SocialLoginProvider(
    icon: Icons.person_rounded,
    name: '游客档案',
    title: '游客档案登录',
    color: InkPalette.reed,
  ),
];
