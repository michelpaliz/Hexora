import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RepetitionToggleWidget extends StatelessWidget {
  final bool isRepetitive;
  final double toggleWidth; // kept for API, but we let Expanded drive width
  final Future<void> Function() onTap;

  const RepetitionToggleWidget({
    Key? key,
    required this.isRepetitive,
    required this.toggleWidth,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LABEL — shrinks/ellipsizes when space is tight
        Flexible(
          flex: 0,
          child: Text(
            loc.repeatEventLabel,
            style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 12),

        // TOGGLE — always sits to the right, fills remaining width
        Expanded(
          child: SizedBox(
            height: 36,
            child: _ToggleButton(
              isOn: isRepetitive,
              onTap: onTap,
              colorScheme: cs,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isOn;
  final Future<void> Function() onTap;
  final ColorScheme colorScheme;

  const _ToggleButton({
    required this.isOn,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final cs = colorScheme;

    final bgActive = cs.primary;
    final fgActive = cs.onPrimary;
    final bgInactive = cs.surface;
    final fgInactive = cs.onSurface;
    final borderInactive = cs.outlineVariant;

    return Semantics(
      button: true,
      toggled: isOn,
      label: isOn ? loc.repeatYes : loc.repeatNo,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async => await onTap(),
          borderRadius: BorderRadius.circular(18),
          splashColor: cs.primary.withOpacity(0.12),
          highlightColor: cs.primary.withOpacity(0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: double.infinity, // fill Expanded
            height: double.infinity, // fill the 36px parent
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
            // 🧩 No-overflow core: scale down icon+text if needed
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOn
                          ? Icons.repeat_rounded
                          : Icons.repeat_one_on_outlined,
                      size: 18,
                      color: isOn ? fgActive : fgInactive.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOn ? loc.repeatYes : loc.repeatNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(
                        MediaQuery.textScaleFactorOf(context)
                            .clamp(0.8, 1.4)
                            .toDouble(),
                      ),
                      style: typo.bodySmall.copyWith(
                        color: isOn ? fgActive : fgInactive,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
