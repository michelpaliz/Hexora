import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';

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
      this.participantIds = const []});
  final String id;
  final String type;
  final String title;
  final BusinessChatMessage? lastMessage;
  final Map<String, dynamic>? issue;
  final int unreadCount;
  final List<String> participantIds;

  factory BusinessChatConversation.fromJson(Map<String, dynamic> json) =>
      BusinessChatConversation(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
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
      );

  BusinessChatConversation copyWith({int? unreadCount}) =>
      BusinessChatConversation(
          id: id,
          type: type,
          title: title,
          lastMessage: lastMessage,
          issue: issue,
          participantIds: participantIds,
          unreadCount: unreadCount ?? this.unreadCount);
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

  Future<List<BusinessChatMessage>> messages(
      String groupId, String conversationId) async {
    final response = await AuthenticatedHttpClient.get(
        _uri(groupId, '/conversations/$conversationId/messages'));
    if (response.statusCode != 200)
      throw BackendApiException.fromResponse(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['messages'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) =>
            BusinessChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BusinessChatMessage> send(
      String groupId, String conversationId, String body) async {
    final response = await AuthenticatedHttpClient.post(
        _uri(groupId, '/conversations/$conversationId/messages'),
        body: jsonEncode({'body': body}));
    if (response.statusCode != 201)
      throw BackendApiException.fromResponse(response);
    return BusinessChatMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)));
  }

  Future<BusinessChatMessage> sendAttachment(String groupId,
      String conversationId, PlatformFile file, String body) async {
    if (file.bytes == null) throw StateError('File data is unavailable');
    final response = await AuthenticatedHttpClient.sendMultipart((headers) {
      final request = http.MultipartRequest(
          'POST', _uri(groupId, '/conversations/$conversationId/attachments'));
      request.fields['body'] = body;
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
