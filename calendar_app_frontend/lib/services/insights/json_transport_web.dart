// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Map<String, String> _parseHeaders(String rawHeaders) {
  final out = <String, String>{};
  final lines = rawHeaders.split('\r\n');
  for (final line in lines) {
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim().toLowerCase();
    final value = line.substring(idx + 1).trim();
    if (key.isEmpty || value.isEmpty) continue;
    out[key] = value;
  }
  return out;
}

Future<http.Response> postJsonTransportImpl({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
}) {
  final completer = Completer<http.Response>();
  final req = html.HttpRequest();

  debugPrint('[InsightsApi][xhr] open POST $uri');
  debugPrint('[InsightsApi][xhr] headers=$headers');
  debugPrint('[InsightsApi][xhr] body=$body');

  req.open('POST', uri.toString());
  req.responseType = 'text';
  req.withCredentials = false;
  headers.forEach(req.setRequestHeader);

  req.onReadyStateChange.listen((_) {
    debugPrint(
      '[InsightsApi][xhr] readyState=${req.readyState} '
      'status=${req.status} statusText=${req.statusText}',
    );
  });

  req.onLoadEnd.listen((_) {
    if (completer.isCompleted) return;
    final responseText = req.responseText ?? '';
    debugPrint(
      '[InsightsApi][xhr] loadEnd status=${req.status} '
      'statusText=${req.statusText} responseUrl=${req.responseUrl}',
    );
    if (responseText.trim().isNotEmpty) {
      debugPrint('[InsightsApi][xhr] responseBody=$responseText');
    }
    completer.complete(
      http.Response(
        responseText,
        req.status ?? 0,
        headers: _parseHeaders(req.getAllResponseHeaders()),
        reasonPhrase: req.statusText,
      ),
    );
  });

  req.onError.listen((_) {
    if (completer.isCompleted) return;
    debugPrint(
      '[InsightsApi][xhr] error status=${req.status} '
      'statusText=${req.statusText} responseUrl=${req.responseUrl}',
    );
    completer.completeError(
      http.ClientException(
        'XHR request failed (status=${req.status}, statusText=${req.statusText})',
        uri,
      ),
      StackTrace.current,
    );
  });

  req.onAbort.listen((_) {
    if (completer.isCompleted) return;
    debugPrint('[InsightsApi][xhr] abort url=$uri');
    completer.completeError(
      http.ClientException('XHR request aborted', uri),
      StackTrace.current,
    );
  });

  req.send(body);
  return completer.future;
}
