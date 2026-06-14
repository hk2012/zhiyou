class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.meta,
    required this.tag,
    required this.content,
    required this.likes,
    required this.comments,
  });

  final int id;
  final String author;
  final String meta;
  final String tag;
  final String content;
  final String likes;
  final String comments;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    // Map CatchJournalResponse to CommunityPost
    final id = json['id'] as int? ?? 0;
    final spotName = _cleanCommunityText(
      json['spot_name']?.toString() ?? '',
      fallback: '湘湖 · 下孙文化村',
    );
    final fish = _cleanFishLabel(json['fish']?.toString() ?? '');
    final method = _cleanMethodLabel(json['method']?.toString() ?? '');
    final title = _cleanCommunityText(json['title']?.toString() ?? '');
    final shareCopy = _cleanCommunityText(json['share_copy']?.toString() ?? '');

    final tag = fish.isNotEmpty ? fish : (method.isNotEmpty ? method : '鱼情实况');
    final content = shareCopy.isNotEmpty ? shareCopy : title;

    return CommunityPost(
      id: id,
      author: '江湖钓客',
      meta: '$spotName · 刚刚',
      tag: tag,
      content: content.isEmpty ? '雨后水位回稳，浅湾口有连续追口，建议先小饵慢搜。' : content,
      likes: '0',
      comments: '0',
    );
  }
}

String _cleanCommunityText(String value, {String fallback = ''}) {
  var text = value.trim();
  if (text.isEmpty) return fallback;

  text = text
      .replaceAll(RegExp(r'\bTest Spot\b', caseSensitive: false), '湘湖 · 下孙文化村')
      .replaceAll(RegExp(r'\bTest\b', caseSensitive: false), '路亚翘嘴')
      .replaceAll(RegExp(r'\bDemo Spot\b', caseSensitive: false), '西湖 · 花港观鱼')
      .replaceAll(RegExp(r'\s*,\s*'), '，')
      .replaceAll(RegExp(r'，+'), '，')
      .replaceAll('。路亚翘嘴，已同步', '。路亚翘嘴窗口已同步');

  final onlyPlaceholder = RegExp(
    r'^(路亚翘嘴|湘湖 · 下孙文化村)$',
    caseSensitive: false,
  ).hasMatch(text);
  if (onlyPlaceholder && fallback.isNotEmpty) return fallback;
  return text;
}

String _cleanFishLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (RegExp(r'^test$', caseSensitive: false).hasMatch(text)) return '翘嘴';
  return _cleanCommunityText(text);
}

String _cleanMethodLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (RegExp(r'^test$', caseSensitive: false).hasMatch(text)) return '路亚';
  return _cleanCommunityText(text);
}
