import 'package:flutter/material.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:provider/provider.dart';

/// Opens the existing premium-access experience when the API rejects an action.
class PremiumRequiredHandler {
  PremiumRequiredHandler._();

  static bool _handling = false;

  static void handle(String rawFeature, [String? requestedGroupId]) {
    if (_handling) return;
    final feature = _parseFeature(rawFeature);
    if (feature == null) return;

    final context = SessionExpiryHandler.navigatorKey.currentContext;
    final navigator = SessionExpiryHandler.navigatorKey.currentState;
    if (context == null || navigator == null) return;
    final group = context.read<GroupDomain>().currentGroup;
    if (group == null) return;
    if (requestedGroupId != null && requestedGroupId != group.id) return;

    _handling = true;
    navigator
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PremiumFeatureRequestScreen(
              feature: feature,
              group: group,
            ),
          ),
        )
        .whenComplete(() => _handling = false);
  }

  static PremiumFeatureRequest? _parseFeature(String value) {
    final normalized =
        value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return switch (normalized) {
      'email' || 'premiumemail' => PremiumFeatureRequest.email,
      'banking' || 'premiumbanking' => PremiumFeatureRequest.banking,
      'aichat' || 'premiumaichat' => PremiumFeatureRequest.aiChat,
      'teamchat' || 'premiumteamchat' => PremiumFeatureRequest.teamChat,
      _ => null,
    };
  }
}
