import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class AzureMapsToken {
  const AzureMapsToken({
    required this.accessToken,
    required this.clientId,
    required this.expiresAt,
  });

  final String accessToken;
  final String clientId;
  final DateTime expiresAt;

  bool get shouldRefresh =>
      DateTime.now().toUtc().add(const Duration(minutes: 2)).isAfter(expiresAt);

  factory AzureMapsToken.fromJson(Map<String, dynamic> json) {
    final accessToken = (json['accessToken'] ?? '').toString().trim();
    final clientId = (json['clientId'] ?? '').toString().trim();
    final expiresAt = DateTime.tryParse(
      (json['expiresAt'] ?? '').toString().trim(),
    )?.toUtc();
    if (accessToken.isEmpty || clientId.isEmpty || expiresAt == null) {
      throw const FormatException('Invalid Azure Maps token response.');
    }
    return AzureMapsToken(
      accessToken: accessToken.replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false), ''),
      clientId: clientId,
      expiresAt: expiresAt,
    );
  }
}

class AzureMapSearchResult {
  const AzureMapSearchResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

class MapsApiException implements Exception {
  const MapsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MapsApi {
  MapsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  AzureMapsToken? _cachedToken;

  Future<AzureMapsToken> getToken({bool forceRefresh = false}) async {
    final cached = _cachedToken;
    if (!forceRefresh && cached != null && !cached.shouldRefresh) return cached;

    final response = await AuthenticatedHttpClient.get(
      Uri.parse('${ApiConstants.baseUrl}/maps/token'),
      headers: const {'Accept': 'application/json'},
      client: _client,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exception(response, 'No se pudo conectar con Azure Maps.');
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      final token = AzureMapsToken.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cachedToken = token;
      return token;
    } catch (_) {
      throw const MapsApiException(
        'La respuesta de autenticación del mapa no es válida.',
      );
    }
  }

  Future<List<AzureMapSearchResult>> searchAddress(String query) async {
    final normalized = query.trim();
    if (normalized.length < 3) return const <AzureMapSearchResult>[];
    final token = await getToken();
    final uri = Uri.https('atlas.microsoft.com', '/geocode', <String, String>{
      'api-version': '2026-01-01',
      'query': normalized,
      'top': '6',
      'view': 'Auto',
    });
    final response = await _client.get(uri, headers: _azureHeaders(token));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exception(response, 'No se pudo buscar la dirección.');
    }
    final decoded = jsonDecode(response.body);
    final features = decoded is Map && decoded['features'] is List
        ? decoded['features'] as List
        : const <dynamic>[];
    return features
        .map(_searchResultFromFeature)
        .whereType<AzureMapSearchResult>()
        .toList();
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final token = await getToken();
    final uri = Uri.https(
      'atlas.microsoft.com',
      '/reverseGeocode',
      <String, String>{
        'api-version': '2026-01-01',
        'coordinates': '$longitude,$latitude',
        'resultTypes': 'Address',
        'view': 'Auto',
      },
    );
    final response = await _client.get(uri, headers: _azureHeaders(token));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    try {
      final decoded = jsonDecode(response.body);
      final features = decoded is Map && decoded['features'] is List
          ? decoded['features'] as List
          : const <dynamic>[];
      if (features.isEmpty || features.first is! Map) return null;
      final feature = Map<String, dynamic>.from(features.first as Map);
      final properties = feature['properties'] is Map
          ? Map<String, dynamic>.from(feature['properties'] as Map)
          : const <String, dynamic>{};
      final address = properties['address'] is Map
          ? Map<String, dynamic>.from(properties['address'] as Map)
          : const <String, dynamic>{};
      final formatted = (address['formattedAddress'] ?? '').toString().trim();
      return formatted.isEmpty ? null : formatted;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _azureHeaders(AzureMapsToken token) => <String, String>{
        'Accept': 'application/geo+json, application/json',
        'Authorization': 'Bearer ${token.accessToken}',
        'x-ms-client-id': token.clientId,
      };

  AzureMapSearchResult? _searchResultFromFeature(dynamic raw) {
    if (raw is! Map) return null;
    final feature = Map<String, dynamic>.from(raw);
    final geometry = feature['geometry'] is Map
        ? Map<String, dynamic>.from(feature['geometry'] as Map)
        : const <String, dynamic>{};
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final longitude = _number(coordinates[0]);
    final latitude = _number(coordinates[1]);
    if (latitude == null || longitude == null) return null;
    final properties = feature['properties'] is Map
        ? Map<String, dynamic>.from(feature['properties'] as Map)
        : const <String, dynamic>{};
    final address = properties['address'] is Map
        ? Map<String, dynamic>.from(properties['address'] as Map)
        : const <String, dynamic>{};
    final title = (address['formattedAddress'] ??
            properties['formattedAddress'] ??
            properties['name'] ??
            '')
        .toString()
        .trim();
    if (title.isEmpty) return null;
    return AzureMapSearchResult(
      address: title,
      latitude: latitude,
      longitude: longitude,
    );
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  MapsApiException _exception(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message =
            (decoded['error'] ?? decoded['message'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          return MapsApiException(message, statusCode: response.statusCode);
        }
      }
    } catch (_) {}
    return MapsApiException(fallback, statusCode: response.statusCode);
  }
}
