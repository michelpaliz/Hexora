import 'package:flutter/material.dart';
import 'package:hexora/app/session/session_connection_cleanup.dart';
import 'package:hexora/data/auth/auth/token/service/token_service.dart';
import 'package:hexora/presentation/routes/app_routes.dart';

/// Centralized session-expiry reaction used by low-level HTTP/auth code.
class SessionExpiryHandler {
  SessionExpiryHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _handling = false;

  static Future<void> handle({
    Future<void> Function()? clearTokens,
    NavigatorState? navigator,
  }) async {
    if (_handling) return;
    _handling = true;
    try {
      resetSessionConnections();
      await (clearTokens ?? TokenService.clearTokens)();

      final nav = navigator ?? navigatorKey.currentState;
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
