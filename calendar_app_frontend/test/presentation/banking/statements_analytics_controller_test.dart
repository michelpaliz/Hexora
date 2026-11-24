import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_controller.dart';
import 'package:hexora/services/statements/statements_api.dart';

class _PartiallyFailingStatementsApi extends StatementsApi {
  final List<int?> requestedTopValues = [];

  @override
  Future<List<Map<String, dynamic>>> listImports() async => [
        {'batchId': 'available'},
        {'batchId': 'unavailable'},
      ];

  @override
  Future<Map<String, dynamic>> analyticsSummary({
    required String batchId,
    int? year,
    int? month,
    int? top,
    String? dateFrom,
    String? dateTo,
  }) async {
    requestedTopValues.add(top);
    if (batchId == 'unavailable') {
      throw Exception('network unavailable');
    }
    return {
      'years': [
        {
          'year': 2026,
          'income': 1200,
          'expense': 400,
          'net': 800,
          'count': 3,
        },
      ],
      'months': const [],
      'topMerchants': const {'expense': [], 'income': []},
    };
  }
}

void main() {
  test('dashboard summary survives one unavailable statement batch', () async {
    final api = _PartiallyFailingStatementsApi();
    final controller = StatementsAnalyticsController(
      api: api,
      loadDerivedData: false,
    );

    await controller.loadBatches();

    expect(controller.hasLoadedSummary, isTrue);
    expect(controller.summaryError, isNull);
    expect(controller.years, hasLength(1));
    expect(api.requestedTopValues, everyElement(20));

    controller.dispose();
  });
}
