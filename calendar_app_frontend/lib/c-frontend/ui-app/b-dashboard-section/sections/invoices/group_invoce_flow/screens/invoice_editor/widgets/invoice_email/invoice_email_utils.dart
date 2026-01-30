part of '../invoice_email_widgets.dart';

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  int unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _quillToHtml(quill.Document doc) {
  final buffer = StringBuffer();
  for (final op in doc.toDelta().toList()) {
    if (op.key != 'insert') continue;
    final data = op.data;
    if (data is! String) continue;
    var text = data
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    text = text.replaceAll('\n', '<br/>');

    final attrs = op.attributes ?? const <String, dynamic>{};
    final isBold = attrs['bold'] == true;
    final isItalic = attrs['italic'] == true;
    final link = attrs['link'];

    if (link is String && link.isNotEmpty) {
      text = '<a href=\"$link\" target=\"_blank\" rel=\"noopener\">$text</a>';
    }
    if (isItalic) {
      text = '<em>$text</em>';
    }
    if (isBold) {
      text = '<strong>$text</strong>';
    }
    buffer.write(text);
  }
  return '<div style=\"white-space:pre-line;\">${buffer.toString()}</div>';
}
