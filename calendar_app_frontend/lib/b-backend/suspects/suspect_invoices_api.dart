import 'package:hexora/b-backend/suspects/suspect_review_api.dart';

class SuspectInvoicesApiException extends SuspectReviewApiException {
  SuspectInvoicesApiException({
    required super.statusCode,
    required super.message,
    required super.url,
    required super.method,
    super.responseBody,
  }) : super(
          apiName: 'SuspectInvoicesApi',
        );
}

class SuspectInvoicesResult extends SuspectReviewResult {
  const SuspectInvoicesResult({
    required super.data,
    required super.requestUrl,
    required super.statusCode,
  });
}

class SuspectInvoicesApi extends SuspectReviewApi<SuspectInvoicesResult> {
  @override
  String get resourceName => 'invoices';

  @override
  String get apiName => 'SuspectInvoicesApi';

  @override
  String get totalScannedKey => 'totalInvoicesScanned';

  @override
  SuspectInvoicesApiException createException({
    required int statusCode,
    required String message,
    required Uri url,
    required String method,
    String? responseBody,
  }) {
    return SuspectInvoicesApiException(
      statusCode: statusCode,
      message: message,
      url: url,
      method: method,
      responseBody: responseBody,
    );
  }

  @override
  SuspectInvoicesResult createResult({
    required Map<String, dynamic> data,
    required Uri requestUrl,
    required int statusCode,
  }) {
    return SuspectInvoicesResult(
      data: data,
      requestUrl: requestUrl,
      statusCode: statusCode,
    );
  }
}
