import 'package:hexora/b-backend/suspects/suspect_review_api.dart';

class SuspectExpensesApiException extends SuspectReviewApiException {
  SuspectExpensesApiException({
    required super.statusCode,
    required super.message,
    required super.url,
    required super.method,
    super.responseBody,
  }) : super(
          apiName: 'SuspectExpensesApi',
        );
}

/// Result wrapper so callers can inspect debug metadata without re-parsing.
class SuspectExpensesResult extends SuspectReviewResult {
  const SuspectExpensesResult({
    required super.data,
    required super.requestUrl,
    required super.statusCode,
  });
}

class SuspectExpensesApi extends SuspectReviewApi<SuspectExpensesResult> {
  @override
  String get resourceName => 'expenses';

  @override
  String get apiName => 'SuspectExpensesApi';

  @override
  String get totalScannedKey => 'totalExpensesScanned';

  @override
  bool get clearNotesWhenUnreviewed => true;

  @override
  SuspectExpensesApiException createException({
    required int statusCode,
    required String message,
    required Uri url,
    required String method,
    String? responseBody,
  }) {
    return SuspectExpensesApiException(
      statusCode: statusCode,
      message: message,
      url: url,
      method: method,
      responseBody: responseBody,
    );
  }

  @override
  SuspectExpensesResult createResult({
    required Map<String, dynamic> data,
    required Uri requestUrl,
    required int statusCode,
  }) {
    return SuspectExpensesResult(
      data: data,
      requestUrl: requestUrl,
      statusCode: statusCode,
    );
  }
}
