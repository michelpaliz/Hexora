// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

Stream<String> postSseLines({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
}) {
  final controller = StreamController<String>();
  final req = html.HttpRequest();
  var consumedLength = 0;
  var buffer = '';

  void emitFromDelta(String delta) {
    if (delta.isEmpty) return;
    buffer += delta;
    var breakIndex = buffer.indexOf('\n');
    while (breakIndex >= 0) {
      final line = buffer.substring(0, breakIndex).trimRight();
      buffer = buffer.substring(breakIndex + 1);
      if (line.startsWith('data:')) {
        final payloadLine = line.substring(5).trim();
        if (payloadLine.isNotEmpty && payloadLine != '[DONE]') {
          controller.add(payloadLine);
        }
      }
      breakIndex = buffer.indexOf('\n');
    }
  }

  req.onProgress.listen((_) {
    final text = req.responseText ?? '';
    if (text.length <= consumedLength) return;
    final delta = text.substring(consumedLength);
    consumedLength = text.length;
    emitFromDelta(delta);
  });

  req.onLoadEnd.listen((_) {
    final text = req.responseText ?? '';
    if (text.length > consumedLength) {
      emitFromDelta(text.substring(consumedLength));
      consumedLength = text.length;
    }

    final trailing = buffer.trim();
    if (trailing.startsWith('data:')) {
      final payloadLine = trailing.substring(5).trim();
      if (payloadLine.isNotEmpty && payloadLine != '[DONE]') {
        controller.add(payloadLine);
      }
    }
    buffer = '';

    final status = req.status ?? 0;
    if (status >= 200 && status < 300) {
      if (!controller.isClosed) controller.close();
      return;
    }

    if (!controller.isClosed) {
      controller.addError(Exception('Streaming request failed ($status)'));
      controller.close();
    }
  });

  req.onError.listen((event) {
    if (!controller.isClosed) {
      controller.addError(Exception('Streaming request failed (network error)'));
      controller.close();
    }
  });

  req.open('POST', uri.toString());
  headers.forEach(req.setRequestHeader);
  req.send(body);

  controller.onCancel = () {
    req.abort();
  };

  return controller.stream;
}
