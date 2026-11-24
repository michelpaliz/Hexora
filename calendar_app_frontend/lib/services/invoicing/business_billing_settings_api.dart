import 'dart:convert';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';

class BusinessBillingSettings {
  const BusinessBillingSettings({
    required this.groupId,
    required this.defaultInvoiceLanguage,
    required this.requiresInitialConfiguration,
    required this.canEdit,
    this.inferredFromHistory = false,
  });

  final String groupId;
  final String? defaultInvoiceLanguage;
  final bool requiresInitialConfiguration;
  final bool canEdit;
  final bool inferredFromHistory;

  factory BusinessBillingSettings.fromJson(Map<String, dynamic> json) {
    final language = json['defaultInvoiceLanguage']?.toString();
    return BusinessBillingSettings(
      groupId: json['groupId']?.toString() ?? '',
      defaultInvoiceLanguage:
          language == 'es' || language == 'en' ? language : null,
      requiresInitialConfiguration:
          json['requiresInitialConfiguration'] == true,
      canEdit: json['canEdit'] == true,
      inferredFromHistory: json['inferredFromHistory'] == true,
    );
  }
}

class BusinessBillingSettingsApi {
  Uri _uri(String groupId) => Uri.parse(
        '${ApiConstants.baseUrl}/groups/$groupId/billing-settings',
      );

  Future<BusinessBillingSettings> load(String groupId) async {
    final response = await AuthenticatedHttpClient.get(_uri(groupId));
    return _decode(response.statusCode, response.body);
  }

  Future<BusinessBillingSettings> save(
    String groupId,
    String language,
  ) async {
    final response = await AuthenticatedHttpClient.patch(
      _uri(groupId),
      body: jsonEncode({'defaultInvoiceLanguage': language}),
    );
    return _decode(response.statusCode, response.body);
  }

  BusinessBillingSettings _decode(int statusCode, String body) {
    final decoded = body.isEmpty ? null : jsonDecode(body);
    if (statusCode >= 200 && statusCode < 300 && decoded is Map) {
      return BusinessBillingSettings.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    }
    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Unable to load billing settings ($statusCode)';
    throw Exception(message);
  }
}
