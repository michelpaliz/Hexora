part of '../../mail_compose_screen.dart';

class _ComposeBottomBar extends StatelessWidget {
  const _ComposeBottomBar(
      {required this.sending,
      required this.enabled,
      required this.onSend,
      required this.label,
      this.disabledHint});
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  final String label;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final hint = !enabled && !sending ? disabledHint : null;
    final button = Tooltip(
        message: hint ?? '',
        child: FilledButton.icon(
          onPressed: enabled && !sending ? onSend : null,
          style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          icon: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(label),
        ));
    final guidance = Row(children: [
      Icon(Icons.info_outline, size: 16, color: cs.primary),
      const SizedBox(width: 8),
      Expanded(
          child: Text(
              hint ??
                  (Localizations.localeOf(context).languageCode == 'es'
                      ? 'Revisa los destinatarios y adjuntos antes de enviar.'
                      : 'Review recipients and attachments before sending.'),
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant))),
    ]);
    return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                if (hint != null) ...[guidance, const SizedBox(height: 6)],
                SizedBox(width: double.infinity, child: button),
              ]);
            }
            return Row(children: [
              Expanded(child: guidance),
              const SizedBox(width: 16),
              SizedBox(width: 240, child: button)
            ]);
          }),
        ));
  }
}
