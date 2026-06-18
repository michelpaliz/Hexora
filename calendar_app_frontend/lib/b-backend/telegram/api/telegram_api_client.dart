import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../a-models/telegram/telegram.dart';
import '../../auth_user/auth/token/service/authenticated_http_client.dart';
import '../../config/api_constants.dart';
import '../../errorClases/error_classes/error_classes.dart';

abstract class ITelegramApiClient {
  /// Start connection flow, returns QR code or next step
  Future<TelegramConnectResponse> startConnect({
    String? accountLabel,
  });

  /// Complete connection with fallback credentials (code or password)
  Future<TelegramAccount> completeConnect({
    required String requestId,
    required String code,
  });

  /// Get current account status
  Future<TelegramAccount> getAccount();

  /// Disconnect Telegram account
  Future<void> disconnectAccount();

  /// Get list of accessible chats
  Future<List<TelegramChat>> getChats({
    required String accountId,
    bool refresh = false,
  });

  /// Get detailed information about a specific chat
  Future<TelegramChatDetail> getChatDetail({
    required String chatId,
    required String accountId,
  });

  /// Get paged chat messages for a specific chat.
  Future<TelegramChatMessagesResponse> getChatMessages({
    required String chatId,
    required String accountId,
    int limit = 50,
    String? beforeMessageId,
    String? afterMessageId,
    String? forumTopicId,
  });

  /// Get forum topics for a forum-enabled Telegram chat.
  Future<TelegramForumTopicsResponse> getChatTopics({
    required String chatId,
    required String accountId,
  });

  /// Send a plain-text message to a Telegram chat.
  Future<TelegramChatMessage> sendChatMessage({
    required String chatId,
    required String accountId,
    required String text,
    String? replyToMessageId,
    String? forumTopicId,
  });

  /// Send a document to a Telegram chat using multipart/form-data.
  Future<TelegramChatMessage> sendChatDocument({
    required String chatId,
    required String accountId,
    required List<int> fileBytes,
    required String fileName,
    String? caption,
    String? replyToMessageId,
    String? mimeType,
    String? forumTopicId,
  });

  /// Create an export job
  Future<TelegramExport> createExport({
    required TelegramExportRequest request,
  });

  /// Get export status
  Future<TelegramExport> getExportStatus(String exportId);

  /// Get list of exports
  Future<TelegramExportList> listExports({
    required String accountId,
  });

  /// Get download URL for completed export
  Future<String> getExportDownloadUrl(String exportId);

  /// Cancel a running export
  Future<void> cancelExport(String exportId);
}

class TelegramApiClient implements ITelegramApiClient {
  TelegramApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/telegram'
      : '${ApiConstants.baseUrl}/api/telegram';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u(String path, [Map<String, String>? params]) {
    final base = Uri.parse('$_base$path');
    if (params == null || params.isEmpty) return base;
    return base.replace(queryParameters: params);
  }

