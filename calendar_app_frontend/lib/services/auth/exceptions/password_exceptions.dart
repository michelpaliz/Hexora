class PasswordMismatchException implements Exception {
  @override
  String toString() =>
      'PasswordMismatchException: New password and confirmation password do not match.';
}

class UserNotSignedInException implements Exception {
  @override
  String toString() => 'UserNotSignedInException: User is not signed in.';
}

class CurrentPasswordMismatchException implements Exception {
  @override
  String toString() =>
      'CurrentPasswordMismatchException: Current password does not match.';
}
