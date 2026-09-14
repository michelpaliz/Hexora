class MailPage<T> {
  final List<T> items;
  final String? nextCursor;

  const MailPage({required this.items, this.nextCursor});

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
