import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:provider/provider.dart';

/// Replaces the old "Members" icon with a compact, live worker-status
/// indicator (👥 3 trabajando ▾). The count comes from the time-tracking
/// "active workers" total; the popover lists active workers and, only when
/// presence is available, the group members who are online.
class WorkerStatusIndicator extends StatefulWidget {
  const WorkerStatusIndicator({
    super.key,
    required this.groupId,
    required this.memberIds,
    required this.groupRoles,
    required this.onOpenWorkers,
  });

  final String groupId;
  final List<String> memberIds;
  final Map<String, String> groupRoles;
  final VoidCallback onOpenWorkers;

  @override
  State<WorkerStatusIndicator> createState() => _WorkerStatusIndicatorState();
}

class _WorkerStatusIndicatorState extends State<WorkerStatusIndicator> {
  int _activeCount = 0;
  bool _loading = true;
  bool _hasError = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant WorkerStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final userDomain = context.read<UserDomain>();
    final repo = context.read<ITimeTrackingRepository>();
    try {
      final token = await userDomain.getAuthToken();
      final totals = await repo.getActiveWorkersTotals(widget.groupId, token);
      if (!mounted) return;
      setState(() {
        _activeCount = (totals['activeWorkersCount'] as num?)?.toInt() ?? 0;
        _loading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _load();
  }

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  Widget build(BuildContext context) {
    final presence = context.watch<PresenceDomain>();
    final onlineMembers = presence
        .getPresenceForGroup(widget.memberIds, widget.groupRoles)
        .where((user) => user.isOnline)
        .toList(growable: false);
    // Only report a count once presence has been received; otherwise it is
    // "unavailable" and must not be shown as a confirmed zero.
    final int? onlineCount =
        presence.hasReceivedPresence ? onlineMembers.length : null;

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < 760;
    final menuWidth = viewportWidth >= 296 ? 280.0 : viewportWidth - 16;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: hexoraDropdownMenuStyle().copyWith(
        minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
        maximumSize: WidgetStatePropertyAll(Size(menuWidth, double.infinity)),
      ),
      menuChildren: _buildMenu(context, onlineCount),
      builder: (context, controller, _) => HexoraNavTile(
        tooltip: _isSpanish ? 'Estado de los trabajadores' : 'Worker status',
        semanticLabel:
            _isSpanish ? '$_activeCount trabajando' : '$_activeCount working',
        padding: const EdgeInsets.symmetric(
          horizontal: NavigationTokens.globalItemPadding,
        ),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        builder: (context, fg) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined,
                size: NavigationTokens.iconSize, color: fg),
            const SizedBox(width: 6),
            Text(
              '$_activeCount',
              style: NavigationTokens.label(context)
                  .copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _isSpanish ? 'trabajando' : 'working',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NavigationTokens.label(context).copyWith(color: fg),
                ),
              ),
            ],
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenu(BuildContext context, int? onlineCount) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return [
      if (_loading)
        _StatusRow(
          icon: Icons.badge_outlined,
          label: _isSpanish ? 'Trabajando ahora' : 'Working now',
          trailing: const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        _StatusRow(
          icon: Icons.badge_outlined,
          label: _isSpanish ? 'Trabajando ahora' : 'Working now',
          count: _hasError ? null : _activeCount,
        ),
      if (_hasError) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            _isSpanish
                ? 'No se pudo cargar el estado.'
                : 'Could not load status.',
            style: text.bodySmall?.copyWith(color: cs.error),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.refresh_rounded, size: 16),
          onPressed: _retry,
          child: Text(_isSpanish ? 'Reintentar' : 'Retry'),
        ),
      ],
      const Divider(height: 8),
      _StatusRow(
        icon: Icons.online_prediction_outlined,
        label: _isSpanish ? 'Conectados' : 'Online',
        count: onlineCount,
      ),
      const Divider(height: 8),
      MenuItemButton(
        leadingIcon: const Icon(Icons.group_outlined, size: 16),
        trailingIcon: const Icon(Icons.chevron_right_rounded, size: 18),
        onPressed: widget.onOpenWorkers,
        child: Text(_isSpanish ? 'Ver trabajadores' : 'View workers'),
      ),
    ];
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    this.count,
    this.trailing,
  });

  final IconData icon;
  final String label;

  /// null = unavailable (renders a dash).
  final int? count;

  /// When provided (e.g. a loading spinner) it replaces the count.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          trailing ??
              (count == null ? null : _StatusCountBadge(count: count!)) ??
              Text(
                count == null ? '—' : '$count',
                style: text.bodyMedium?.copyWith(
                  color: count == null ? cs.onSurfaceVariant : cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusCountBadge extends StatelessWidget {
  const _StatusCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
