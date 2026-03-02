import 'dart:convert';

import 'package:hexora/b-backend/errorClases/error_classes/error_classes.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum GroupMembershipErrorContext {
  createGroup,
  joinGroup,
  profileMembershipUpdate,
}

const String _premiumRequiredMultiGroupCode = 'PREMIUM_REQUIRED_MULTI_GROUP';

class GroupMembershipErrorMapper {
  static bool isPremiumMultiGroupError(Object error) {
    if (error is BackendApiException) {
      return error.statusCode == 409 &&
          (error.code ?? '').trim() == _premiumRequiredMultiGroupCode;
    }
    if (error is HttpFailure && error.statusCode == 409) {
      final parsed = _tryParseBody(error.message);
      final code = (parsed['code'] ?? parsed['errorCode'] ?? '').toString();
      return code.trim() == _premiumRequiredMultiGroupCode;
    }
    return false;
  }

  static String messageFor(
    AppLocalizations l,
    GroupMembershipErrorContext context,
  ) {
    switch (context) {
      case GroupMembershipErrorContext.joinGroup:
        return l.premiumRequiredJoinGroupOnlyMessage;
      case GroupMembershipErrorContext.createGroup:
      case GroupMembershipErrorContext.profileMembershipUpdate:
        return l.premiumRequiredSingleGroupMessage;
    }
  }

  static Map<String, dynamic> _tryParseBody(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }
}
