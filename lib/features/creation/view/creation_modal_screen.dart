import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../../features/creation/data/catch_journal_repository.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class CreationModalScreen extends ConsumerStatefulWidget {
  const CreationModalScreen({super.key, this.initialSpot});

  final String? initialSpot;

  @override
  ConsumerState<CreationModalScreen> createState() =>
      _CreationModalScreenState();
}

class _CreationModalScreenState extends ConsumerState<CreationModalScreen> {
  final _lengthController = TextEditingController(text: '42');
  final _weightController = TextEditingController(text: '1.6');
  final _noteController = TextEditingController(text: '早口窗口很短，亮片快搜有追口。');

  int _step = 0;
  bool _autoLayout = true;
  bool _savingDraft = false;
  bool _publishing = false;
  final List<String> _photoPaths = [];

  Future<void> _handlePhotoCapture() async {
    showInkActionSheet(
      context,
      title: '添加照片',
      subtitle: '支持现场拍摄或从相册多选',
      icon: Icons.camera_alt_rounded,
      actions: [
        InkSheetAction(
          title: '拍一张照片',
          subtitle: '记录当下实况',
          icon: Icons.camera_alt_outlined,
          onTap: () async {
            final status = await Permission.camera.request();
            if (status.isGranted) {
              final photo = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (photo != null && mounted) {
                setState(() => _photoPaths.add(photo.path));
              }
            }
          },
        ),
        InkSheetAction(
          title: '从相册选择',
          subtitle: '支持多图模式',
          icon: Icons.photo_library_outlined,
          onTap: () async {
            final status = await Permission.photos.request();
            if (status.isGranted || status.isLimited) {
              final photos = await ImagePicker().pickMultiImage();
              if (photos.isNotEmpty && mounted) {
                setState(() => _photoPaths.addAll(photos.map((e) => e.path)));
              }
            }
          },
        ),
      ],
    );
  }

  String _spot = '千岛湖 · 东南湖区';
  String _fish = '翘嘴';
  String _method = '路亚亮片';
  String _waterClarity = '微浑';
  String _bite = '连续追口';
  String _device = '已同步';
  String _visibility = '公开';

  @override
  void dispose() {
    _lengthController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initialSpot = widget.initialSpot?.trim();
    if (initialSpot != null && initialSpot.isNotEmpty) {
      _spot = initialSpot;
    }
  }

  bool get _busy => _savingDraft || _publishing;

  int get _probability {
    if (_fish == '翘嘴') return 87;
    if (_fish == '鲫鱼') return 72;
    if (_fish == '鲤鱼') return 48;
    return 64;
  }

  String get _title {
    if (!_autoLayout) return '$_spot · $_fish记录';
    final size = _lengthController.text.trim();
    final suffix = size.isEmpty ? '' : ' ${size}cm';
    return '今日$_fish$suffix，$_method命中';
  }

  String get _shareCopy {
    final length = _lengthController.text.trim();
    final weight = _weightController.text.trim();
    final note = _noteController.text.trim();
    final sizeText = [
      if (length.isNotEmpty) '${length}cm',
      if (weight.isNotEmpty) '$weight斤',
    ].join(' · ');
    final sizeLine = sizeText.isEmpty ? '' : '$sizeText · ';
    return '$sizeLine$_spot，$_waterClarity，$_bite。$_method，$_device。$note';
  }

  void _nextStep() {
    if (_step >= 2) return;
    setState(() => _step += 1);
  }

