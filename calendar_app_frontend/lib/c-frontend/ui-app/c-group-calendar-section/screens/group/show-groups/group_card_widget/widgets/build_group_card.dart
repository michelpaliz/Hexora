// lib/.../dialog_content/profile_alert_dialog.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/invited-user/group_role_extension.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/profile_alert_dialog_content.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

void showProfileAlertDialog(
  BuildContext context,
  Group group,
  User owner,
  User? currentUser,
  UserDomain userDomain,
  GroupDomain groupDomain,
  void Function(String?) updateRole, [
  bool? overridePermission,
]) {
  final user = currentUser ?? userDomain.user!;
  final role = group.getRoleForUser(user);
  final hasPermission = overridePermission ?? role != 'Member';
  updateRole(role);

  final cs = Theme.of(context).colorScheme;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      final t = AppTypography.of(context);
      final l = AppLocalizations.of(context)!;

      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: Dialog(
            backgroundColor: ThemeColors.cardBg(context),
            clipBehavior: Clip.antiAlias,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bar with close button
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, top: 12, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.details,
                            style: t.titleLarge
                                .copyWith(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.onSurface),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true)
                                  .maybePop(),
                        ),
                      ],
                    ),
                  ),

                  // Content (no buttons here anymore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ProfileDialogContent(group: group),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .20), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}
