part of '../mail_console_screen.dart';

String _folderLabel(MailFolder folder, AppLocalizations l) {
  switch (folder) {
    case MailFolder.inbox:
      return l.mailFolderInbox;
    case MailFolder.sent:
      return l.mailFolderSent;
    case MailFolder.archive:
      return l.mailFolderArchive;
    case MailFolder.trash:
      return l.mailFolderTrash;
    case MailFolder.spam:
      return l.mailFolderSpam;
  }
}

IconData _folderIcon(MailFolder folder) {
  switch (folder) {
    case MailFolder.inbox:
      return Icons.inbox_outlined;
    case MailFolder.sent:
      return Icons.send_outlined;
    case MailFolder.archive:
      return Icons.archive_outlined;
    case MailFolder.trash:
      return Icons.delete_outline;
    case MailFolder.spam:
      return Icons.report_gmailerrorred_outlined;
  }
}

String _shortParticipants(List<String> participants) {
  if (participants.isEmpty) return '';
  if (participants.length <= 2) return participants.join(', ');
  final rest = participants.length - 2;
  return '${participants.take(2).join(', ')} +$rest';
}

String _friendlySender(List<String> participants, AppLocalizations l) {
  if (participants.isEmpty) return l.mailDetailUnknownSender;
  final raw = participants.first.trim();
  if (raw.isEmpty) return l.mailDetailUnknownSender;
  final match = RegExp(r'^(.*)<([^>]+)>$').firstMatch(raw);
  if (match != null) {
    final name = match.group(1)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = match.group(2)?.trim();
    return _friendlyNameFromEmail(email);
  }
  if (raw.contains('@')) return _friendlyNameFromEmail(raw);
  return raw;
}

String _friendlyNameFromEmail(String? email) {
  if (email == null) return 'Unknown';
  final local = email.split('@').first;
  if (local.isEmpty) return 'Unknown';
  final cleaned = local.replaceAll(RegExp(r'[._\\-]+'), ' ').trim();
  if (cleaned.isEmpty) return local;
  return cleaned
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

String _formatRelativeDate(DateTime? date) {
  if (date == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo';
  final years = (diff.inDays / 365).floor();
  return '${years}y';
}

String? _formatBytes(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '${bytes} B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}
