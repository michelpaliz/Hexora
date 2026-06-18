bool isLikelyValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  if (email.contains(RegExp(r'\s'))) return false;
  final at = email.indexOf('@');
  if (at <= 0 || at != email.lastIndexOf('@')) return false;
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  if (local.isEmpty || domain.isEmpty) return false;
  if (domain.startsWith('.') || domain.endsWith('.')) return false;
  if (!domain.contains('.')) return false;
  return true;
}
