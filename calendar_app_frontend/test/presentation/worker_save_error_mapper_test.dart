import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/data/shared/backend_api_exception.dart';
import 'package:hexora/presentation/features/dashboard/sections/workers/shared/worker_save_error_mapper.dart';
import 'package:hexora/l10n/app_localizations_en.dart';

void main() {
  const rawResponse = '{"error":"internal response detail"}';
  final l = AppLocalizationsEn();

  test('maps worker validation failures to a safe localized message', () {
    const error = BackendApiException(
      statusCode: 400,
      message: 'Name leaks from the API',
      rawBody: rawResponse,
    );

    final message = WorkerSaveErrorMapper.messageFor(l, error);

    expect(message, l.workerSaveValidationError);
    expect(message, isNot(contains('leaks')));
    expect(message, isNot(contains('internal response detail')));
  });

  test('maps worker unauthorized failures to a safe localized message', () {
    const error = BackendApiException(
      statusCode: 403,
      message: 'Missing group membership',
      rawBody: rawResponse,
    );

    final message = WorkerSaveErrorMapper.messageFor(l, error);

    expect(message, l.workerSaveUnauthorizedError);
    expect(message, isNot(contains('membership')));
  });

  test('maps unexpected worker failures to a safe localized message', () {
    final message = WorkerSaveErrorMapper.messageFor(
      l,
      Exception('Database host is unavailable'),
    );

    expect(message, l.workerSaveUnexpectedError);
    expect(message, isNot(contains('Database host')));
  });
}
