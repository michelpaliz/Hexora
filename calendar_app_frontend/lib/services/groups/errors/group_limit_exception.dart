class GroupLimitException implements Exception {
  final String message;

  const GroupLimitException(
      [this.message = 'You have reached the maximum number of groups.']);

  @override
  String toString() => 'GroupLimitException: $message';
}
