part of '../mail_compose_screen.dart';

String _inferMimeType(PlatformFile file) {
  final ext = file.extension?.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'txt':
      return 'text/plain';
    case 'html':
    case 'htm':
      return 'text/html';
    case 'csv':
      return 'text/csv';
    case 'json':
      return 'application/json';
    default:
      return 'application/octet-stream';
  }
}

String _quillToHtml(quill.Document doc) {
  final buffer = StringBuffer();
  final delta = doc.toDelta();

  for (final op in delta.toList()) {
    final data = op.data;
    if (data is! String) continue;
    final attrs = op.attributes ?? const <String, dynamic>{};
    final pieces = data.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      final raw = _escapeHtml(pieces[i]);
      if (raw.isNotEmpty) {
        buffer.write(_applyAttrs(raw, attrs));
      }
      if (i != pieces.length - 1) {
        buffer.write('<br/>');
      }
    }
  }

  return buffer.toString();
}

String _applyAttrs(String text, Map<String, dynamic> attrs) {
  var output = text;
  final link = attrs['link'];
  if (link != null && link.toString().isNotEmpty) {
    output = '<a href="${_escapeHtml(link.toString())}">$output</a>';
  }
  if (attrs['bold'] == true) {
    output = '<b>$output</b>';
  }
  if (attrs['italic'] == true) {
    output = '<i>$output</i>';
  }
  return output;
}

String _escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
