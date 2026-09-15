String formatInsightsEuroAmount(num? amount, String? currency) {
  if (amount == null) return '';
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final left = whole.length - i;
    buffer.write(whole[i]);
    if (left > 1 && left % 3 == 1) buffer.write('.');
  }
  final code = (currency ?? 'EUR').trim().isEmpty ? 'EUR' : currency!.trim();
  return '${buffer.toString()},${parts.last} $code';
}
