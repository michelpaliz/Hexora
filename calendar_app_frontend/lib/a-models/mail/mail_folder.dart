enum MailFolder {
  inbox,
  sent,
  archive,
  trash,
  spam,
}

extension MailFolderWire on MailFolder {
  String get wireName {
    switch (this) {
      case MailFolder.inbox:
        return 'INBOX';
      case MailFolder.sent:
        return 'Sent';
      case MailFolder.archive:
        return 'Archive';
      case MailFolder.trash:
        return 'Trash';
      case MailFolder.spam:
        return 'Spam';
    }
  }

  static MailFolder? fromWire(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    switch (normalized) {
      case 'inbox':
        return MailFolder.inbox;
      case 'sent':
        return MailFolder.sent;
      case 'archive':
        return MailFolder.archive;
      case 'trash':
        return MailFolder.trash;
      case 'spam':
        return MailFolder.spam;
    }
    return null;
  }
}
