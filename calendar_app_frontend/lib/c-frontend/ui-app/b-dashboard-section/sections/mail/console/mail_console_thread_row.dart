part of '../mail_console_screen.dart';

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final MailThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    final sender = _friendlySender(thread.participants, l);
    final snippet = thread.snippet?.trim() ?? '';
    final dateLabel = _formatRelativeDate(thread.latestDate, locale: l.localeName);
    final fullDateLabel = _formatFullDate(thread.latestDate);

    final isUnread = thread.unreadCount > 0;
    final hasExtraUnread = thread.unreadCount > 1;

    final background = selected
        ? cs.primaryContainer.withValues(alpha: 0.18)
        : isUnread
            ? cs.primaryContainer.withValues(alpha: 0.07)
            : Colors.transparent;

    return Stack(
      children: [
        Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            hoverColor: cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Row 1: sender + date ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isUnread)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5, top: 1),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            sender,
                            style: t.bodySmall.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: fullDateLabel,
                          preferBelow: true,
                          child: SizedBox(
                            width: 32,
                            child: Text(
                              dateLabel,
                              style: t.bodySmall.copyWith(
                                color: isUnread
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // ── Row 2: subject + badges ───────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: t.bodySmall.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: isUnread
                                  ? cs.onSurface
                                  : cs.onSurface
                                      .withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (thread.hasAttachments)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.attach_file,
                              size: 13,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        if (thread.messageCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${thread.messageCount}',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (hasExtraUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: t.bodySmall.copyWith(
                                color: cs.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // ── Row 3: snippet (only if non-empty) ───────────
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        snippet,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Selected left bar ───────────────────────────────────────
        if (selected)
          Positioned(
            left: 0,
            top: 5,
            bottom: 5,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Skeleton row ─────────────────────────────────────────────────────────────

class _SkeletonThreadRow extends StatefulWidget {
  const _SkeletonThreadRow({super.key, this.seed = 0});

  final int seed;

  @override
  State<_SkeletonThreadRow> createState() => _SkeletonThreadRowState();
}

class _SkeletonThreadRowState extends State<_SkeletonThreadRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    // Stagger by seed so rows don't all pulse in sync
    if (widget.seed > 0) {
      _ctrl.forward(from: (widget.seed * 0.18) % 1.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = _anim.value;
        final base = cs.onSurface.withValues(alpha: 0.055 + 0.055 * v);
        final faint = cs.onSurface.withValues(alpha: 0.035 + 0.035 * v);
        // Vary widths per row so they don't all look identical
        final senderW = 70.0 + (widget.seed % 4) * 18.0;
        final subjectW = 110.0 + (widget.seed % 5) * 14.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _pill(senderW, 9, base),
                  const Spacer(),
                  _pill(22, 9, base),
                ],
              ),
              const SizedBox(height: 5),
              _pill(subjectW, 10, base),
              const SizedBox(height: 4),
              _pill(double.infinity, 8, faint),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(double width, double height, Color color) => Container(
        height: height,
        width: width == double.infinity ? null : width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      );
}