  MediaType? _parseMediaType(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    try {
      return MediaType.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(dynamic body, int statusCode, String? reason) {
    String pick(dynamic v) => (v == null) ? '' : v.toString().trim();

    if (body is Map) {
      final message = pick(body['message']);
      if (message.isNotEmpty) return message;

      final error = body['error'];
      if (error is Map) {
        final nestedMessage = pick(error['message']);
        if (nestedMessage.isNotEmpty) return nestedMessage;
        final nestedDetail = pick(error['detail']);
        if (nestedDetail.isNotEmpty) return nestedDetail;
      } else {
        final plainError = pick(error);
        if (plainError.isNotEmpty) return plainError;
      }

      final detail = pick(body['detail']);
      if (detail.isNotEmpty) return detail;

      final title = pick(body['title']);
      if (title.isNotEmpty) return title;
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    final safeReason = (reason ?? '').trim();
    if (safeReason.isNotEmpty) return safeReason;

    if (statusCode >= 500) {
      return 'Server error ($statusCode). Please try again.';
    }
    return 'Request failed ($statusCode).';
  }

  dynamic _decode(http.Response r) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }
    if (ok) return body;

    final message = _extractErrorMessage(body, r.statusCode, r.reasonPhrase);
    throw HttpFailure(r.statusCode, message);
  }

  T _decodeObject<T>(
    http.Response r,
    T Function(Map<String, dynamic>) map,
  ) {
    final data = _decode(r);
    if (data is Map) {
      return map(data.cast<String, dynamic>());
    }
    throw HttpFailure(500, 'Invalid response format');
  }

  TelegramAccount _decodeAccountObject(http.Response r) {
    final data = _decode(r);
    if (data is! Map) {
      throw HttpFailure(500, 'Invalid account response format');
    }

    final json = data.cast<String, dynamic>();
    final accounts = json['accounts'];
    if (accounts is List) {
      return _selectAccountFromList(accounts);
    }

    final nested =
        json['account'] ?? json['data'] ?? json['result'] ?? json['item'];
    if (nested is Map) {
      return TelegramAccount.fromJson(
        Map<String, dynamic>.from(nested),
      );
    }

    return TelegramAccount.fromJson(json);
  }

  TelegramChatMessage _decodeMessageObject(http.Response r) {
    final data = _decode(r);
    if (data is! Map) {
      throw HttpFailure(500, 'Invalid Telegram message response format');
    }

    final json = data.cast<String, dynamic>();
    final nested = json['message'] ?? json['item'] ?? json['data'];
    if (nested is Map) {
      return TelegramChatMessage.fromJson(
        Map<String, dynamic>.from(nested),
      );
    }

    return TelegramChatMessage.fromJson(json);
  }

  TelegramAccount _selectAccountFromList(List<dynamic> accounts) {
    final parsed = accounts
        .whereType<Map>()
        .map((entry) => TelegramAccount.fromJson(entry.cast<String, dynamic>()))
        .toList();

    if (parsed.isEmpty) {
      throw HttpFailure(404, 'No Telegram account found.');
    }

    TelegramAccount? firstConnecting;
    TelegramAccount? firstReconnect;
    TelegramAccount? firstError;

    for (final account in parsed) {
      if (account.isActive) return account;
      firstConnecting ??= account.isConnecting ? account : null;
      firstReconnect ??= account.needsReconnect ? account : null;
      firstError ??= account.isError ? account : null;
    }

    return firstConnecting ?? firstReconnect ?? firstError ?? parsed.first;
  }

  List<T> _decodeList<T>(
    http.Response r,
    T Function(Map<String, dynamic>) map,
  ) {
    final data = _decode(r);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => map(e.cast<String, dynamic>()))
          .toList();
    }
    if (data is Map) {
      final list =
          data['chats'] ?? data['items'] ?? data['data'] ?? data['results'];
      return list is List
          ? list
              .whereType<Map>()
              .map((e) => map(e.cast<String, dynamic>()))
              .toList()
          : <T>[];
    }
    return <T>[];
  }

  @override
  Future<TelegramConnectResponse> startConnect({
    String? accountLabel,
  }) async {
    final payload = {
      if (accountLabel != null) 'accountLabel': accountLabel,
    };
    final r = await AuthenticatedHttpClient.post(
      _u('/connect/start'),
      body: jsonEncode(payload),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramConnectResponse.fromJson);
  }

  @override
  Future<TelegramAccount> completeConnect({
    required String requestId,
    required String code,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/connect/complete'),
      body: jsonEncode({
        'requestId': requestId,
        'code': code,
      }),
      headers: _headers(),
      client: _client,
    );
    return _decodeAccountObject(r);
  }

  @override
  Future<TelegramAccount> getAccount() async {
    final r = await AuthenticatedHttpClient.get(
      _u('/account'),
      headers: _headers(),
      client: _client,
    );
    return _decodeAccountObject(r);
  }

  @override
  Future<void> disconnectAccount() async {
    await AuthenticatedHttpClient.delete(
      _u('/account'),
      headers: _headers(),
      client: _client,
    );
  }

  @override
  Future<List<TelegramChat>> getChats({
    required String accountId,
    bool refresh = false,
  }) async {
    final params = {
      'accountId': accountId,
      if (refresh) 'refresh': 'true',
    };
    final r = await AuthenticatedHttpClient.get(
      _u('/chats', params),
      headers: _headers(),
      client: _client,
    );
    return _decodeList(r, TelegramChat.fromJson);
  }

  @override
  Future<TelegramChatDetail> getChatDetail({
    required String chatId,
    required String accountId,
  }) async {
    final params = {'accountId': accountId};
    final r = await AuthenticatedHttpClient.get(
      _u('/chats/$chatId', params),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramChatDetail.fromJson);
  }

  @override
  Future<TelegramChatMessagesResponse> getChatMessages({
    required String chatId,
    required String accountId,
    int limit = 50,
    String? beforeMessageId,
    String? afterMessageId,
    String? forumTopicId,
  }) async {
    final params = {
      'accountId': accountId,
      'limit': '$limit',
      if (beforeMessageId != null && beforeMessageId.isNotEmpty)
        'beforeMessageId': beforeMessageId,
      if (afterMessageId != null && afterMessageId.isNotEmpty)
        'afterMessageId': afterMessageId,
      if (forumTopicId != null && forumTopicId.isNotEmpty)
        'forumTopicId': forumTopicId,
    };
    final r = await AuthenticatedHttpClient.get(
      _u('/chats/$chatId/messages', params),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramChatMessagesResponse.fromJson);
  }

  @override
  Future<TelegramForumTopicsResponse> getChatTopics({
    required String chatId,
    required String accountId,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/chats/$chatId/topics', {'accountId': accountId}),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramForumTopicsResponse.fromJson);
  }

  @override
  Future<TelegramChatMessage> sendChatMessage({
    required String chatId,
    required String accountId,
    required String text,
    String? replyToMessageId,
    String? forumTopicId,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/chats/$chatId/messages'),
      body: jsonEncode({
        'accountId': accountId,
        'text': text,
        if (replyToMessageId != null && replyToMessageId.isNotEmpty)
          'replyToMessageId': replyToMessageId,
        if (forumTopicId != null && forumTopicId.isNotEmpty)
          'forumTopicId': forumTopicId,
      }),
      headers: _headers(),
      client: _client,
    );
    return _decodeMessageObject(r);
  }

  @override
  Future<TelegramChatMessage> sendChatDocument({
    required String chatId,
    required String accountId,
    required List<int> fileBytes,
    required String fileName,
    String? caption,
    String? replyToMessageId,
    String? mimeType,
    String? forumTopicId,
  }) async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (auth.trim().isEmpty) {
      throw HttpFailure(401, 'Not authenticated');
    }

    final normalizedTopicId = (forumTopicId ?? '').trim();

    final req = http.MultipartRequest(
      'POST',
      _u('/chats/$chatId/documents'),
    );
    req.headers['Authorization'] = auth;
    req.fields['accountId'] = accountId;
    final normalizedCaption = (caption ?? '').trim();
    if (normalizedCaption.isNotEmpty) {
      req.fields['caption'] = normalizedCaption;
    }
    final normalizedReplyId = (replyToMessageId ?? '').trim();
    if (normalizedReplyId.isNotEmpty) {
      req.fields['replyToMessageId'] = normalizedReplyId;
    }
    if (normalizedTopicId.isNotEmpty) {
      req.fields['forumTopicId'] = normalizedTopicId;
    }
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: _parseMediaType(mimeType),
      ),
    );

    final streamed = await _client.send(req);
    final response = await http.Response.fromStream(streamed);
    return _decodeMessageObject(response);
  }

  @override
  Future<TelegramExport> createExport({
    required TelegramExportRequest request,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/exports'),
      body: jsonEncode(request.toJson()),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramExport.fromJson);
  }

  @override
  Future<TelegramExport> getExportStatus(String exportId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/exports/$exportId'),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramExport.fromJson);
  }

  @override
  Future<TelegramExportList> listExports({
    required String accountId,
  }) async {
    final params = {'accountId': accountId};
    final r = await AuthenticatedHttpClient.get(
      _u('/exports', params),
      headers: _headers(),
      client: _client,
    );
    return _decodeObject(r, TelegramExportList.fromJson);
  }

  @override
  Future<String> getExportDownloadUrl(String exportId) async {
    return _u('/exports/$exportId/download').toString();
  }

  @override
  Future<void> cancelExport(String exportId) async {
    await AuthenticatedHttpClient.post(
      _u('/exports/$exportId/cancel'),
      headers: _headers(),
      client: _client,
    );
  }
}
