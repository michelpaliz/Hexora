import 'package:flutter/material.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class TimeEntryHeaderStrip extends StatelessWidget {
  const TimeEntryHeaderStrip({
    super.key,
    required this.l,
    required this.t,
    this.worker,
    this.onBack,
  });

  final AppLocalizations l;
  final AppTypography t;
  final Worker? worker;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentWorker = worker;
    final active = currentWorker?.status == WorkerStatus.active;
    return SizedBox(
      height: 42,
      child: Row(children: [
        if (onBack != null) ...[
          HexoraButton(
            icon: Icons.arrow_back_rounded,
            label: l.back,
            size: HexoraButtonSize.compact,
            variant: HexoraButtonVariant.ghost,
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          l.addTimeEntryCta,
          style: t.titleLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: l.localeName.startsWith('es')
              ? worker == null
                  ? 'Selecciona los trabajadores y el horario que quieres registrar.'
                  : 'Selecciona el horario que quieres registrar para este trabajador.'
              : worker == null
                  ? 'Select the workers and schedule you want to register.'
                  : 'Select the schedule to register for this worker.',
          child: Icon(Icons.info_outline_rounded,
              size: 17, color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        if (currentWorker != null) ...[
          Flexible(
            child: Text(
              currentWorker.displayName ??
                  currentWorker.userId ??
                  l.unknownWorker,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  (active ? ThemeColors.success(context) : cs.onSurfaceVariant)
                      .withValues(alpha: .09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              active ? l.statusActive : l.statusInactive,
              style: t.caption.copyWith(
                color:
                    active ? ThemeColors.success(context) : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