  Future<void> _saveRecord({required bool publish}) async {
    if (_busy) return;
    setState(() {
      if (publish) {
        _publishing = true;
      } else {
        _savingDraft = true;
      }
    });

    try {
      final result = await ref
          .read(catchJournalRepositoryProvider)
          .save(
            spotName: _spot,
            fish: _fish,
            method: _method,
            waterClarity: _waterClarity,
            biteStatus: _bite,
            deviceStatus: _device,
            probability: _probability,
            title: _title,
            shareCopy: _shareCopy,
            visibility: publish ? _publishVisibility : 'private',
            status: publish ? 'published' : 'draft',
            autoLayout: _autoLayout,
            photoLabels: _photoPaths.isNotEmpty
                ? [_fish, _method, _waterClarity]
                : [],
            lengthCm: _numberFrom(_lengthController.text),
            weightJin: _numberFrom(_weightController.text),
            notes: _noteController.text,
          );

      if (!mounted) return;
      final action = publish
          ? _publishVisibility == 'private'
                ? '已保存为仅自己可见'
                : '发布成功'
          : '已保存草稿';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action：${result.title}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: InkPalette.ink,
        ),
      );
      if (publish) {
        await Future<void>.delayed(const Duration(milliseconds: 360));
        if (mounted) context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? '发布失败，请稍后重试' : '保存失败，请稍后重试'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: InkPalette.cinnabar,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingDraft = false;
          _publishing = false;
        });
      }
    }
  }

  String get _publishVisibility {
    if (_visibility == '仅自己') return 'private';
    if (_visibility == '钓友可见') return 'card';
    return 'public';
  }

  double? _numberFrom(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final maxWidth = MediaQuery.sizeOf(context).width >= 560
        ? 430.0
        : double.infinity;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: InkPalette.ink.withValues(alpha: 0.18)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                child: SizedBox(
                  height: height,
                  child: InkGlassCard(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      10.h,
                      16.w,
                      14.h + safeBottom,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 42.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: InkPalette.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _CreationHeader(onClose: () => context.pop()),
                        SizedBox(height: 14.h),
                        _CreationFlow(
                          activeStep: _step,
                          onStep: (step) => setState(() => _step = step),
                        ),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            child: SingleChildScrollView(
                              key: ValueKey(_step),
                              physics: const BouncingScrollPhysics(),
                              child: _buildStepBody(),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _CreationFooter(
                          step: _step,
                          savingDraft: _savingDraft,
                          publishing: _publishing,
                          onNext: _nextStep,
                          onDraft: () => _saveRecord(publish: false),
                          onPublish: () => _saveRecord(publish: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    if (_step == 0) {
      return _CatchBasicsStep(
        spot: _spot,
        fish: _fish,
        lengthController: _lengthController,
        weightController: _weightController,
        photoPaths: _photoPaths,
        onSpot: (value) => setState(() => _spot = value),
        onFish: (value) => setState(() => _fish = value),
        onPhotoTap: _handlePhotoCapture,
      );
    }
    if (_step == 1) {
      return _CatchConditionStep(
        method: _method,
        waterClarity: _waterClarity,
        bite: _bite,
        device: _device,
        noteController: _noteController,
        onMethod: (value) => setState(() => _method = value),
        onWaterClarity: (value) => setState(() => _waterClarity = value),
        onBite: (value) => setState(() => _bite = value),
        onDevice: (value) => setState(() => _device = value),
      );
    }
    return _CatchPreviewStep(
      autoLayout: _autoLayout,
      title: _title,
      shareCopy: _shareCopy,
      spot: _spot,
      fish: _fish,
      method: _method,
      waterClarity: _waterClarity,
      bite: _bite,
      device: _device,
      visibility: _visibility,
      probability: _probability,
      hasPhoto: _photoPaths.isNotEmpty,
      onAutoLayout: (value) => setState(() => _autoLayout = value),
      onVisibility: (value) => setState(() => _visibility = value),
    );
  }
}

class _CreationHeader extends StatelessWidget {
  const _CreationHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkIconMark(
          icon: Icons.add_circle_outline_rounded,
          color: InkPalette.pine,
          size: 46,
          iconSize: 24,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '记录这次出钓',
                style: TextStyle(
                  color: InkPalette.text,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w900,
                  fontFamilyFallback: brushFontFallback,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                '少填表，多沉淀：鱼获、鱼情、复盘一并归档',
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
        InkRoundButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _CreationFlow extends StatelessWidget {
  const _CreationFlow({required this.activeStep, required this.onStep});

  final int activeStep;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.place_rounded, '选水域'),
      (Icons.set_meal_rounded, '填鱼情'),
      (Icons.auto_awesome_rounded, '预览发布'),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: InkPalette.paper.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkPressable(
                onTap: () => onStep(i),
                child: Column(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: i == activeStep
                            ? InkPalette.pine
                            : InkPalette.white.withValues(alpha: 0.70),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == activeStep
                              ? InkPalette.pine
                              : InkPalette.line,
                        ),
                      ),
                      child: Icon(
                        steps[i].$1,
                        color: i == activeStep
                            ? InkPalette.white
                            : InkPalette.pine,
                        size: 16.w,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      steps[i].$2,
                      style: TextStyle(
                        color: i == activeStep
                            ? InkPalette.pine
                            : InkPalette.text,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != steps.length - 1)
              Icon(
                Icons.chevron_right_rounded,
                color: InkPalette.muted,
                size: 18.w,
              ),
          ],
        ],
      ),
    );
  }
}

class _CatchBasicsStep extends StatelessWidget {
  const _CatchBasicsStep({
    required this.spot,
    required this.fish,
    required this.lengthController,
    required this.weightController,
    required this.photoPaths,
    required this.onSpot,
    required this.onFish,
    required this.onPhotoTap,
  });

  final String spot;
  final String fish;
  final TextEditingController lengthController;
  final TextEditingController weightController;
  final List<String> photoPaths;
  final ValueChanged<String> onSpot;
  final ValueChanged<String> onFish;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GuideCard(
          icon: Icons.touch_app_rounded,
          title: '先填 3 个关键事实',
          subtitle: '水域、鱼种、尺寸重量会决定鱼获档案和社区卡片的主信息。',
          color: InkPalette.pine,
        ),
        SizedBox(height: 10.h),
        _PhotoStubCard(photoPaths: photoPaths, fish: fish, onTap: onPhotoTap),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '水域',
          subtitle: '默认带入最近推荐钓点，允许手动切换。',
          options: const ['千岛湖 · 东南湖区', '支流回水湾', '老码头', '湘湖草边'],
          selected: spot,
          color: InkPalette.lake,
          onSelected: onSpot,
        ),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '鱼种',
          subtitle: '鱼种会进入下一次鱼情模型，是最重要的标签。',
          options: const ['翘嘴', '鲫鱼', '鲤鱼', '鲶鱼', '鲈鱼', '黄颡'],
          selected: fish,
          color: InkPalette.moss,
          onSelected: onFish,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MiniInputCard(
                title: '尺寸 cm',
                icon: Icons.straighten_rounded,
                controller: lengthController,
                color: InkPalette.reed,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MiniInputCard(
                title: '重量 斤',
                icon: Icons.monitor_weight_rounded,
                controller: weightController,
                color: InkPalette.pine,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatchConditionStep extends StatelessWidget {
  const _CatchConditionStep({
    required this.method,
    required this.waterClarity,
    required this.bite,
    required this.device,
    required this.noteController,
    required this.onMethod,
    required this.onWaterClarity,
    required this.onBite,
    required this.onDevice,
  });

  final String method;
  final String waterClarity;
  final String bite;
  final String device;
  final TextEditingController noteController;
  final ValueChanged<String> onMethod;
  final ValueChanged<String> onWaterClarity;
  final ValueChanged<String> onBite;
  final ValueChanged<String> onDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GuideCard(
          icon: Icons.analytics_rounded,
          title: '这些信息会反哺推荐',
          subtitle: '钓法、水色、鱼口和设备数据会用于下一次推荐置信度。',
          color: InkPalette.lake,
        ),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '钓法',
          subtitle: '用于匹配装备、鱼层和窗口期。',
          options: const ['路亚亮片', '米诺慢控', '腥饵台钓', '蚯蚓守底', '飞铅白条'],
          selected: method,
          color: InkPalette.pine,
          onSelected: onMethod,
        ),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '水色',
          subtitle: '决定饵色、味型和搜索速度。',
          options: const ['清水', '微浑', '泥水'],
          selected: waterClarity,
          color: InkPalette.lake,
          onSelected: onWaterClarity,
        ),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '鱼口',
          subtitle: '让复盘能判断是窗口、站位还是钓法问题。',
          options: const ['连续追口', '轻口', '只蹭线', '无口', '跑鱼'],
          selected: bite,
          color: InkPalette.reed,
          onSelected: onBite,
        ),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '设备',
          subtitle: '同步水温、水深、电量，也可以手动记录。',
          options: const ['已同步', '手动填写', '未连接'],
          selected: device,
          color: InkPalette.moss,
          onSelected: onDevice,
        ),
        SizedBox(height: 10.h),
        _NoteCard(controller: noteController),
      ],
    );
  }
}

