import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';

/// Centralized session-expiry reaction used by low-level HTTP/auth code.
class SessionExpiryHandler {
  SessionExpiryHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _handling = false;

  static Future<void> handle() async {
    if (_handling) return;
    _handling = true;
    try {
      await TokenService.clearTokens();

      final nav = navigatorKey.currentState;
      if (nav == null) return;

      nav.pushNamedAndRemoveUntil(
        AppRoutes.loginRoute,
        (_) => false,
      );
    } finally {
      _handling = false;
    }
  }
}
