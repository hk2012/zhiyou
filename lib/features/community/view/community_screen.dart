import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ink_app_widgets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTopic = 0;
  final Set<int> _likedPosts = {};
  final Set<int> _savedPosts = {};

  @override
  Widget build(BuildContext context) {
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
              title: '鱼圈',
              subtitle: '关注 · 发现 · 同城 · 成就',
              leading: Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: InkPalette.mist,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.forum_rounded,
                  color: InkPalette.pine,
                  size: 22.w,
                ),
              ),
              actions: [
                InkRoundButton(
                  icon: Icons.search_rounded,
                  onTap: () => _showCommunitySearchSheet(context),
                ),
                InkRoundButton(
                  icon: Icons.add_photo_alternate_rounded,
                  onTap: () => _showPublishSheet(context),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _topics.length,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  return InkChip(
                    label: _topics[index],
                    active: index == _selectedTopic,
                    color: index == _selectedTopic
                        ? InkPalette.pine
                        : InkPalette.lake,
                    onTap: () {
                      setState(() => _selectedTopic = index);
                      AppFeedback.showMessage(
                        context,
                        '已切换到 ${_topics[index]}',
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: const _CommunityHero(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 0),
              child: _PublishFlowCard(onTap: () => _showPublishSheet(context)),
            ),
            const InkSectionHeader(title: '今日推荐', subtitle: '优质动态与实战经验'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  for (var i = 0; i < _posts.length; i++) ...[
                    _PostCard(
                      post: _posts[i],
                      liked: _likedPosts.contains(i),
                      saved: _savedPosts.contains(i),
                      onTap: () => _showPostSheet(context, _posts[i]),
                      onLike: () {
                        setState(() {
                          _likedPosts.contains(i)
                              ? _likedPosts.remove(i)
                              : _likedPosts.add(i);
                        });
                      },
                      onSave: () {
                        setState(() {
                          _savedPosts.contains(i)
                              ? _savedPosts.remove(i)
                              : _savedPosts.add(i);
                        });
                      },
                    ),
                    if (i != _posts.length - 1) SizedBox(height: 12.h),
                  ],
                ],
              ),
            ),
            const InkSectionHeader(title: '成就与图鉴', subtitle: '低概率鱼获、挑战与鱼种收藏'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: const _AchievementSystemCard(),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 148.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: _achievements.length,
                separatorBuilder: (_, _) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final item = _achievements[index];
                  return SizedBox(
                    width: 150.w,
                    child: InkCard(
                      onTap: () => _showAchievementSheet(
                        context,
                        title: item.$2,
                        subtitle: item.$3,
                        icon: item.$1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$1, color: InkPalette.reed, size: 28.w),
                          const Spacer(),
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: InkPalette.text,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            item.$3,
                            style: TextStyle(
                              color: InkPalette.muted,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero();

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '江湖今日榜',
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        fontFamilyFallback: brushFontFallback,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const InkSeal(text: '热'),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '同城 126 条鱼情更新，花港浅湾热度上升，3 个战队正在约钓。',
                  style: TextStyle(
                    color: InkPalette.muted,
                    fontSize: 12.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: 96.w,
            child: const InkLandscapeHero(height: 92, bright: false),
          ),
        ],
      ),
    );
  }
}

class _PublishFlowCard extends StatelessWidget {
  const _PublishFlowCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.photo_camera_rounded, '拍图'),
      (Icons.place_rounded, '水域'),
      (Icons.set_meal_rounded, '鱼种'),
      (Icons.cloud_done_rounded, '发布'),
    ];
    return InkCard(
      padding: EdgeInsets.all(13.r),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InkInfoRow(
            icon: Icons.add_photo_alternate_rounded,
            title: '发布流程',
            subtitle: '动态、鱼情、攻略和渔获档案统一入口',
            trailing: '发布',
            color: InkPalette.pine,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(steps[i].$1, color: InkPalette.pine, size: 19.w),
                      SizedBox(height: 5.h),
                      Text(
                        steps[i].$2,
                        style: TextStyle(
                          color: InkPalette.text,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }
}

class _AchievementSystemCard extends StatelessWidget {
  const _AchievementSystemCard();

  @override
  Widget build(BuildContext context) {
    return InkCard(
      padding: EdgeInsets.all(13.r),
      onTap: () => _showAchievementSheet(
        context,
        title: '江湖成就中心',
        subtitle: '挑战、图鉴、徽章和个人荣誉墙',
        icon: Icons.workspace_premium_rounded,
      ),
      child: Column(
        children: [
          const InkInfoRow(
            icon: Icons.workspace_premium_rounded,
            title: '江湖成长体系',
            subtitle: '称号、勋章、图鉴和挑战都在这里沉淀',
            trailing: '进入',
            color: InkPalette.reed,
          ),
          SizedBox(height: 12.h),
          Row(
            children: const [
              Expanded(
                child: InkMetric(
                  value: '36/128',
                  label: '鱼种图鉴',
                  icon: Icons.menu_book_rounded,
                  color: InkPalette.lake,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: InkMetric(
                  value: '12枚',
                  label: '徽章',
                  icon: Icons.workspace_premium_rounded,
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: InkMetric(
                  value: '31天',
                  label: '连续出勤',
                  icon: Icons.local_fire_department_rounded,
                  color: InkPalette.pine,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: const [
              Expanded(
                child: _CommunityHonorMini(
                  icon: Icons.military_tech_rounded,
                  title: '称号榜',
                  subtitle: '雨后巡水者',
                  color: InkPalette.reed,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _CommunityHonorMini(
                  icon: Icons.emoji_events_rounded,
                  title: '勋章墙',
                  subtitle: '本月 +3',
                  color: InkPalette.pine,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _CommunityHonorMini(
                  icon: Icons.menu_book_rounded,
                  title: '图鉴',
                  subtitle: '鳜鱼已解锁',
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

class _CommunityHonorMini extends StatelessWidget {
  const _CommunityHonorMini({
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 5.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 11.sp,
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
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.liked,
    required this.saved,
    required this.onTap,
    required this.onLike,
    required this.onSave,
  });

  final _CommunityPost post;
  final bool liked;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: InkPalette.mist,
                child: Icon(
                  Icons.person_rounded,
                  color: InkPalette.pine,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: TextStyle(
                        color: InkPalette.text,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      post.meta,
                      style: TextStyle(
                        color: InkPalette.muted,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkChip(label: post.tag, active: true, color: InkPalette.moss),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            post.content,
            style: TextStyle(
              color: InkPalette.text,
              fontSize: 13.sp,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: InkLandscapeHero(height: 86, bright: true)),
              SizedBox(width: 8.w),
              Expanded(child: InkLandscapeHero(height: 86, bright: false)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _PostAction(
                icon: liked
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                value: liked ? '${int.parse(post.likes) + 1}' : post.likes,
                active: liked,
                onTap: onLike,
              ),
              SizedBox(width: 18.w),
              _PostAction(
                icon: Icons.chat_bubble_outline_rounded,
                value: post.comments,
                onTap: () => showInkActionSheet(
                  context,
                  title: '评论',
                  subtitle: '这条动态已有 ${post.comments} 条讨论',
                  icon: Icons.chat_bubble_outline_rounded,
                  actions: const [
                    InkSheetAction(
                      icon: Icons.edit_rounded,
                      title: '写评论',
                      subtitle: '补充你的钓法、天气或装备建议',
                      color: InkPalette.pine,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 18.w),
              _PostAction(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                value: saved ? '已收藏' : '收藏',
                active: saved,
                onTap: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.value,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? InkPalette.pine : InkPalette.muted;
    return InkPressable(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17.w),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPost {
  const _CommunityPost({
    required this.author,
    required this.meta,
    required this.tag,
    required this.content,
    required this.likes,
    required this.comments,
  });

  final String author;
  final String meta;
  final String tag;
  final String content;
  final String likes;
  final String comments;
}

const _topics = ['关注', '发现', '同城', '话题', '战队', '攻略'];

const _posts = [
  _CommunityPost(
    author: '江湖钓客',
    meta: '西湖区 · 20分钟前',
    tag: '鱼情实况',
    content: '清晨风小，花港一带近岸口不错。饵料别太腥，钓 1.2-1.8m 的缓坡更稳。',
    likes: '35',
    comments: '9',
  ),
  _CommunityPost(
    author: '山水之间',
    meta: '湘湖 · 1小时前',
    tag: '路亚',
    content: '今天亮片比米诺更好用，鱼群贴边巡游，抛投角度比饵型更关键。',
    likes: '128',
    comments: '21',
  ),
];

const _achievements = [
  (Icons.emoji_events_rounded, '低概率挑战', '雨后 20 分钟中鳜鱼'),
  (Icons.workspace_premium_rounded, '连续签到', '已坚持 31 天'),
  (Icons.volunteer_activism_rounded, '钓友互助', '本周帮助 8 人'),
];

void _showPublishSheet(BuildContext context) {
  showInkActionSheet(
    context,
    title: '发布到社区',
    subtitle: '选择内容类型，保持钓点隐私和安全提醒',
    icon: Icons.add_photo_alternate_rounded,
    color: InkPalette.pine,
    actions: const [
      InkSheetAction(
        icon: Icons.photo_camera_rounded,
        title: '发动态',
        subtitle: '图片、文字、话题和同城水域',
        color: InkPalette.lake,
      ),
      InkSheetAction(
        icon: Icons.set_meal_rounded,
        title: '报鱼情',
        subtitle: '鱼种、尺寸、钓法、天气和水情',
        color: InkPalette.pine,
      ),
      InkSheetAction(
        icon: Icons.edit_note_rounded,
        title: '写攻略',
        subtitle: '复盘钓法、装备和路线',
        color: InkPalette.moss,
      ),
    ],
  );
}

void _showPostSheet(BuildContext context, _CommunityPost post) {
  showInkActionSheet(
    context,
    title: post.author,
    subtitle: '${post.meta} · ${post.tag}',
    icon: Icons.forum_rounded,
    color: InkPalette.pine,
    showLandscape: true,
    children: [
      Text(
        post.content,
        style: TextStyle(
          color: InkPalette.text,
          fontSize: 13.sp,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.share_rounded,
        title: '分享动态',
        subtitle: '生成图文卡片或发送给钓友',
        color: InkPalette.lake,
      ),
      InkSheetAction(
        icon: Icons.flag_rounded,
        title: '钓点隐私',
        subtitle: '隐藏精确位置，只展示区域',
        color: InkPalette.moss,
      ),
    ],
  );
}

void _showAchievementSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  showInkActionSheet(
    context,
    title: title,
    subtitle: subtitle,
    icon: icon,
    color: InkPalette.reed,
    children: [
      Row(
        children: const [
          Expanded(
            child: InkMetric(
              value: '8',
              label: '称号',
              icon: Icons.military_tech_rounded,
              color: InkPalette.reed,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(
              value: '12',
              label: '勋章',
              icon: Icons.emoji_events_rounded,
              color: InkPalette.pine,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: InkMetric(
              value: '36',
              label: '图鉴',
              icon: Icons.menu_book_rounded,
              color: InkPalette.lake,
            ),
          ),
        ],
      ),
      SizedBox(height: 12.h),
      const InkInfoRow(
        icon: Icons.workspace_premium_rounded,
        title: '当前称号',
        subtitle: '雨后巡水者 · 雨后窗口命中率高于 70%',
        trailing: '佩戴中',
        color: InkPalette.reed,
      ),
      SizedBox(height: 10.h),
      const InkInfoRow(
        icon: Icons.set_meal_rounded,
        title: '最新图鉴',
        subtitle: '鳜鱼 · 雨后回水湾 · 亮片慢收',
        trailing: '稀有',
        color: InkPalette.lake,
      ),
      SizedBox(height: 10.h),
      const InkInfoRow(
        icon: Icons.emoji_events_rounded,
        title: '本月勋章',
        subtitle: '识水、守夜、互助已解锁',
        trailing: '+3',
        color: InkPalette.pine,
      ),
    ],
    actions: const [
      InkSheetAction(
        icon: Icons.workspace_premium_rounded,
        title: '查看成就详情',
        subtitle: '解锁条件、进度和奖励',
        color: InkPalette.pine,
      ),
      InkSheetAction(
        icon: Icons.ios_share_rounded,
        title: '生成成就海报',
        subtitle: '用于社区分享和个人主页展示',
        color: InkPalette.lake,
      ),
    ],
  );
}

void _showCommunitySearchSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: InkPalette.ink.withValues(alpha: 0.24),
    builder: (_) => const _CommunitySearchSheet(),
  );
}

class _CommunitySearchSheet extends StatefulWidget {
  const _CommunitySearchSheet();

  @override
  State<_CommunitySearchSheet> createState() => _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends State<_CommunitySearchSheet> {
  final _controller = TextEditingController(text: '雨后 鳜鱼');
  var _category = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CommunitySearchResult> get _results {
    final keyword = _controller.text.trim().toLowerCase();
    final terms = keyword
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    final category = _searchCategories[_category];
    return _communitySearchResults.where((item) {
      final categoryMatched = category == '全部' || item.category == category;
      final searchable =
          '${item.title}${item.subtitle}${item.meta}${item.category}'
              .toLowerCase();
      final keywordMatched =
          keyword.isEmpty || terms.every((term) => searchable.contains(term));
      return categoryMatched && keywordMatched;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: FractionallySizedBox(
          heightFactor: 0.84,
          child: InkGlassCard(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
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
                  title: '社区搜索',
                  subtitle: '找鱼情、钓点、钓法、钓友和战队',
                  color: InkPalette.pine,
                ),
                SizedBox(height: 14.h),
                _SearchInput(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 36.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _searchCategories.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) => InkChip(
                      label: _searchCategories[index],
                      active: _category == index,
                      color: index == 0 ? InkPalette.pine : InkPalette.lake,
                      onTap: () => setState(() => _category = index),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final tag in _hotSearchTags)
                      InkPressable(
                        onTap: () {
                          _controller.text = tag;
                          _controller.selection = TextSelection.collapsed(
                            offset: tag.length,
                          );
                          setState(() => _category = 0);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: InkPalette.paper.withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: InkPalette.line),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: InkPalette.muted,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: _results.isEmpty
                      ? const _SearchEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return InkCard(
                              padding: EdgeInsets.all(12.r),
                              color: InkPalette.paper.withValues(alpha: 0.74),
                              onTap: () {
                                Navigator.of(context).pop();
                                AppFeedback.showMessage(
                                  context,
                                  '已打开：${result.title}',
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkInfoRow(
                                    icon: result.icon,
                                    title: result.title,
                                    subtitle: result.subtitle,
                                    trailing: result.category,
                                    color: result.color,
                                  ),
                                  SizedBox(height: 10.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up_rounded,
                                        color: InkPalette.reed,
                                        size: 16.w,
                                      ),
                                      SizedBox(width: 5.w),
                                      Expanded(
                                        child: Text(
                                          result.meta,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: InkPalette.muted,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 12.h),
                InkPrimaryButton(
                  label: '保存搜索条件',
                  icon: Icons.bookmark_add_rounded,
                  onTap: () {
                    Navigator.of(context).pop();
                    AppFeedback.showMessage(context, '搜索条件已保存到鱼圈');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: InkPalette.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: InkPalette.line),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: InkPalette.pine, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: InkPalette.text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: '搜索鱼情、钓法、钓点或钓友',
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          InkPressable(
            onTap: () {
              controller.clear();
              onChanged('');
            },
            child: Icon(
              Icons.close_rounded,
              color: InkPalette.muted,
              size: 18.w,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkCard(
        padding: EdgeInsets.all(16.r),
        color: InkPalette.paper.withValues(alpha: 0.70),
        child: const InkInfoRow(
          icon: Icons.manage_search_rounded,
          title: '没有匹配内容',
          subtitle: '换个鱼种、水域或钓法关键词试试',
          color: InkPalette.lake,
        ),
      ),
    );
  }
}

class _CommunitySearchResult {
  const _CommunitySearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.category,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final String category;
  final Color color;
}

const _searchCategories = ['全部', '鱼情', '钓点', '钓法', '钓友'];

const _hotSearchTags = ['雨后 鳜鱼', '夜钓安全', '浅水翘嘴', '花港浅湾', '路亚亮片'];

const _communitySearchResults = [
  _CommunitySearchResult(
    icon: Icons.water_drop_rounded,
    title: '雨后鳜鱼窗口',
    subtitle: '水色微浑，缓流石边 05:30-08:10',
    meta: '24 条讨论 · 6 个同城钓点关联',
    category: '鱼情',
    color: InkPalette.lake,
  ),
  _CommunitySearchResult(
    icon: Icons.place_rounded,
    title: '花港浅湾',
    subtitle: '近岸草边，适合轻量路亚和短竿试探',
    meta: '热度上升 18% · 今日 9 人打卡',
    category: '钓点',
    color: InkPalette.pine,
  ),
  _CommunitySearchResult(
    icon: Icons.auto_awesome_rounded,
    title: '亮片慢收三段法',
    subtitle: '开局搜边，中段换层，最后守结构',
    meta: '成功率 68% · 适配翘嘴/鳜鱼',
    category: '钓法',
    color: InkPalette.reed,
  ),
  _CommunitySearchResult(
    icon: Icons.person_search_rounded,
    title: '山水之间',
    subtitle: '同城路亚玩家，擅长雨后浅水搜索',
    meta: '128 条动态 · 12 枚成就',
    category: '钓友',
    color: InkPalette.moss,
  ),
];
