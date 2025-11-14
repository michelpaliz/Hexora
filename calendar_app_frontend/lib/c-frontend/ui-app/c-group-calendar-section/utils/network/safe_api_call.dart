// lib/utils/network_utils.dart

/// Wraps any async call to the backend and — if there’s no auth token — just returns null.
Future<T?> safeApiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on Exception catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('token not found') || msg.contains('unauthorized')) {
      // silently drop it
      return null;
    }
    rethrow; // something else went wrong
  }
}
