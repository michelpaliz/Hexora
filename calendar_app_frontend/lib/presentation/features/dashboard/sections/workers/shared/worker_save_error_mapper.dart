import 'package:flutter/foundation.dart';
import 'package:hexora/data/shared/backend_api_exception.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerSaveErrorMapper {
  const WorkerSaveErrorMapper._();

  static String messageFor(AppLocalizations l, Object error) {
    final statusCode = error is BackendApiException ? error.statusCode : null;
    if (statusCode == 400 || statusCode == 422) {
      return l.workerSaveValidationError;
    }
    if (statusCode == 401 || statusCode == 403) {
      return l.workerSaveUnauthorizedError;
    }
    return l.workerSaveUnexpectedError;
  }

  static void logDiagnostic({
    required String action,
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) return;

    final details = error is BackendApiException
        ? 'status=${error.statusCode} code=${error.code} '
            'message=${error.message} rawBody=${error.rawBody}'
        : error.toString();
    debugPrint('[WorkerSave] $action failed: $details');
    debugPrintStack(label: '[WorkerSave] $action stack', stackTrace: stackTrace);
  }
}
