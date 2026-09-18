import 'package:flutter/material.dart';
import 'package:hexora/presentation/features/events/utils/number_selector.dart';

import 'section_card_builder.dart';

/// Manager-facing toggle for "Require photos to complete" + minimum count.
/// OFF by default — the manager decides when photographic evidence matters.
class CompletionRequirementsSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final bool requirePhotos;
  final int minPhotos;
  final bool requireBeforeAfterPhotos;
  final ValueChanged<bool> onRequirePhotosChanged;
  final ValueChanged<int> onMinPhotosChanged;
  final ValueChanged<bool> onRequireBeforeAfterPhotosChanged;

  const CompletionRequirementsSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.requirePhotos,
    required this.minPhotos,
    required this.requireBeforeAfterPhotos,
    required this.onRequirePhotosChanged,
    required this.onMinPhotosChanged,
    required this.onRequireBeforeAfterPhotosChanged,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Flexible(
                flex: 0,
                child: Text(
                  'Require photos to complete',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: _RequirePhotosToggle(
                    isOn: requirePhotos,
                    onTap: () => onRequirePhotosChanged(!requirePhotos),
                  ),
                ),
              ),
            ],
          ),
          if (requirePhotos) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Minimum photos'),
                ),
                NumberSelector(
                  value: minPhotos,
                  minValue: 1,
                  maxValue: 20,
                  onChanged: (v) => onMinPhotosChanged(v ?? 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Require before and after photos'),
              subtitle: const Text(
                  'The assigned user must upload Before first, then After.'),
              value: requireBeforeAfterPhotos,
              onChanged: onRequireBeforeAfterPhotosChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _RequirePhotosToggle extends StatelessWidget {
  const _RequirePhotosToggle({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgActive = cs.primary;
    final fgActive = cs.onPrimary;
    final bgInactive = cs.surface;
    final fgInactive = cs.onSurface;
    final borderInactive = cs.outlineVariant;

    return Semantics(
      button: true,
      toggled: isOn,
      label: isOn ? 'Required' : 'Optional',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: cs.primary.withOpacity(0.12),
          highlightColor: cs.primary.withOpacity(0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isOn ? bgActive : bgInactive,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isOn ? Colors.transparent : borderInactive,
                width: 1,
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOn
                          ? Icons.camera_alt_rounded
                          : Icons.camera_alt_outlined,
                      size: 18,
                      color: isOn ? fgActive : fgInactive.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOn ? 'Required' : 'Optional',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOn ? fgActive : fgInactive,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
