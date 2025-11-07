class PasswordMismatchException implements Exception {
  String toString() =>
      'PasswordMismatchException: New password and confirmation password do not match.';
}

class UserNotSignedInException implements Exception {
  String toString() => 'UserNotSignedInException: User is not signed in.';
}

class CurrentPasswordMismatchException implements Exception {
  String toString() =>
      'CurrentPasswordMismatchException: Current password does not match.';
}
