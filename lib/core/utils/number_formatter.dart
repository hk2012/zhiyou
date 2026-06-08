String formatCompactNumber(int? value) {
  if (value == null) return '--';
  if (value >= 10000) {
    final wan = value / 10000;
    return '${wan.toStringAsFixed(wan >= 10 ? 0 : 1)}w';
  }
  return value.toString();
}
