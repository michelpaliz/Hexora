import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

Future<void> openProfileActions(BuildContext context, Color accent) async {
  final loc = AppLocalizations.of(context)!;
  final user = context.read<UserDomain>().user;
  if (user == null) return;

  void copyToClipboard(String text, String toast) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      final onVar = Theme.of(ctx).colorScheme.onSurfaceVariant;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Iconsax.edit, color: accent),
              title: Text(loc.edit),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            ListTile(
              leading: Icon(Icons.ios_share_rounded, color: onVar),
              title: Text(loc.share),
              onTap: () {
                Navigator.pop(ctx);
                final text = '${user.name} (@${user.userName}) • ${user.email}';
                copyToClipboard(text, loc.copiedToClipboard);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add_alt_1_rounded, color: onVar),
              title: Text(loc.addToContacts),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.comingSoon)));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
