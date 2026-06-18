class JobNotification {
  const JobNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.actionUrl,
    required this.readAt,
    required this.createdAt,
    required this.jobId,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String severity;
  final String? actionUrl;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String? jobId;

  bool get unread => readAt == null;

  factory JobNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final jobIdText = (json['jobId'] ?? '').toString().trim();
    final actionUrlText = (json['actionUrl'] ?? '').toString().trim();

    return JobNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      severity: (json['severity'] ?? 'info').toString().toLowerCase(),
      actionUrl: actionUrlText.isEmpty ? null : actionUrlText,
      readAt: parseDate(json['readAt']),
      createdAt: parseDate(json['createdAt']),
      jobId: jobIdText.isEmpty ? null : jobIdText,
    );
  }
}
