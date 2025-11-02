// event_form_router.dart
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/event_form_work_visit.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/simple/event_form_simple.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventFormRouter extends StatefulWidget {
  final BaseEventLogic logic;
  final Future<void> Function() onSubmit;
  final String ownerUserId;
  final CategoryApi categoryApi;
  final bool isEditing;

  /// Parent’s dialog impl (e.g., `this`)
  final EventDialogs dialogs;

  /// (Kept for backward-compat but ignored by option B)
  final bool enableClientServicePickers;

  const EventFormRouter({
    super.key,
    required this.logic,
    required this.onSubmit,
    required this.ownerUserId,
    required this.categoryApi,
    required this.dialogs,
    this.isEditing = false,
    this.enableClientServicePickers = false,
  });

  @override
  State<EventFormRouter> createState() => _EventFormRouterState();
}

class _EventFormRouterState extends State<EventFormRouter> {
  late String _type; // 'simple' | 'work_visit'

  @override
  void initState() {
    super.initState();

    // Default to work_visit unless logic explicitly says 'simple'
    _type = widget.logic.eventType.toLowerCase() == 'simple'
        ? 'simple'
        : 'work_visit';

    // Inform logic on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.logic.setEventType?.call(_type);
    });
  }

  void _setType(String t) {
    if (_type == t) return;
    setState(() => _type = t);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.logic.setEventType?.call(t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final bool isWork = _type == 'work_visit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l.chooseType,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),

        // Segmented chips
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TypeChip(
                icon: Icons.engineering_outlined,
                label: l.workVisit,
                selected: isWork,
                onTap: () => _setType('work_visit'),
                typo: typo,
              ),
              _TypeChip(
                icon: Icons.event_outlined,
                label: l.simpleEvent,
                selected: !isWork,
                onTap: () => _setType('simple'),
                typo: typo,
              ),
            ],
          ),
        ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(
            isWork ? l.workVisitHint : l.simpleEventHint,
            style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ),

        // Body
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: isWork
              ? KeyedSubtree(
                  key: const ValueKey('work_visit'),
                  child: EventFormWorkVisit(
                    logic: widget.logic,
                    onSubmit: widget.onSubmit,
                    ownerUserId: widget.ownerUserId,
                    isEditing: widget.isEditing,
                    dialogs: widget.dialogs,
                    // ✅ Option B: show pickers automatically when work_visit
                    enableClientServicePickers: true,
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('simple'),
                  child: EventFormSimple(
                    logic: widget.logic,
                    onSubmit: widget.onSubmit,
                    ownerUserId: widget.ownerUserId,
                    categoryApi: widget.categoryApi,
                    isEditing: widget.isEditing,
                    dialogs: widget.dialogs,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppTypography typo;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.typo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: (selected ? typo.bodyMedium : typo.bodySmall).copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? cs.onPrimaryContainer : cs.onSurface,
          letterSpacing: .2,
        ),
      ),
      selectedColor: cs.primaryContainer,
      backgroundColor: cs.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? cs.primaryContainer : cs.outlineVariant,
          width: selected ? 1.2 : 1,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}
