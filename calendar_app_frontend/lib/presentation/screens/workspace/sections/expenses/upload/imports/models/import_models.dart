part of '../../expense_upload_screen.dart';

class _ExpenseImportTypeScale {
  static const sectionLabel = 10.5;
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const helper = 12.0;
  static const code = 12.0;
}

enum _BatchExecutionFileStatus { success, warning, error }

class _BatchExecutionFile {
  final int originalIndex;
  final String name;
  final int sizeBytes;
  final _BatchExecutionFileStatus status;
  final String detail;

  const _BatchExecutionFile({
    required this.originalIndex,
    required this.name,
    required this.sizeBytes,
    required this.status,
    required this.detail,
  });
}
