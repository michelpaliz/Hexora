import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class EmailApi {
  final String _base = '${ApiConstants.baseUrl}/api/emails';
  final String _mailBase = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/mail'
      : '${ApiConstants.baseUrl}/api/mail';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');
  Uri _mail([String path = '']) => Uri.parse('$_mailBase$path');

  List<String> _normalizeEmails(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<dynamic>()
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return const [];
    return text
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    if (ok) {
      return map(body);
    }

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final r = await AuthenticatedHttpClient.get(_u('/status'), headers: _headers());
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<List<Map<String, dynamic>>> getLogs({
    required String invoiceId,
    required String groupId,
  }) async {
    final uri = _u('/logs?invoiceId=$invoiceId&groupId=$groupId');
    final r = await AuthenticatedHttpClient.get(uri, headers: _headers());
    return _decode<List<Map<String, dynamic>>>(r, (j) {
      if (j is! List) return <Map<String, dynamic>>[];
      return j.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<Map<String, dynamic>> previewTemplate(
      Map<String, dynamic> payload) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/templates/preview'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<Map<String, dynamic>> sendInvoice(Map<String, dynamic> payload) async {
    final invoiceId = payload['invoiceId']?.toString().trim();
    final templateId = payload['templateId']?.toString().trim();
    final templateVarsRaw = payload['templateVars'];
    final templateVars = templateVarsRaw is Map
        ? Map<String, dynamic>.from(templateVarsRaw)
        : null;

    final to = _normalizeEmails(payload['to']);
    final cc = _normalizeEmails(payload['cc']);
    final bcc = _normalizeEmails(payload['bcc']);
    final subject = payload['subject']?.toString() ?? '';
    final text = payload['text']?.toString();
    final html = payload['html']?.toString();
    // Invoice emails must always be sent through backend with PDF attached.
    const attachInvoicePdf = true;
    final includeInvoiceLinks = payload['includeInvoiceLinks'] is bool
        ? payload['includeInvoiceLinks'] as bool
        : (attachInvoicePdf == true ? false : true);
    final sendToInternal = payload['sendToInternal'] is bool
        ? payload['sendToInternal'] as bool
        : null;
    final applyDefaultFooter = payload['applyDefaultFooter'] is bool
        ? payload['applyDefaultFooter'] as bool
        : true;

    final Map<String, dynamic> mailPayload = {
      if (to.isNotEmpty) 'to': to,
      if (cc.isNotEmpty) 'cc': cc,
      if (bcc.isNotEmpty) 'bcc': bcc,
      if (subject.trim().isNotEmpty) 'subject': subject,
      if (text != null && text.isNotEmpty) 'text': text,
      if (html != null && html.isNotEmpty) 'html': html,
      if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
      if (templateId != null && templateId.isNotEmpty) 'templateId': templateId,
      if (templateVars != null && templateVars.isNotEmpty)
        'templateVars': templateVars,
      'attachInvoicePdf': attachInvoicePdf,
      'includeInvoiceLinks': includeInvoiceLinks,
      'applyDefaultFooter': applyDefaultFooter,
      if (sendToInternal != null) 'sendToInternal': sendToInternal,
    };

    if (kDebugMode) {
      final safePayload = Map<String, dynamic>.from(mailPayload);
      if (safePayload['to'] is List) {
        safePayload['to'] =
            (safePayload['to'] as List).map((e) => e.toString()).toList();
      }
      if (safePayload['cc'] is List) {
        safePayload['cc'] =
            (safePayload['cc'] as List).map((e) => e.toString()).toList();
      }
      if (safePayload['bcc'] is List) {
        safePayload['bcc'] =
            (safePayload['bcc'] as List).map((e) => e.toString()).toList();
      }
      debugPrint(
          '[EmailApi] /api/mail/send-invoice payload=${jsonEncode(safePayload)}');
    }

    final r = await AuthenticatedHttpClient.post(
      _mail('/send-invoice'),
      headers: _headers(),
      body: jsonEncode(mailPayload),
    );

    if (kDebugMode) {
      final body = r.body;
      final preview = body.length > 800 ? '${body.substring(0, 800)}...' : body;
      debugPrint('[EmailApi] /api/mail/send-invoice status=${r.statusCode}');
      if (preview.isNotEmpty) {
        debugPrint('[EmailApi] /api/mail/send-invoice body=$preview');
      }
    }

    return _decode<Map<String, dynamic>>(r, (j) {
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    });
  }

  Future<void> resend(String emailLogId) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/resend/$emailLogId'),
      headers: _headers(),
      body: jsonEncode({}),
    );
    _decode<void>(r, (_) {});
  }
}
