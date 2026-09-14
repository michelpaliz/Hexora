String? contentDispositionFileName(String? value) {
  final header = value?.trim() ?? '';
  if (header.isEmpty) return null;

  final encodedMatch = RegExp(
    r'''(?:^|;)\s*filename\*\s*=\s*UTF-8'[^']*'([^;]+)''',
    caseSensitive: false,
  ).firstMatch(header);
  final encodedName = encodedMatch?.group(1)?.trim().replaceAll('"', '');
  if (encodedName != null && encodedName.isNotEmpty) {
    try {
      final decoded = Uri.decodeComponent(encodedName).trim();
      if (decoded.isNotEmpty) return decoded;
    } on ArgumentError {
      // A malformed extended value may still have a valid plain fallback.
    }
  }

  if (encodedMatch == null) {
    final unqualifiedEncodedMatch = RegExp(
      r'''(?:^|;)\s*filename\*\s*=\s*"?([^;"']+)"?''',
      caseSensitive: false,
    ).firstMatch(header);
    final unqualifiedEncodedName = unqualifiedEncodedMatch?.group(1)?.trim();
    if (unqualifiedEncodedName != null && unqualifiedEncodedName.isNotEmpty) {
      try {
        final decoded = Uri.decodeComponent(unqualifiedEncodedName).trim();
        if (decoded.isNotEmpty) return decoded;
      } on ArgumentError {
        // Continue to the plain filename parameter.
      }
    }
  }

  final quotedMatch = RegExp(
    r'''(?:^|;)\s*filename\s*=\s*"([^"]*)"''',
    caseSensitive: false,
  ).firstMatch(header);
  final quotedName = quotedMatch?.group(1)?.trim();
  if (quotedName != null && quotedName.isNotEmpty) return quotedName;

  final plainMatch = RegExp(
    r'''(?:^|;)\s*filename\s*=\s*([^;]*)''',
    caseSensitive: false,
  ).firstMatch(header);
  final plainName = plainMatch?.group(1)?.trim();
  return plainName == null || plainName.isEmpty ? null : plainName;
}

String downloadFileNameFromHeaders(
  Map<String, String> headers, {
  required String fallback,
}) {
  String? contentDisposition;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'content-disposition') {
      contentDisposition = entry.value;
      break;
    }
  }
  return contentDispositionFileName(contentDisposition) ?? fallback;
}
