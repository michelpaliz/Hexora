import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/shared/content_disposition.dart';

void main() {
  group('contentDispositionFileName', () {
    test('decodes an RFC 5987 UTF-8 filename', () {
      expect(
        contentDispositionFileName(
          "attachment; filename*=UTF-8''factura%20n%C3%BAmero%201.pdf",
        ),
        'factura número 1.pdf',
      );
    });

    test('reads quoted and unquoted plain filenames', () {
      expect(
        contentDispositionFileName('attachment; filename="report one.xlsx"'),
        'report one.xlsx',
      );
      expect(
        contentDispositionFileName('attachment; filename=report-two.xlsx'),
        'report-two.xlsx',
      );
    });

    test('uses a plain filename when the extended value is malformed', () {
      expect(
        contentDispositionFileName(
          "attachment; filename*=UTF-8''bad%ZZ; filename=fallback.pdf",
        ),
        'fallback.pdf',
      );
    });
  });

  group('downloadFileNameFromHeaders', () {
    test('matches the header name case-insensitively', () {
      expect(
        downloadFileNameFromHeaders(
          const {'Content-Disposition': 'attachment; filename="export.zip"'},
          fallback: 'fallback.zip',
        ),
        'export.zip',
      );
    });

    test('returns the supplied fallback when no filename is present', () {
      expect(
        downloadFileNameFromHeaders(
          const {'content-type': 'application/pdf'},
          fallback: 'invoice-1.pdf',
        ),
        'invoice-1.pdf',
      );
    });
  });
}
