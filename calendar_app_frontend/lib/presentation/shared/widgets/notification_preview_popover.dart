import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_localization.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A lightweight notification inbox anchored to the global navigation bell.
///
/// Hovering provides a temporary preview while clicking pins the preview open
/// for touch and keyboard users. The full notifications workspace remains the
/// owner of notification actions and destination routing.
class NotificationPreviewPopover extends StatefulWidget {
  const NotificationPreviewPopover({
    super.key,
    required this.notifications,
    required this.unreadCount,
    required this.selected,
    required this.onOpenAll,
    required this.onMarkAllRead,
    this.onNotificationTap,
    this.openDelay = const Duration(milliseconds: 250),
    this.closeDelay = const Duration(milliseconds: 180),
  });

  final List<NotificationUser> notifications;
  final int unreadCount;
  final bool selected;
  final VoidCallback onOpenAll;
  final Future<void> Function() onMarkAllRead;
  final ValueChanged<NotificationUser>? onNotificationTap;
  final Duration openDelay;
  final Duration closeDelay;

  @override
  State<NotificationPreviewPopover> createState() =>
      _NotificationPreviewPopoverState();
}

class _NotificationPreviewPopoverState
    extends State<NotificationPreviewPopover> {
  final GlobalKey _anchorKey = GlobalKey();
  Timer? _openTimer;
  Timer? _closeTimer;
  OverlayEntry? _entry;
  bool _anchorHovered = false;
  bool _popoverHovered = false;
  bool _pinned = false;
  bool _markingAllRead = false;

  bool get _isOpen => _entry != null;

  @override
  void didUpdateWidget(covariant NotificationPreviewPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _scheduleOpen() {
    _closeTimer?.cancel();
    if (_isOpen || _openTimer?.isActive == true) return;
    _openTimer = Timer(widget.openDelay, () {
      if (mounted && _anchorHovered) _show();
    });
  }

  void _scheduleClose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    if (_pinned) return;
    _closeTimer = Timer(widget.closeDelay, () {
      if (mounted && !_anchorHovered && !_popoverHovered) _hide();
    });
  }

  void _togglePinned() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    if (_isOpen && _pinned) {
      _hide();
      return;
    }
    _pinned = true;
    _show();
  }

  void _show() {
    if (_isOpen || !mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  void _hide() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    _entry?.remove();
    _entry = null;
    _pinned = false;
    _popoverHovered = false;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return const SizedBox.shrink();
    final anchor = anchorContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(overlayContext).context.findRenderObject() as RenderBox?;
    if (anchor == null || overlay == null || !anchor.hasSize) {
      return const SizedBox.shrink();
    }

    final anchorTopLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorRect = anchorTopLeft & anchor.size;
    final viewport = overlay.size;
    final width = (viewport.width - 24).clamp(280.0, 372.0);
    final maxHeight = (viewport.height - 32).clamp(220.0, 480.0);
    final left = (anchorRect.right - width)
        .clamp(12.0, (viewport.width - width - 12).clamp(12.0, viewport.width));
    const gap = 8.0;
    final roomBelow = viewport.height - anchorRect.bottom - gap - 12;
    final placeBelow = roomBelow >= 300 || anchorRect.top < roomBelow;
    final top = placeBelow ? anchorRect.bottom + gap : null;
    final bottom = placeBelow ? null : viewport.height - anchorRect.top + gap;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          bottom: bottom,
          width: width,
          child: TapRegion(
            onTapOutside: (_) {
              if (_pinned) _hide();
            },
            child: MouseRegion(
              onEnter: (_) {
                _popoverHovered = true;
                _closeTimer?.cancel();
              },
              onExit: (_) {
                _popoverHovered = false;
                _scheduleClose();
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: _NotificationPreviewSurface(
                  notifications: widget.notifications.take(6).toList(),
                  unreadCount: widget.unreadCount,
                  markingAllRead: _markingAllRead,
                  onClose: _hide,
                  onMarkAllRead: _markAllRead,
                  onOpenAll: () {
                    _hide();
                    widget.onOpenAll();
                  },
                  onNotificationTap: (notification) {
                    _hide();
                    (widget.onNotificationTap ?? (_) => widget.onOpenAll())(
                      notification,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead || widget.unreadCount == 0) return;
    _markingAllRead = true;
    _entry?.markNeedsBuild();
    try {
      await widget.onMarkAllRead();
    } finally {
      _markingAllRead = false;
      _entry?.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final tooltip = widget.unreadCount > 0
        ? (isEs
            ? 'Notificaciones (${widget.unreadCount} sin leer)'
            : 'Notifications (${widget.unreadCount} unread)')
        : (isEs ? 'Notificaciones' : 'Notifications');
    return MouseRegion(
      key: _anchorKey,
      onEnter: (_) {
        _anchorHovered = true;
        _scheduleOpen();
      },
      onExit: (_) {
        _anchorHovered = false;
        _scheduleClose();
      },
      child: HexoraNavIconButton(
        key: const ValueKey('notification-preview-trigger'),
        icon: widget.unreadCount > 0 ? LucideIcons.bellRing : LucideIcons.bell,
        tooltip: tooltip,
        selected: widget.selected,
        badgeCount: widget.unreadCount,
        onPressed: _togglePinned,
      ),
    );
  }
}

class _NotificationPreviewSurface extends StatelessWidget {
  const _NotificationPreviewSurface({
    required this.notifications,
    required this.unreadCount,
    required this.markingAllRead,
    required this.onClose,
    required this.onMarkAllRead,
    required this.onOpenAll,
    required this.onNotificationTap,
  });

  final List<NotificationUser> notifications;
  final int unreadCount;
  final bool markingAllRead;
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;
  final VoidCallback onOpenAll;
  final ValueChanged<NotificationUser> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return Material(
      key: const ValueKey('notification-preview-popover'),
      color: cs.surface,
      elevation: 12,
      shadowColor: cs.shadow.withValues(alpha: 0.22),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.72)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEs ? 'Notificaciones' : 'Notifications',
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('notification-preview-mark-all'),
                    onPressed: unreadCount == 0 || markingAllRead
                        ? null
                        : onMarkAllRead,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: markingAllRead
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEs ? 'Marcar todas como leídas' : 'Mark all read',
                            style: t.bodySmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  IconButton(
                    key: const ValueKey('notification-preview-close'),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    constraints:
                        const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .55)),
            Flexible(
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 28,
                              color: cs.onSurfaceVariant.withValues(alpha: .7)),
                          const SizedBox(height: 8),
                          Text(
                            isEs
                                ? 'No hay notificaciones recientes'
                                : 'No recent notifications',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 54,
                        color: cs.outlineVariant.withValues(alpha: .42),
                      ),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationPreviewRow(
                          key: ValueKey(
                              'notification-preview-item-${notification.id}'),
                          notification: notification,
                          onTap: () => onNotificationTap(notification),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .55)),
            InkWell(
              key: const ValueKey('notification-preview-view-all'),
              onTap: onOpenAll,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        isEs
                            ? 'Ver todas las notificaciones'
                            : 'View all notifications',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.arrow_forward_rounded,
                        size: 15, color: cs.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreviewRow extends StatelessWidget {
  const _NotificationPreviewRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationUser notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final meta = resolveNotifMeta(notification, cs);
    final unread = !notification.isRead;
    return Material(
      color: unread ? cs.primary.withValues(alpha: .065) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(meta.icon, size: 17, color: meta.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.getLocalizedTitle(l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.circle, size: 7, color: cs.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.getLocalizedMessage(l),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatTimeDifference(notification.timestamp, context),
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: .82),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