class _CatchPreviewStep extends StatelessWidget {
  const _CatchPreviewStep({
    required this.autoLayout,
    required this.title,
    required this.shareCopy,
    required this.spot,
    required this.fish,
    required this.method,
    required this.waterClarity,
    required this.bite,
    required this.device,
    required this.visibility,
    required this.probability,
    required this.hasPhoto,
    required this.onAutoLayout,
    required this.onVisibility,
  });

  final bool autoLayout;
  final String title;
  final String shareCopy;
  final String spot;
  final String fish;
  final String method;
  final String waterClarity;
  final String bite;
  final String device;
  final String visibility;
  final int probability;
  final bool hasPhoto;
  final ValueChanged<bool> onAutoLayout;
  final ValueChanged<String> onVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AutoLayoutCard(enabled: autoLayout, onChanged: onAutoLayout),
        SizedBox(height: 10.h),
        _OptionCard(
          title: '发布范围',
          subtitle: '草稿始终仅自己可见；发布时按这里的范围展示。',
          options: const ['公开', '钓友可见', '仅自己'],
          selected: visibility,
          color: InkPalette.pine,
          onSelected: onVisibility,
        ),
        SizedBox(height: 10.h),
        _PreviewPostCard(
          title: title,
          shareCopy: shareCopy,
          spot: spot,
          fish: fish,
          method: method,
          waterClarity: waterClarity,
          bite: bite,
          device: device,
          probability: probability,
          hasPhoto: hasPhoto,
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.white.withValues(alpha: 0.84),
      borderColor: color.withValues(alpha: 0.14),
      child: Row(
        children: [
          InkIconMark(icon: icon, color: color, size: 38, iconSize: 18),
          SizedBox(width: 10.w),
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
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.36,
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

class _PhotoStubCard extends StatelessWidget {
  const _PhotoStubCard({
    required this.photoPaths,
    required this.fish,
    required this.onTap,
  });

  final List<String> photoPaths;
  final String fish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) {
      return InkCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 140.h,
          decoration: BoxDecoration(
            color: InkPalette.ink.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                color: InkPalette.muted,
                size: 28.w,
              ),
              SizedBox(height: 8.h),
              Text(
                '添加鱼获照片',
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              scrollDirection: Axis.horizontal,
              itemCount: photoPaths.length + 1,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                if (index == photoPaths.length) {
                  return Container(
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: InkPalette.rice.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: InkPalette.line),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: InkPalette.muted,
                        size: 32.w,
                      ),
                    ),
                  );
                }
                return Container(
                  width: 140.w,
                  decoration: BoxDecoration(
                    color: InkPalette.ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12.r),
                    image: DecorationImage(
                      image: FileImage(File(photoPaths[index])),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: InkPalette.ink.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: InkPalette.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.center_focus_weak_rounded,
                        color: InkPalette.pine,
                        size: 14.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'AI 已识别: $fish',
                        style: TextStyle(
                          color: InkPalette.pine,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '已选 ${photoPaths.length} 张',
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.paper.withValues(alpha: 0.72),
      borderColor: color.withValues(alpha: 0.13),
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
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: TextStyle(
              color: InkPalette.muted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final option in options)
                InkChip(
                  label: option,
                  active: option == selected,
                  color: color,
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInputCard extends StatelessWidget {
  const _MiniInputCard({
    required this.title,
    required this.icon,
    required this.controller,
    required this.color,
  });

  final String title;
  final IconData icon;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
      color: InkPalette.paper.withValues(alpha: 0.72),
      borderColor: color.withValues(alpha: 0.13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15.w),
              SizedBox(width: 5.w),
              Text(
                title,
                style: TextStyle(
                  color: InkPalette.muted,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: '选填',
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: InkPalette.paper.withValues(alpha: 0.72),
      borderColor: InkPalette.line.withValues(alpha: 0.82),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '复盘备注',
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.5.sp,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '例如：几分钟来口、站位、饵色、跑鱼原因...',
              hintStyle: TextStyle(
                color: InkPalette.faint,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoLayoutCard extends StatelessWidget {
  const _AutoLayoutCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(11.r),
      color: enabled
          ? InkPalette.pine.withValues(alpha: 0.09)
          : InkPalette.paper.withValues(alpha: 0.72),
      borderColor: InkPalette.pine.withValues(alpha: 0.16),
      child: Row(
        children: [
          InkIconMark(
            icon: Icons.auto_fix_high_rounded,
            color: InkPalette.pine,
            size: 38,
            iconSize: 18,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '自动排版',
                  style: TextStyle(
                    color: InkPalette.text,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '自动生成标题、鱼获卡和分享文案，减少填表感。',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 11.5.sp,
                    height: 1.36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: InkPalette.white,
            activeTrackColor: InkPalette.pine,
            inactiveThumbColor: InkPalette.line,
            inactiveTrackColor: InkPalette.white.withValues(alpha: 0.78),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PreviewPostCard extends StatelessWidget {
  const _PreviewPostCard({
    required this.title,
    required this.shareCopy,
    required this.spot,
    required this.fish,
    required this.method,
    required this.waterClarity,
    required this.bite,
    required this.device,
    required this.probability,
    required this.hasPhoto,
  });

  final String title;
  final String shareCopy;
  final String spot;
  final String fish;
  final String method;
  final String waterClarity;
  final String bite;
  final String device;
  final int probability;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final tags = [fish, method, waterClarity, bite, device];

    return InkCard(
      padding: EdgeInsets.all(12.r),
      color: InkPalette.white.withValues(alpha: 0.90),
      borderColor: InkPalette.pine.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      InkPalette.pine,
                      InkPalette.lake.withValues(alpha: 0.86),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8.w,
                      bottom: -8.h,
                      child: Icon(
                        Icons.set_meal_rounded,
                        color: InkPalette.white.withValues(alpha: 0.16),
                        size: 56.w,
                      ),
                    ),
                    Center(
                      child: Icon(
                        hasPhoto
                            ? Icons.image_rounded
                            : Icons.photo_camera_rounded,
                        color: InkPalette.white,
                        size: 24.w,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 16.sp,
                        height: 1.22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      spot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    InkChip(
                      label: hasPhoto
                          ? '有图 · 命中 $probability%'
                          : '推荐命中 $probability%',
                      active: true,
                      color: InkPalette.pine,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            shareCopy,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 12.5.sp,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 11.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final tag in tags)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: InkPalette.pine.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: InkPalette.pine.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: InkPalette.text,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreationFooter extends StatelessWidget {
  const _CreationFooter({
    required this.step,
    required this.savingDraft,
    required this.publishing,
    required this.onNext,
    required this.onDraft,
    required this.onPublish,
  });

  final int step;
  final bool savingDraft;
  final bool publishing;
  final VoidCallback onNext;
  final VoidCallback onDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkPressable(
            onTap: onDraft,
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
                child: savingDraft
                    ? const InkTaijiLoader(size: 24, label: '')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_add_rounded,
                            color: InkPalette.pine,
                            size: 18.w,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '存草稿',
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
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: InkPrimaryButton(
            label: step < 2 ? '下一步' : '发布动态',
            icon: step < 2
                ? Icons.arrow_forward_rounded
                : Icons.cloud_upload_rounded,
            color: step < 2 ? InkPalette.pine : InkPalette.lake,
            busy: publishing,
            onTap: step < 2 ? onNext : onPublish,
          ),
        ),
      ],
    );
  }
}
