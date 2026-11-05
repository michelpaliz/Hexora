import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';

enum BusinessChatChannelType {
  general,
  income,
  expenses,
  quotes,
  workers,
  custom,
}

enum BusinessChatComposerAction {
  attachFile,
  image,
  link,
  invoice,
  receipt,
  expense,
  quote,
  timesheet,
  bankTransaction,
}

BusinessChatChannelType _businessChatChannelType(
  Object? rawType,
  String conversationType,
  String title,
) {
  final value = rawType?.toString().trim().toLowerCase() ?? '';
  for (final type in BusinessChatChannelType.values) {
    if (type.name == value) return type;
  }
  if (conversationType.trim().toLowerCase() == 'general') {
    return BusinessChatChannelType.general;
  }

  // Backward-compatible migration for channels created before channelType
  // existed. The composer consumes the resolved type/actions and never
  // depends directly on a user-editable channel title.
  final legacy = title.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  return switch (legacy) {
    'horas_trabajadores' => BusinessChatChannelType.workers,
    'factura_ingresos' || 'facturas_ingresos' => BusinessChatChannelType.income,
    'presupuestos' => BusinessChatChannelType.quotes,
    'facturas_gastos' || 'factura_gastos' => BusinessChatChannelType.expenses,
    _ => BusinessChatChannelType.custom,
  };
}

Set<BusinessChatComposerAction> _defaultComposerActions(
  BusinessChatChannelType type,
  String title,
) {
  final defaults = switch (type) {
    BusinessChatChannelType.general => {
        BusinessChatComposerAction.attachFile,
        BusinessChatComposerAction.image,
      },
    BusinessChatChannelType.income => {
        BusinessChatComposerAction.attachFile,
        BusinessChatComposerAction.invoice,
        BusinessChatComposerAction.receipt,
      },
    BusinessChatChannelType.expenses => {
        BusinessChatComposerAction.attachFile,
        BusinessChatComposerAction.expense,
        BusinessChatComposerAction.receipt,
      },
    BusinessChatChannelType.quotes => {
        BusinessChatComposerAction.attachFile,
        BusinessChatComposerAction.quote,
      },
    BusinessChatChannelType.workers => {
        BusinessChatComposerAction.attachFile,
        BusinessChatComposerAction.timesheet,
      },
    BusinessChatChannelType.custom => {
        BusinessChatComposerAction.attachFile,
      },
  };
  final legacy = title.trim().toLowerCase();
  if (type == BusinessChatChannelType.custom && legacy == 'marketing') {
    return {
      ...defaults,
      BusinessChatComposerAction.image,
      BusinessChatComposerAction.link,
    };
  }
  return defaults;
}

BusinessChatComposerAction? _businessChatComposerAction(Object? value) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return switch (raw) {
    'file' ||
    'attach_file' ||
    'attachfile' ||
    'attachment' =>
      BusinessChatComposerAction.attachFile,
    'image' || 'images' => BusinessChatComposerAction.image,
    'link' || 'links' => BusinessChatComposerAction.link,
    'invoice' || 'invoices' => BusinessChatComposerAction.invoice,
    'receipt' || 'receipts' => BusinessChatComposerAction.receipt,
    'expense' || 'expenses' => BusinessChatComposerAction.expense,
    'quote' ||
    'quotes' ||
    'budget' ||
    'presupuesto' =>
      BusinessChatComposerAction.quote,
    'timesheet' ||
    'timesheets' ||
    'worker_hours' =>
      BusinessChatComposerAction.timesheet,
    'bank_transaction' ||
    'banktransaction' ||
    'bank' =>
      BusinessChatComposerAction.bankTransaction,
    _ => null,
  };
}

class BusinessChatMessage {
  const BusinessChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.attachment,
    this.businessRecord,
    this.bankTransaction,
    this.replyTo,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final Map<String, dynamic>? attachment;
  final Map<String, dynamic>? businessRecord;
  final Map<String, dynamic>? bankTransaction;
  final Map<String, dynamic>? replyTo;

