import 'package:flutter/material.dart';

/// Pure text/markdown helpers shared by the insights chat UI.
List<InlineSpan> markdownBoldSpans({
  required String text,
  required TextStyle baseStyle,
}) {
  final sanitized = sanitizeModelOutput(text);
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var lastEnd = 0;

  for (final match in pattern.allMatches(sanitized)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: sanitized.substring(lastEnd, match.start),
        style: baseStyle,
      ));
    }
    final boldText = match.group(1) ?? '';
    if (boldText.isNotEmpty) {
      spans.add(TextSpan(
        text: boldText,
        style: baseStyle.copyWith(fontWeight: FontWeight.w800),
      ));
    }
    lastEnd = match.end;
  }

  if (lastEnd < sanitized.length) {
    spans.add(TextSpan(
      text: sanitized.substring(lastEnd),
      style: baseStyle,
    ));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: sanitized, style: baseStyle));
  }
  return spans;
}

String sanitizeModelOutput(String input) {
  var out = input;
  out = out.replaceAllMapped(
    RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true),
    (_) => '',
  );
  out = out.replaceAllMapped(
    RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
    (m) {
      final num = (m.group(1) ?? '').trim();
      final den = (m.group(2) ?? '').trim();
      if (num.isEmpty && den.isEmpty) return '';
      if (den.isEmpty) return num;
      if (num.isEmpty) return den;
      return '$num / $den';
    },
  );
  out = out.replaceAllMapped(
    RegExp(r'\\text\{([^}]*)\}'),
    (m) => m.group(1) ?? '',
  );
  out = out.replaceAllMapped(
    RegExp(r'\^\{([^}]*)\}'),
    (m) => '^${(m.group(1) ?? '').trim()}',
  );
  out = out.replaceAllMapped(
    RegExp(r'_\{([^}]*)\}'),
    (m) => '_${(m.group(1) ?? '').trim()}',
  );
  out = out.replaceAll(r'\times', ' x ');
  out = out.replaceAll(r'\cdot', ' * ');
  out = out.replaceAllMapped(
    RegExp(r'\\([a-zA-Z]+)'),
    (m) => m.group(1) ?? '',
  );
  out = out.replaceAll('\\[', '');
  out = out.replaceAll('\\]', '');
  out = out.replaceAll('\\(', '');
  out = out.replaceAll('\\)', '');
  out = out.replaceAll('\\%', '%');
  out = out.replaceAll(r'\$', '\$');
  out = out.replaceAll('\\_', '_');
  out = out.replaceAll('\\{', '{');
  out = out.replaceAll('\\}', '}');
  out = out.replaceAll('\\,', ',');
  out = out.replaceAll('\\.', '.');
  out = out.replaceAll('\\;', ';');
  out = out.replaceAll('\\:', ':');
  out = out.replaceAllMapped(
    RegExp(r'(?<=\b[A-Za-zÁÉÍÓÚÑáéíóúñ]+):(?=\S)'),
    (_) => ': ',
  );
  out = out.replaceAllMapped(
    RegExp(r'(EUR|USD|GBP|€|\$)(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])'),
    (m) => '${m.group(1)} ',
  );
  out = out.replaceAllMapped(
    RegExp(
      r'\b(de|del|al|el|la|los|las|total|suma|asciende|ascendio)(?=\d)',
      caseSensitive: false,
    ),
    (m) => '${m.group(1)} ',
  );
  // Remove markdown horizontal rules (---, ===, ___)
  out = out.replaceAll(RegExp(r'^[-=_]{3,}\s*$', multiLine: true), '');
  out = out.replaceAll(RegExp(r'[ ]{2,}'), ' ');
  out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return out.trim();
}

String formatChatTime(DateTime value) {
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
