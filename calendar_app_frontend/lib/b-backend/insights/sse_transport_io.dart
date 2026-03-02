import 'dart:convert';

import 'package:http/http.dart' as http;

Stream<String> postSseLines({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
}) async* {
  final c = client ?? http.Client();
  final request = http.Request('POST', uri);
  request.headers.addAll(headers);
  request.body = body;

  final response = await c.send(request);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Streaming request failed (${response.statusCode})');
  }

  var buffer = '';
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    buffer += chunk;
    var breakIndex = buffer.indexOf('\n');
    while (breakIndex >= 0) {
      final line = buffer.substring(0, breakIndex).trimRight();
      buffer = buffer.substring(breakIndex + 1);
      if (line.startsWith('data:')) {
        final payloadLine = line.substring(5).trim();
        if (payloadLine.isNotEmpty && payloadLine != '[DONE]') {
          yield payloadLine;
        }
      }
      breakIndex = buffer.indexOf('\n');
    }
  }

  final trailing = buffer.trim();
  if (trailing.startsWith('data:')) {
    final payloadLine = trailing.substring(5).trim();
    if (payloadLine.isNotEmpty && payloadLine != '[DONE]') {
      yield payloadLine;
    }
  }
}
