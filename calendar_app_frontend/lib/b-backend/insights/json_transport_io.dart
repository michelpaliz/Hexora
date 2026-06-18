import 'package:http/http.dart' as http;

Future<http.Response> postJsonTransportImpl({
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final ownsClient = client == null;
  try {
    return await c.post(
      uri,
      headers: headers,
      body: body,
    );
  } finally {
    if (ownsClient) {
      c.close();
    }
  }
}
