import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_job_models.dart';
import 'package:test/test.dart';

void main() {
  test('maps batch preview payloads with the existing defaults', () {
    final items = expenseBatchPreviewItemsFromPayload({
      'items': [
        {
          'status': ' READY ',
          'tempId': ' temp-1 ',
          'sourceDocument': {'fileName': 'invoice.pdf'},
          'prediction': {'total': 120.5},
          'confidence': {'overall': 0.92},
          'warnings': [' Check tax ', '', 7],
        },
        'ignored',
        {
          'duplicate': {'isDuplicate': true},
        },
      ],
    });

    expect(items, hasLength(2));
    expect(items.first.id, 'temp-1');
    expect(items.first.fileName, 'invoice.pdf');
    expect(items.first.status, 'ready');
    expect(items.first.warnings, ['Check tax', '7']);
    expect(items.first.selected, isTrue);
    expect(items.last.id, 'Documento 3_2');
    expect(items.last.status, 'needs_review');
    expect(items.last.isDuplicate, isTrue);
    expect(items.last.canSelect, isFalse);
  });

  test('normalizes batch status, counts, and progress messages', () {
    expect(expenseBatchJobText(' value '), 'value');
    expect(expenseBatchJobFirstText([null, ' ', 42]), '42');
    expect(expenseBatchJobInt(4.9), 4);
    expect(expenseBatchJobDouble(' 3.5 '), 3.5);
    expect(
      expenseBatchJobStatusFromPayload({'status': ' PROCESSING '}),
      'processing',
    );
    expect(isExpenseBatchJobTerminal('completed'), isTrue);
    expect(isExpenseBatchJobTerminal('processing'), isFalse);
    expect(
      expenseBatchJobUiMessage({
        'status': 'processing',
        'processedFiles': 2,
        'totalFiles': '4',
        'message': 'Validando importes',
      }),
      'Procesando 2 de 4 archivos. Validando importes',
    );
  });

  test('deduplicates issue labels and maps file-specific reasons', () {
    final payload = <String, dynamic>{
      'errors': [
        {'fileName': 'Invoice.PDF', 'message': 'Invalid'},
      ],
      'warnings': ['Global warning', 'Global warning'],
      'failedFiles': [
        {'filename': 'Invoice.PDF', 'reason': 'Rejected'},
      ],
      'files': [
        {'name': 'NoReason.pdf'},
      ],
    };

    expect(
      expenseBatchIssuesFromPayload(payload),
      [
        'Invoice.PDF - Invalid',
        'Global warning',
        'Invoice.PDF - Rejected',
        'NoReason.pdf',
      ],
    );
    expect(
      expenseBatchFileIssueMapFromPayload(payload),
      {
        'invoice.pdf': 'Invalid',
        'noreason.pdf': 'Con incidencia',
      },
    );
  });
}
