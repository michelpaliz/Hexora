import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/feedback/error_message.dart';
import 'package:http/http.dart' as http;

class _ApiError implements Exception {
  _ApiError(this.statusCode, this.message, [this.responseData]);
  final int statusCode;
  final String message;
  final Map<String, dynamic>? responseData;
}

void main() {
  late BuildContext ctx;
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(Localizations(
        locale: const Locale('es'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ));

  testWidgets('explains API, network and unknown failures', (tester) async {
    await pump(tester);

    final validation = describeError(
        ctx,
        _ApiError(400, 'Validation failed', {
          'errors': {'billing.taxId': 'NIF no válido'}
        }));
    expect(validation.message, contains('Algunos datos no son válidos'));
    expect(validation.message, contains('billing.taxId: NIF no válido'));
    expect(validation.details, contains('HTTP 400'));

    final network = describeError(ctx, http.ClientException('XMLHttpRequest error'));
    expect(network.message, contains('conexión'));

    final unknown = describeError(ctx, Exception('Bad Request (status 400)'));
    expect(unknown.message, 'Bad Request (status 400)');
  });
}
