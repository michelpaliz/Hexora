part of '../../mail_compose_screen.dart';

/// Bottom bar with send button for email composition
class _ComposeBottomBar extends StatelessWidget {
  const _ComposeBottomBar({
    required this.sending,
    required this.enabled,
    required this.onSend,
    required this.label,
  });

  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: t.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            onPressed: enabled && !sending
                ? () {
                    debugPrint('[MailCompose] send button tapped');
                    onSend();
                  }
                : null,
            icon: sending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}
