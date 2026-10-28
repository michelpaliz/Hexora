import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/mail/models/mail_requests.dart';

void main() {
  test(
      'Word presupuesto attachment retains its document ID for delivery tracking',
      () {
    const request = MailSendRequest(
      groupId: 'group-1',
      to: ['client@example.com'],
      subject: 'Presupuesto',
      textBody: 'Adjunto presupuesto',
      attachments: [
        MailOutgoingAttachment(
          storageKey: 'users/document.pdf',
          filename: 'presupuesto-12.pdf',
          contentType: 'application/pdf',
          presupuestoId: 'presupuesto-12',
        ),
      ],
    );

    expect(
      (request.toJson()['attachments'] as List).single['presupuestoId'],
      'presupuesto-12',
    );
  });
}
