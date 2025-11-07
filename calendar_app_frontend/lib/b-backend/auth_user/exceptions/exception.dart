// lib/b-backend/custom_errors.dart

class CustomException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  CustomException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    return 'CustomException: $message (Status Code: $statusCode, Response Body: $responseBody)';
  }
}
