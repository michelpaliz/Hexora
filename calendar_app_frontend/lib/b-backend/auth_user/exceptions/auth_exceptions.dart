// ==========================
// LOGIN EXCEPTIONS
// ==========================

class UserNotFoundAuthException implements Exception {
  @override
  String toString() => 'No user found with the provided email.';
}

class WrongPasswordAuthException implements Exception {
  @override
  String toString() => 'The password entered is incorrect.';
}

// ==========================
// REGISTER EXCEPTIONS
// ==========================

class WeakPasswordException implements Exception {
  @override
  String toString() => 'The password provided is too weak.';
}

class EmailAlreadyUseAuthException implements Exception {
  @override
  String toString() => 'This email address is already in use.';
}

class InvalidEmailAuthException implements Exception {
  @override
  String toString() => 'The email address is invalid.';
}

// ==========================
// PASSWORD EXCEPTIONS
// ==========================

class PasswordMismatchException implements Exception {
  @override
  String toString() => 'New password and confirmation do not match.';
}

class CurrentPasswordMismatchException implements Exception {
  @override
  String toString() => 'Current password is incorrect.';
}

// ==========================
// GENERIC & SESSION EXCEPTIONS
// ==========================

class GenericAuthException implements Exception {
  @override
  String toString() => 'An unknown authentication error occurred.';
}

class UserNotLoggedInAuthException implements Exception {
  @override
  String toString() => 'You must be logged in to perform this action.';
}

class UserNotSignedInException implements Exception {
  @override
  String toString() => 'You are not signed in.';
}
