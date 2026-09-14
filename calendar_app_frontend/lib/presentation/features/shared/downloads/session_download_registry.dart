import 'package:flutter/foundation.dart';

enum SessionDownloadStatus {
  preparing,
  handedToBrowser,
  error,
}

class SessionDownloadItem {
  const SessionDownloadItem({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.startedAt,
    required this.status,
    this.completedAt,
    this.errorMessage,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime startedAt;
  final SessionDownloadStatus status;
  final DateTime? completedAt;
  final String? errorMessage;

  bool get isPdf =>
      mimeType.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  SessionDownloadItem copyWith({
    String? id,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    DateTime? startedAt,
    SessionDownloadStatus? status,
    DateTime? completedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SessionDownloadItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class SessionDownloadRegistry extends ChangeNotifier {
  SessionDownloadRegistry._();

  static final SessionDownloadRegistry instance = SessionDownloadRegistry._();

  final List<SessionDownloadItem> _items = <SessionDownloadItem>[];

  List<SessionDownloadItem> get items => List.unmodifiable(_items);

  String startDownload({
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_items.length}';
    _items.insert(
      0,
      SessionDownloadItem(
        id: id,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        startedAt: DateTime.now(),
        status: SessionDownloadStatus.preparing,
      ),
    );
    notifyListeners();
    return id;
  }

  void markHandedToBrowser(String id) {
    final idx = _items.indexWhere((item) => item.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      status: SessionDownloadStatus.handedToBrowser,
      completedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void markError(String id, Object error) {
    final idx = _items.indexWhere((item) => item.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      status: SessionDownloadStatus.error,
      completedAt: DateTime.now(),
      errorMessage: error.toString(),
    );
    notifyListeners();
  }
}
