import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

/// Bottom-sheet panel that shows backend capabilities for the manual editor.
class CapabilitiesInfoPanel extends StatelessWidget {
  final ManualEditorCapabilities capabilities;

  const CapabilitiesInfoPanel({super.key, required this.capabilities});

  static void show(BuildContext context, ManualEditorCapabilities caps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CapabilitiesInfoPanel(capabilities: caps),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(
            text,
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        );

    Widget ruleItem(String rule) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );

    Widget actionCard(ManualEditorActionCapability action) {
      final isHelper = action.isFrontendHelper;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHelper
              ? cs.secondaryContainer.withValues(alpha: 0.45)
              : cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHelper
                ? cs.outlineVariant.withValues(alpha: 0.5)
                : cs.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    action.label,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHelper
                        ? cs.secondaryContainer
                        : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isHelper ? 'Helper' : 'Nativo',
                    style: t.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isHelper
                          ? cs.onSecondaryContainer
                          : cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (action.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                action.description,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (action.whenToUse != null && action.whenToUse!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                action.whenToUse!,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (action.examples.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: action.examples
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          e,
                          style: t.bodySmall.copyWith(
                            fontSize: 11,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
    }

    Widget unsupportedCard(ManualEditorUnsupportedItem item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.block_outlined, size: 16, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onErrorContainer,
                      ),
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.reason,
                        style: t.bodySmall.copyWith(
                          color: cs.onErrorContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                capabilities.title.isNotEmpty
                    ? capabilities.title
                    : 'Editor manual',
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (capabilities.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    capabilities.summary,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (capabilities.rules.isNotEmpty) ...[
                  sectionTitle('Reglas'),
                  ...capabilities.rules.map(ruleItem),
                ],
                if (capabilities.actions.isNotEmpty) ...[
                  sectionTitle('Acciones disponibles'),
                  ...capabilities.actions.map(actionCard),
                ],
                if (capabilities.unsupported.isNotEmpty) ...[
                  sectionTitle('No disponible'),
                  ...capabilities.unsupported.map(unsupportedCard),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
