class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = 'Not found']);
  @override
  String toString() => 'NotFoundException: $message';
}

class HttpFailure implements Exception {
  final int statusCode;
  final String message;
  HttpFailure(this.statusCode, this.message);
  @override
  String toString() => 'HttpFailure($statusCode): $message';
}
