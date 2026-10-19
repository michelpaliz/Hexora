import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:intl/intl.dart';
import 'worker_directory_tabs.dart';

class WorkerDirectoryCard extends StatelessWidget {
  const WorkerDirectoryCard(
      {super.key,
      required this.worker,
      required this.selected,
      required this.onEdit,
      required this.onAddHours,
      required this.onOverview,
      this.partnerRole,
      this.grid = false});

  final Worker worker;
  final WorkerPartnerRole? partnerRole;
  final bool selected;
  final bool grid;
  final VoidCallback onEdit;
  final VoidCallback onAddHours;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.startsWith('es');
    final dark = cs.brightness == Brightness.dark;
    final name =
        (worker.displayName ?? worker.userId ?? l.unknownWorker).trim();
    final linked = (worker.userId ?? '').isNotEmpty;
    final active = worker.status == WorkerStatus.active;
    final green = ThemeColors.success(context);
    final violet = dark ? const Color(0xffc8b6ff) : const Color(0xff5943d6);
    final avatarColor = cs.onSurfaceVariant;
    String number(num amount) =>
        NumberFormat('#,##0.##', l.localeName).format(amount);
    Widget chip(IconData icon, String label, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .07),
              border: Border.all(color: color.withValues(alpha: .14)),
              borderRadius: BorderRadius.circular(11)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Flexible(
                child: Tooltip(
                    message: label,
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontFeatures: HexoraTypography.numericFeatures,
                            fontWeight: FontWeight.w600,
                            color: color))))
          ]),
        );
    final metrics = Wrap(spacing: 6, runSpacing: 4, children: [
      if ((worker.defaultHourlyRate ?? 0) > 0)
        chip(
            Icons.payments_outlined,
            '${number(worker.defaultHourlyRate!)} ${worker.currency ?? 'EUR'}/h',
            green),
    ]);
    final buttonStyle = ThemedButtons.iconAction(context);
    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton.outlined(
          tooltip: l.addTimeEntryCta,
          onPressed: onAddHours,
          style: buttonStyle,
          icon: Icon(Icons.schedule_outlined, size: 17, color: cs.primary)),
      const SizedBox(width: 5),
      IconButton.outlined(
          tooltip: l.overviewInfoTitle,
          onPressed: onOverview,
          style: buttonStyle,
          icon: const Icon(Icons.calendar_view_month_outlined, size: 17)),
      const SizedBox(width: 5),
      IconButton.outlined(
          tooltip: l.editWorker,
          onPressed: onEdit,
          style: buttonStyle,
          icon: const Icon(Icons.edit_outlined, size: 17)),
      const SizedBox(width: 5),
      SizedBox(
          width: ThemedButtons.actionTarget(context),
          height: ThemedButtons.actionTarget(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              tooltip: isEs ? 'Más opciones' : 'More options',
              icon: const Icon(Icons.more_vert_rounded, size: 17),
              onSelected: (value) async {
                if (value == 'copy') {
                  await Clipboard.setData(ClipboardData(text: name));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isEs ? 'Nombre copiado' : 'Name copied')));
                } else {
                  showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(name),
                            content: SelectableText(worker.notes!),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(MaterialLocalizations.of(context)
                                      .closeButtonLabel))
                            ],
                          ));
                }
              },
              itemBuilder: (_) => [
                NavigationPopupMenuItem(
                    value: 'copy',
                    child: Text(isEs ? 'Copiar nombre' : 'Copy name')),
                if ((worker.notes ?? '').trim().isNotEmpty)
                  NavigationPopupMenuItem(
                      value: 'notes',
                      child: Text(isEs ? 'Ver notas' : 'View notes')),
              ],
            ),
          )),
    ]);
    final description =
        '${linked ? l.linkedUser : l.externalWorker}${(worker.roleTag ?? '').isEmpty ? '' : ' · ${worker.roleTag}'}';
    final roleLabel = switch (partnerRole) {
      WorkerPartnerRole.owner => isEs ? 'Propietario' : 'Owner',
      WorkerPartnerRole.admin => isEs ? 'Administrador' : 'Admin',
      WorkerPartnerRole.coAdmin => 'Co-admin',
      null => null,
    };
    final roleColor =
        partnerRole == WorkerPartnerRole.coAdmin ? violet : cs.primary;
    final identity = Row(children: [
      CircleAvatar(
          radius: 15,
          backgroundColor: avatarColor.withValues(alpha: .10),
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                  color: avatarColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600))),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: HexoraTypography.body,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        const SizedBox(height: 3),
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: (active ? green : cs.onSurfaceVariant)
                      .withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(active ? l.statusActive : l.statusInactive,
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? green : cs.onSurfaceVariant))),
          const SizedBox(width: 6),
          Expanded(
              child: roleLabel != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message:
                            '${isEs ? 'Rol en el equipo' : 'Team role'}: $roleLabel',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                                partnerRole == WorkerPartnerRole.owner
                                    ? Icons.verified_user_outlined
                                    : Icons.admin_panel_settings_outlined,
                                size: 12,
                                color: roleColor),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(roleLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: roleColor))),
                          ]),
                        ),
                      ))
                  : Tooltip(
                      message: description,
                      child: Text(description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)))),
        ]),
      ])),
    ]);
    return HexoraListRow(
      selected: selected,
      onTap: onEdit,
      child: LayoutBuilder(builder: (context, constraints) {
        final stacked = grid ||
            constraints.maxWidth < 480 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        if (stacked) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [metrics, actions]),
              ]);
        }
        return Row(children: [
          Expanded(child: identity),
          const SizedBox(width: 8),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120), child: metrics),
          const SizedBox(width: 8),
          actions
        ]);
      }),
    );
  }
}
