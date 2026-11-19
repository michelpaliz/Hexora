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
        child: HexoraButton(
          onPressed: enabled && !sending ? onSend : null,
          icon: Icons.send_outlined,
          label: label,
          variant: HexoraButtonVariant.primary,
          size: HexoraButtonSize.standard,
          loading: sending,
        ));
    final guidance = Row(children: [
      Icon(Icons.info_outline, size: 16, color: cs.primary),
      const SizedBox(width: 8),
      Expanded(
          child: Text(hint ?? '',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant))),
    ]);
    return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: .45)),
              ),
              borderRadius: BorderRadius.circular(8)),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                if (hint != null) ...[guidance, const SizedBox(height: 4)],
                SizedBox(width: double.infinity, child: button),
              ]);
            }
            return Row(children: [
              if (hint != null) Expanded(child: guidance) else const Spacer(),
              const SizedBox(width: 16),
              SizedBox(width: 200, child: button)
            ]);
          }),
        ));
  }
}
