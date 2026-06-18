import 'package:hexora/b-backend/insights/json_transport_io.dart'
    if (dart.library.html) 'package:hexora/b-backend/insights/json_transport_web.dart';
import 'package:http/http.dart' as http;

Future<http.Response> postJsonTransport({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
}) {
  return postJsonTransportImpl(
    uri: uri,
    headers: headers,
    body: body,
    client: client,
  );
}
