import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';

class _FakeInvoiceLinesApi extends InvoiceLinesApi {
  final List<String> calls = <String>[];

  @override
  Future<InvoiceLineEvidenceUploadSas> getLineEvidenceUploadSas(
    String invoiceId,
    String lineId,
    String mimeType, {
    String strategy = 'versioned',
  }) async {
    calls.add('sas:$invoiceId:$lineId:$mimeType:$strategy');
    return const InvoiceLineEvidenceUploadSas(
      uploadUrl: 'https://upload.example/sas',
      blobName: 'invoice-lines/line-1/evidence-v1.png',
      blobUrl: null,
      expiresOn: null,
    );
  }

  @override
  Future<void> uploadEvidenceFile(
    String uploadUrl,
    InvoiceLineEvidenceFile file,
  ) async {
    calls.add('upload:$uploadUrl:${file.mimeType}:${file.sizeBytes}');
  }

  @override
  Future<InvoiceLineEvidenceAttachResult> setLineEvidence(
    String invoiceId,
    String lineId,
    String blobName,
  ) async {
    calls.add('set:$invoiceId:$lineId:$blobName');
    return InvoiceLineEvidenceAttachResult(
      line: InvoiceLine(
        id: lineId,
        invoiceId: invoiceId,
        position: 1,
        description: 'Line 1',
        unitPrice: 10,
        evidenceBlobName: blobName,
      ),
      evidenceBlobName: blobName,
      evidenceUrl: null,
    );
  }
}

void main() {
  group('attachEvidenceToLine', () {
    test('runs SAS -> upload -> set flow in order', () async {
      final api = _FakeInvoiceLinesApi();
      final file = InvoiceLineEvidenceFile(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        fileName: 'proof.png',
        mimeType: 'image/png',
      );

      final result = await api.attachEvidenceToLine(
        invoiceId: 'inv-1',
        lineId: 'line-1',
        file: file,
      );

      expect(
        api.calls,
        [
          'sas:inv-1:line-1:image/png:versioned',
          'upload:https://upload.example/sas:image/png:3',
          'set:inv-1:line-1:invoice-lines/line-1/evidence-v1.png',
        ],
      );
      expect(result.evidenceBlobName, contains('invoice-lines/line-1'));
      expect(result.line.evidenceBlobName, result.evidenceBlobName);
    });

    test('rejects unsupported mime and oversized file', () async {
      final api = _FakeInvoiceLinesApi();
      final invalidMime = InvoiceLineEvidenceFile(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        fileName: 'proof.txt',
        mimeType: 'text/plain',
      );
      expect(
        () => api.attachEvidenceToLine(
          invoiceId: 'inv-1',
          lineId: 'line-1',
          file: invalidMime,
        ),
        throwsA(isA<InvoiceLineEvidenceException>()),
      );

      final oversized = InvoiceLineEvidenceFile(
        bytes: Uint8List(InvoiceLinesApi.maxEvidenceFileBytes + 1),
        fileName: 'proof.png',
        mimeType: 'image/png',
      );
      expect(
        () => api.attachEvidenceToLine(
          invoiceId: 'inv-1',
          lineId: 'line-1',
          file: oversized,
        ),
        throwsA(isA<InvoiceLineEvidenceException>()),
      );
    });
  });

  test('InvoiceLine supports evidenceBlobName mapping', () {
    final line = InvoiceLine.fromJson({
      '_id': 'line-1',
      'invoiceId': 'inv-1',
      'position': 1,
      'description': 'Line',
      'quantity': 1,
      'unitPrice': 10,
      'taxRate': 21,
      'evidenceBlobName': 'invoice-lines/line-1/evidence.png',
    });
    expect(line.evidenceBlobName, isNotNull);
    expect(line.toJson()['evidenceBlobName'], line.evidenceBlobName);
  });
}
