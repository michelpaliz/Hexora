import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PasswordStrength {
  final double value; // 0.0 → 1.0
  final String label;

  PasswordStrength(this.value, this.label);
}

PasswordStrength computePasswordStrength(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;

  int score = 0;
  if (value.length >= 6) score++;
  if (value.length >= 10) score++;
  if (RegExp(r'[A-Z]').hasMatch(value)) score++;
  if (RegExp(r'[a-z]').hasMatch(value)) score++;
  if (RegExp(r'\d').hasMatch(value)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]]').hasMatch(value)) score++;

  if (value.isEmpty) {
    return PasswordStrength(0.0, '');
  } else if (score <= 2) {
    return PasswordStrength(0.33, l10n.passwordWeak);
  } else if (score <= 4) {
    return PasswordStrength(0.66, l10n.passwordMedium);
  } else {
    return PasswordStrength(1.0, l10n.passwordStrong);
  }
}
