import 'package:hexora/models/downloads/download_job.dart';
import 'package:hexora/models/jobs/background_job.dart';
import 'package:hexora/models/notifications/notification_user.dart';

/// Shared parsing helpers for "invoice ZIP export ready/failed" notifications,
/// used by both the home notifications screen and the per-group one so the
/// download-handling logic isn't duplicated between them.
class NotificationDownloadHelper {
  const NotificationDownloadHelper._();

  static bool isInvoiceZipDownload(NotificationUser notification) {
    final rawCategory = notification.args['category']?.toString().trim();
    final categoryMatches =
        notification.category.index == 8 || rawCategory == '8';
    final jobType = notification.args['jobType']?.toString().trim();
    return categoryMatches && jobType == 'invoice_zip';
  }

  static bool isReadyDownload(NotificationUser notification) {
    if (!isInvoiceZipDownload(notification)) return false;
    final status = notification.args['downloadStatus']?.toString().trim();
    return status == 'ready';
  }

  static bool isFailedDownload(NotificationUser notification) {
    if (!isInvoiceZipDownload(notification)) return false;
    final status = notification.args['downloadStatus']?.toString().trim();
    return status == 'failed';
  }

  static DownloadJob? downloadJobFrom(NotificationUser notification) {
    if (!isInvoiceZipDownload(notification)) return null;
    final args = notification.args;
    final jobId = (args['downloadJobId'] ??
            args['downloadId'] ??
            args['id'] ??
            args['jobId'])
        ?.toString()
        .trim();
    final downloadUrl = args['downloadUrl']?.toString().trim() ?? '';
    if ((jobId == null || jobId.isEmpty) && downloadUrl.isEmpty) return null;

    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    final status = (args['downloadStatus'] ?? args['status'] ?? '')
        .toString()
        .trim();

    return DownloadJob(
      id: jobId?.isNotEmpty == true ? jobId! : notification.id,
      groupId: (args['groupId'] ?? notification.groupId).toString(),
      requestedByUserId: (args['requestedByUserId'] ?? '').toString(),
      requestedByUserName: (args['requestedByUserName'] ?? '').toString(),
      jobType: (args['jobType'] ?? '').toString(),
      title: (args['title']?.toString().trim().isNotEmpty == true)
          ? args['title'].toString()
          : notification.fallbackTitle,
      description: (args['description']?.toString().trim().isNotEmpty == true)
          ? args['description'].toString()
          : notification.fallbackMessage,
      status: status,
      fileName: (args['fileName'] ?? '').toString(),
      mimeType: (args['mimeType'] ?? 'application/zip').toString(),
      size: parseInt(args['size']),
      errorMessage: (args['errorMessage'] ?? '').toString(),
      params: const <String, dynamic>{},
      notificationId: notification.id,
      expiresAt: parseDate(args['expiresAt']),
      startedAt: parseDate(args['startedAt']),
      createdAt: parseDate(args['createdAt']) ?? notification.timestamp,
      updatedAt: parseDate(args['updatedAt']) ?? notification.timestamp,
      completedAt: parseDate(args['completedAt']),
      downloadUrl: downloadUrl,
      canDownload: status == 'ready' && downloadUrl.isNotEmpty,
    );
  }
}

/// Shared helper for pulling a `groupId` out of a background job's metadata,
/// used to scope a globally-tracked job to a single group's notifications
/// screen.
String? extractGroupIdFromMap(Map<String, dynamic> raw) {
  for (final key in const [
    'groupId',
    'group_id',
    'workspaceGroupId',
    'targetGroupId',
  ]) {
    final value = raw[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  for (final value in raw.values) {
    if (value is Map) {
      final nested = extractGroupIdFromMap(Map<String, dynamic>.from(value));
      if (nested != null && nested.isNotEmpty) return nested;
    }
  }
  return null;
}

String? extractGroupIdFromJob(BackgroundJob job) {
  final fromMetadata = extractGroupIdFromMap(job.metadata);
  if (fromMetadata != null) return fromMetadata;
  return extractGroupIdFromMap(job.resultSummary);
}
