part of '../../presupuesto_template_editor_screen.dart';

class _RestrictedMarkdownText extends StatelessWidget {
  const _RestrictedMarkdownText({
    required this.data,
    this.style,
  });

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: _restrictedMarkdownSpans(data),
      ),
    );
  }
}
