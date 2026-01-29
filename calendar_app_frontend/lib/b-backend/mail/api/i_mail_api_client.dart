import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_page.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:http/http.dart' as http;

abstract class IMailApiClient {
  Future<MailPage<MailMessage>> getMessages({
    required String folder,
    required String token,
    int limit = 25,
    String? cursor,
  });

  Future<MailMessage> getMessage({
    required String id,
    required String token,
  });

  Future<MailPage<MailMessage>> searchMessages({
    required String token,
    String? query,
    String? folder,
    bool? unread,
    DateTime? after,
    DateTime? before,
    int limit = 25,
    String? cursor,
  });

  Future<MailPage<MailThread>> getThreads({
    required String folder,
    required String token,
    int limit = 25,
    String? cursor,
  });

  Future<MailThreadDetail> getThread({
    required String threadKey,
    required String token,
  });

  Future<void> markRead({
    required String id,
    required String token,
  });

  Future<void> markUnread({
    required String id,
    required String token,
  });

  Future<void> archive({
    required String id,
    required String token,
  });

  Future<void> trash({
    required String id,
    required String token,
  });

  Future<void> spam({
    required String id,
    required String token,
  });

  Future<http.Response> downloadAttachment({
    required String attachmentId,
    required String token,
  });

  Future<void> sendMessage({
    required Map<String, dynamic> payload,
    required String token,
  });

  Future<void> reply({
    required String id,
    required Map<String, dynamic> payload,
    required String token,
  });

  Future<void> forward({
    required String id,
    required Map<String, dynamic> payload,
    required String token,
  });
}
