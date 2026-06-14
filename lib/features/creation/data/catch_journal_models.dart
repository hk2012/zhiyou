class CatchJournalResult {
  const CatchJournalResult({
    required this.id,
    required this.title,
    required this.shareCopy,
    required this.status,
    required this.visibility,
    required this.layoutBlocks,
  });

  final int id;
  final String title;
  final String shareCopy;
  final String status;
  final String visibility;
  final List<CatchJournalLayoutBlock> layoutBlocks;

  factory CatchJournalResult.fromJson(Map<String, dynamic> json) {
    return CatchJournalResult(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      shareCopy: json['share_copy']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? '',
      layoutBlocks: _asList(
        json['layout_blocks'],
        CatchJournalLayoutBlock.fromJson,
      ),
    );
  }
}

class CatchJournalLayoutBlock {
  const CatchJournalLayoutBlock({
    required this.type,
    required this.title,
    required this.value,
  });

  final String type;
  final String title;
  final String value;

  factory CatchJournalLayoutBlock.fromJson(Map<String, dynamic> json) {
    return CatchJournalLayoutBlock(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<T> _asList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value.map((item) => fromJson(_asMap(item))).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
