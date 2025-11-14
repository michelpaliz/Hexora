import 'package:flutter/material.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:provider/provider.dart';

void showLanguageSheet(BuildContext context) {
  final localeProv = Provider.of<LocaleProvider>(context, listen: false);
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final bodyM = theme.textTheme.bodyMedium!;
  final bodyS = theme.textTheme.bodySmall!;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    backgroundColor: cs.surface,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional header (bodySmall, muted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Language',
                    style: bodyS.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            _LanguageTile(
              label: 'English',
              selected: localeProv.locale.languageCode == 'en',
              onTap: () {
                localeProv.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              bodyM: bodyM,
              cs: cs,
            ),
            _LanguageTile(
              label: 'Español',
              selected: localeProv.locale.languageCode == 'es',
              onTap: () {
                localeProv.setLocale(const Locale('es'));
                Navigator.pop(context);
              },
              bodyM: bodyM,
              cs: cs,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.bodyM,
    required this.cs,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle bodyM;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(
        label,
        style: bodyM.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: cs.primary) : null,
      onTap: onTap,
    );
  }
}
