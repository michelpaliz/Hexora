import 'package:flutter/material.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/presentation/routes/app_routes.dart';

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