  factory BusinessChatMessage.fromJson(Map<String, dynamic> json) =>
      BusinessChatMessage(
        id: (json['id'] ?? '').toString(),
        conversationId: (json['conversationId'] ?? '').toString(),
        senderId: (json['senderId'] ?? '').toString(),
        senderName: (json['senderName'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        editedAt: DateTime.tryParse((json['editedAt'] ?? '').toString()),
        isDeleted: json['isDeleted'] == true,
        attachment: json['attachment'] is Map
            ? Map<String, dynamic>.from(json['attachment'])
            : null,
        businessRecord: json['businessRecord'] is Map
            ? Map<String, dynamic>.from(json['businessRecord'])
            : (json['attachment'] is Map &&
                    (json['attachment'] as Map)['businessRecord'] is Map
                ? Map<String, dynamic>.from(
                    (json['attachment'] as Map)['businessRecord'] as Map)
                : null),
        bankTransaction: json['bankTransaction'] is Map
            ? Map<String, dynamic>.from(json['bankTransaction'])
            : null,
        replyTo: json['replyTo'] is Map
            ? Map<String, dynamic>.from(json['replyTo'])
            : null,
      );
}

class BusinessChatMember {
  const BusinessChatMember({
    required this.id,
    required this.name,
    required this.isOnline,
    this.photoUrl,
    this.lastActiveAt,
  });

  final String id;
  final String name;
  final bool isOnline;
  final String? photoUrl;
  final DateTime? lastActiveAt;

  factory BusinessChatMember.fromJson(Map<String, dynamic> json) =>
      BusinessChatMember(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        isOnline: json['isOnline'] == true,
        photoUrl: json['photoUrl']?.toString(),
        lastActiveAt:
            DateTime.tryParse((json['lastActiveAt'] ?? '').toString()),
      );
}

class BusinessChatConversation {
  const BusinessChatConversation(
      {required this.id,
      required this.type,
      required this.title,
      this.lastMessage,
      this.issue,
      this.unreadCount = 0,
      this.participantIds = const [],
      this.moderatorIds = const [],
      this.canManageParticipants = false,
      this.canModerateMessages = false,
      this.muted = false,
      this.canShareBankTransaction = false,
      this.channelType = BusinessChatChannelType.custom,
      this.composerActions = const {BusinessChatComposerAction.attachFile}});
  final String id;
  final String type;
  final String title;
  final BusinessChatMessage? lastMessage;
  final Map<String, dynamic>? issue;
  final int unreadCount;
  final List<String> participantIds;
  final List<String> moderatorIds;
  final bool canManageParticipants;
  final bool canModerateMessages;
  final bool muted;
  final bool canShareBankTransaction;
  final BusinessChatChannelType channelType;
  final Set<BusinessChatComposerAction> composerActions;

  factory BusinessChatConversation.fromJson(Map<String, dynamic> json) {
    final conversationType = (json['type'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final channelConfig = json['channelConfig'] is Map
        ? Map<String, dynamic>.from(json['channelConfig'] as Map)
        : const <String, dynamic>{};
    final channelType = _businessChatChannelType(
      json['channelType'] ??
          json['channel_type'] ??
          channelConfig['type'] ??
          channelConfig['channelType'],
      conversationType,
      title,
    );
    final rawActions = json['allowedActions'] ??
        json['composerActions'] ??
        json['allowed_actions'] ??
        channelConfig['allowedActions'] ??
        channelConfig['composerActions'];
    final configuredActions = rawActions is List
        ? rawActions
            .map(_businessChatComposerAction)
            .whereType<BusinessChatComposerAction>()
            .toSet()
        : <BusinessChatComposerAction>{};
    final composerActions = configuredActions.isEmpty
        ? _defaultComposerActions(channelType, title)
        : configuredActions;
    composerActions.add(BusinessChatComposerAction.attachFile);
    return BusinessChatConversation(
      id: (json['id'] ?? '').toString(),
      type: conversationType,
      title: title,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessage: json['lastMessage'] is Map
          ? BusinessChatMessage.fromJson(
              Map<String, dynamic>.from(json['lastMessage']))
          : null,
      issue: json['issue'] is Map
          ? Map<String, dynamic>.from(json['issue'])
          : null,
      participantIds: (json['participantIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
      moderatorIds: (json['moderatorIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
      canManageParticipants: json['canManageParticipants'] == true,
      canModerateMessages: json['canModerateMessages'] == true,
      muted: json['muted'] == true,
      canShareBankTransaction: json['canShareBankTransaction'] == true,
      channelType: channelType,
      composerActions: composerActions,
    );
  }

  BusinessChatConversation copyWith({int? unreadCount}) =>
      BusinessChatConversation(
          id: id,
          type: type,
          title: title,
          lastMessage: lastMessage,
          issue: issue,
          participantIds: participantIds,
          moderatorIds: moderatorIds,
          canManageParticipants: canManageParticipants,
          canModerateMessages: canModerateMessages,
          muted: muted,
          canShareBankTransaction: canShareBankTransaction,
          channelType: channelType,
          composerActions: composerActions,
          unreadCount: unreadCount ?? this.unreadCount);
}

class BusinessChatMessagePage {
  const BusinessChatMessagePage(this.messages, this.hasMore, this.nextCursor);
  final List<BusinessChatMessage> messages;
  final bool hasMore;
  final String? nextCursor;
}

class BusinessChatApi {
  Uri _uri(String groupId, [String path = '']) =>
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/chat$path');

  Future<Map<String, dynamic>> conversations(String groupId) async {
    final response =
        await AuthenticatedHttpClient.get(_uri(groupId, '/conversations'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    data['conversations'] = (data['conversations'] as List<dynamic>? ??
            const [])
        .whereType<Map>()
        .map((item) =>
            BusinessChatConversation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return data;
  }

  Future<List<BusinessChatMember>> memberPresence(String groupId) async {
    final response =
        await AuthenticatedHttpClient.get(_uri(groupId, '/members'));
    if (response.statusCode != 200) {
      throw BackendApiException.fromResponse(response);
    }
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    return (data['members'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) =>
            BusinessChatMember.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BusinessChatMessagePage> messages(
      String groupId, String conversationId,
      {String? before}) async {
    final response = await AuthenticatedHttpClient.get(
        _uri(groupId, '/conversations/$conversationId/messages').replace(
      queryParameters: before == null ? null : {'before': before},
    ));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = (decoded['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) =>
            BusinessChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return BusinessChatMessagePage(messages, decoded['hasMore'] == true,
        decoded['nextCursor']?.toString());
  }

  Future<List<BusinessChatMessage>> searchMessages(
      String groupId, String conversationId, String query) async {
    final response = await AuthenticatedHttpClient.get(
      _uri(groupId, '/conversations/$conversationId/messages/search')
          .replace(queryParameters: {'q': query}),
    );
    if (response.statusCode != 200) {
      throw BackendApiException.fromResponse(response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) =>
            BusinessChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> setMuted(
      String groupId, String conversationId, bool muted) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/conversations/$conversationId/mute'),
        body: jsonEncode({'muted': muted}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> setTeamModerator(String groupId, String conversationId,
      String userId, bool enabled) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/conversations/$conversationId/moderators/$userId'),
        body: jsonEncode({'enabled': enabled}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<BusinessChatMessage> send(
      String groupId, String conversationId, String body,
      {String? replyToMessageId}) async {
    final response = await AuthenticatedHttpClient.post(
        _uri(groupId, '/conversations/$conversationId/messages'),
        body: jsonEncode({
          'body': body,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId
        }));
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
    return BusinessChatMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<BusinessChatMessage> shareBankTransaction(String groupId,
      String conversationId, String entryId, String body) async {
    final response = await AuthenticatedHttpClient.post(
        _uri(groupId,
            '/conversations/$conversationId/messages/bank-transaction'),
        body: jsonEncode({'entryId': entryId, 'body': body}));
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
    return BusinessChatMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<Map<String, dynamic>> bankTransaction(
      String groupId, String entryId) async {
    final response = await AuthenticatedHttpClient.get(
        _uri(groupId, '/bank-transactions/$entryId'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    return Map<String, dynamic>.from(jsonDecode(response.body)['entry'] as Map);
  }

  Future<BusinessChatMessage> sendAttachment(
      String groupId, String conversationId, PlatformFile file, String body,
      {String? replyToMessageId, Map<String, dynamic>? businessRecord}) async {
    if (file.bytes == null) throw StateError('File data is unavailable');
    final response = await AuthenticatedHttpClient.sendMultipart((headers) {
      final request = http.MultipartRequest(
          'POST', _uri(groupId, '/conversations/$conversationId/attachments'));
      request.fields['body'] = body;
      if (replyToMessageId != null) {
        request.fields['replyToMessageId'] = replyToMessageId;
      }
      if (businessRecord != null) {
        request.fields['businessRecord'] = jsonEncode(businessRecord);
      }
      final extension = file.extension?.toLowerCase() ?? '';
      final mime = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'pdf': 'application/pdf'
      }[extension];
      if (mime == null) throw StateError('Unsupported attachment type');
      request.files.add(http.MultipartFile.fromBytes('file', file.bytes!,
          filename: file.name, contentType: MediaType.parse(mime)));
      return request;
    });
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
    return BusinessChatMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<Uri> attachmentUrl(String groupId, BusinessChatMessage message) async {
    final response = await AuthenticatedHttpClient.get(_uri(groupId,
        '/conversations/${message.conversationId}/messages/${message.id}/attachment'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    return Uri.parse(jsonDecode(response.body)['url'].toString());
  }

  Future<void> edit(
      String groupId, BusinessChatMessage message, String body) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId,
            '/conversations/${message.conversationId}/messages/${message.id}'),
        body: jsonEncode({'body': body}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> delete(String groupId, BusinessChatMessage message) async {
    final response = await AuthenticatedHttpClient.delete(_uri(groupId,
        '/conversations/${message.conversationId}/messages/${message.id}'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<Map<String, dynamic>> createIssue(
      String groupId, String title, String description,
      {String? workerId, String? clientId, String? eventId}) async {
    final response =
        await AuthenticatedHttpClient.post(_uri(groupId, '/issues'),
            body: jsonEncode({
              'title': title,
              'description': description,
              if (workerId != null) 'assigneeWorkerId': workerId,
              if (clientId != null) 'clientId': clientId,
              if (eventId != null) 'eventId': eventId
            }));
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> issueLinks(String groupId) async {
    final response =
        await AuthenticatedHttpClient.get(_uri(groupId, '/issue-links'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> workers(String groupId) async {
    final response =
        await AuthenticatedHttpClient.get(_uri(groupId, '/workers'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    return (jsonDecode(response.body)['workers'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> assignIssue(
      String groupId, String issueId, String workerId) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/issues/$issueId/assignment'),
        body: jsonEncode({'workerId': workerId}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> markRead(String groupId, String conversationId) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/conversations/$conversationId/read'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> createTeam(
      String groupId, String title, List<String> participantIds) async {
    final response = await AuthenticatedHttpClient.post(
        _uri(groupId, '/conversations/team'),
        body: jsonEncode({'title': title, 'participantIds': participantIds}));
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> addParticipants(String groupId, String conversationId,
      List<String> participantIds) async {
    final response = await AuthenticatedHttpClient.post(
        _uri(groupId, '/conversations/$conversationId/participants'),
        body: jsonEncode({'participantIds': participantIds}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> renameTeam(
      String groupId, String conversationId, String title) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/conversations/$conversationId'),
        body: jsonEncode({'title': title}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> updateChannelConfiguration(
    String groupId,
    String conversationId, {
    required BusinessChatChannelType channelType,
    required Set<BusinessChatComposerAction> allowedActions,
  }) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/conversations/$conversationId'),
        body: jsonEncode({
          'channelType': channelType.name,
          'allowedActions':
              allowedActions.map((action) => action.name).toList(),
        }));
    if (response.statusCode != 200) {
      throw BackendApiException.fromResponse(response);
    }
  }

  Future<void> removeParticipant(
      String groupId, String conversationId, String userId) async {
    final response = await AuthenticatedHttpClient.delete(
        _uri(groupId, '/conversations/$conversationId/participants/$userId'));
    if (response.statusCode != 204)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> archiveTeam(String groupId, String conversationId) async {
    final response = await AuthenticatedHttpClient.delete(
        _uri(groupId, '/conversations/$conversationId'));
    if (response.statusCode != 204)
      throw BackendApiException.fromResponse(response);
  }

  Future<void> updateIssueStatus(String groupId, String issueId, String status,
      {String? note}) async {
    final response = await AuthenticatedHttpClient.patch(
        _uri(groupId, '/issues/$issueId/status'),
        body: jsonEncode({'status': status, if (note != null) 'note': note}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
  }

  Future<List<Map<String, dynamic>>> members(String groupId) async {
    final response = await AuthenticatedHttpClient.post(
        Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/members/profiles'),
        body: jsonEncode({}));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
