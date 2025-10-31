import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/event_detail/sections/work_visit/widgets/services_wrap.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/event_detail/sections/work_visit/widgets/toned_raw.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/section_card.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkVisitSection extends StatelessWidget {
  final String? clientLabel;
  final String? primaryServiceLabel;
  final List<String> visitServices;
  final int maxVisibleServices;

  const WorkVisitSection({
    super.key,
    this.clientLabel,
    this.primaryServiceLabel,
    required this.visitServices,
    this.maxVisibleServices = 6,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final hasClient = (clientLabel?.trim().isNotEmpty ?? false);
    final hasPrimary = (primaryServiceLabel?.trim().isNotEmpty ?? false);
    final services = visitServices.where((s) => s.trim().isNotEmpty).toList();

    return SectionCard(
      title: l.workVisitSectionTitle,
      children: [
        if (hasClient)
          TonedRow(
            icon: Icons.person_pin_circle_outlined,
            iconBg: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            label: l.clientLabel,
            value: clientLabel!,
          ),
        if (hasClient && hasPrimary) const SizedBox(height: 6),
        if (hasPrimary)
          TonedRow(
            icon: Icons.home_repair_service_outlined,
            iconBg: cs.secondaryContainer,
            iconColor: cs.onSecondaryContainer,
            label: l.servicePrimaryLabel,
            value: primaryServiceLabel!,
          ),
        if (services.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l.services,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          ServicesWrap(
            services: services,
            maxVisible: maxVisibleServices,
          ),
        ],
        if (!hasClient && !hasPrimary && services.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.noWorkVisitData,
              style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
