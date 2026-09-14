import 'package:http/http.dart' as http;

export 'sse_transport_io.dart'
    if (dart.library.html) 'sse_transport_web.dart';

typedef SseTransportFn = Stream<String> Function({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
});
