import 'package:hexora/presentation/features/shared/widgets/insights_chat_export_actions.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes export actions from nested response envelopes', () {
    expect(
      extractInsightsExportActionMap({
        'data': {
          'exportAction': {
            'endpoint': ' /exports/invoices ',
            'method': 'get',
            'body': <Object, Object>{'year': 2026},
            'filename': ' invoices.xlsx ',
          },
        },
      }),
      {
        'type': 'export_excel',
        'endpoint': '/exports/invoices',
        'method': 'GET',
        'body': {'year': 2026},
        'filename': 'invoices.xlsx',
      },
    );
  });

  test('falls back through invalid actions and rejects invalid envelopes', () {
    expect(
      extractInsightsExportActionMap({
        'exportAction': {'type': 'unsupported', 'endpoint': '/ignored'},
        'data': {
          'exportAction': {'endpoint': '/exports/fallback'},
        },
      }),
      {
        'type': 'export_excel',
        'endpoint': '/exports/fallback',
        'method': 'POST',
        'body': <String, dynamic>{},
        'filename': null,
      },
    );
    expect(extractInsightsExportActionMap(const {}), isNull);
    expect(extractInsightsExportActionMap('invalid'), isNull);
  });

  test('returns message actions only when export is explicitly enabled', () {
    InsightsChatMessage message({required bool canExport, dynamic action}) {
      return InsightsChatMessage(
        isUser: false,
        text: 'Export ready',
        timestamp: DateTime.utc(2026, 9, 15),
        canExport: canExport,
        exportAction: action as Map<String, dynamic>?,
      );
    }

    final enabled = insightsExportActionForMessage(
      message(canExport: true, action: {'endpoint': '/exports/ready'}),
    );
    expect(enabled?.endpoint, '/exports/ready');
    expect(enabled?.method, 'POST');
    expect(
      insightsExportActionForMessage(
        message(canExport: false, action: {'endpoint': '/exports/ready'}),
      ),
      isNull,
    );
    expect(
      insightsExportActionForMessage(message(canExport: true)),
      isNull,
    );
  });
}
