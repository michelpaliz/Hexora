import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_page.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:http/http.dart' as http;

typedef TokenSupplier = Future<String> Function();

abstract class IMailRepository {
  Future<MailPage<MailMessage>> getMessages({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
  });

  Future<MailMessage> getMessage(String id);

  Future<MailPage<MailMessage>> searchMessages({
    required String query,
    MailFolder? folder,
    bool? unread,
    DateTime? after,
    DateTime? before,
    int limit = 25,
    String? cursor,
  });

  Future<MailPage<MailThread>> getThreads({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
    String? query,
  });

  Future<MailThreadDetail> getThread(String threadKey);

  Future<void> markRead(String id);

  Future<void> markUnread(String id);

  Future<void> archive(String id);

  Future<void> trash(String id);

  Future<void> spam(String id);

  Future<http.Response> downloadAttachment(String attachmentId);

  Future<void> sendMessage(MailSendRequest request);

  Future<void> reply(String id, MailReplyRequest request);

  Future<void> forward(String id, MailForwardRequest request);
}
