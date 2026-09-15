import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/json_response_decoder.dart';
import 'package:http/http.dart' as http;

enum TaxReportSection {
  supported('iva-supported', 'IVA soportado'),
  charged('iva-charged', 'IVA repercutido'),
  irpf('irpf', 'IRPF'),
  intracommunity('intracommunity', 'Operaciones intracomunitarias'),
  quarterly('quarterly-summary', 'Resumen trimestral');

  const TaxReportSection(this.endpoint, this.label);
  final String endpoint;
  final String label;
}

/// Calendar dates, not instants: avoids DST changing the exclusive end date.
String taxIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String taxExclusiveEnd(DateTime inclusiveEnd) => taxIsoDate(
    DateTime(inclusiveEnd.year, inclusiveEnd.month, inclusiveEnd.day + 1));

class TaxReportingException implements Exception {
  const TaxReportingException(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

class TaxReportingApi {
  TaxReportingApi({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<Map<String, dynamic>> getReport({
    required String groupId,
    required TaxReportSection section,
    required DateTime from,
    required DateTime inclusiveTo,
    required int year,
    required int quarter,
  }) async {
    if (groupId.trim().isEmpty ||
        inclusiveTo.isBefore(from) ||
        quarter < 1 ||
        quarter > 4) {
      throw const TaxReportingException(400, 'Revisa el período seleccionado.');
    }
    final root = ApiConstants.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final apiRoot = root.endsWith('/api') ? root : '$root/api';
    final uri = Uri.parse('$apiRoot/tax/${section.endpoint}').replace(
      queryParameters: {
        'groupId': groupId,
        if (section == TaxReportSection.quarterly) ...{
          'year': '$year',
          'quarter': 'T$quarter',
        } else ...{
          'from': taxIsoDate(from),
          'to': taxExclusiveEnd(inclusiveTo),
          'currency': 'EUR',
        },
      },
    );
    // Includes token refresh and the application's session-expired handler.
    final response = await AuthenticatedHttpClient.get(uri, client: _client);
    return decodeJsonResponse<Map<String, dynamic>>(
      response,
      url: uri,
      method: 'GET',
      map: (json) {
        if (json is! Map) throw const FormatException('Invalid tax report');
        return Map<String, dynamic>.from(json);
      },
      createException: (error) =>
          TaxReportingException(error.statusCode, error.message),
      shouldLogError: (_) => false,
    );
  }
}
