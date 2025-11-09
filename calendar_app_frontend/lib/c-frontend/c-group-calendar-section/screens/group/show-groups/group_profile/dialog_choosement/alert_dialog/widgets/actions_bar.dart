// lib/.../dialog_content/widgets/actions_bar.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/j-routes/appRoutes.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/button_styles.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ActionsBar extends StatelessWidget {
  const ActionsBar({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyM = Theme.of(context).textTheme.bodyMedium!;
    final loc = AppLocalizations.of(context)!;

    // Order: [Close] [View members]  —  [Dashboard]
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Close
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
          ),
          child: Text(
            loc.close, // add key if missing
            style: bodyM.copyWith(fontWeight: FontWeight.w600),
          ),
        ),

        // Right: secondary then primary grouped
        Row(
          children: [
            // Secondary: View members
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.groupMembers, // ensure this route exists
                  arguments: group,
                );
              },
              icon: const Icon(Icons.people_alt_outlined),
              label: Text(
                loc.viewMembers, // add key if missing
                style: bodyM.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            // Primary: Dashboard
            TextButton(
              onPressed: () {
                final groupDomain =
                    Provider.of<GroupDomain>(context, listen: false);
                groupDomain.currentGroup = group;

                Navigator.pushNamed(
                  context,
                  AppRoutes.groupDashboard,
                  arguments: group,
                );
              },
              style: ButtonStyles.saucyButtonStyle(
                defaultBackgroundColor: scheme.primary,
                pressedBackgroundColor: scheme.primary,
                textColor: scheme.onPrimary,
                borderColor: scheme.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dashboard_customize_rounded),
                  const SizedBox(width: 8),
                  Text(
                    loc.dashboard,
                    style: bodyM.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
