import 'package:flutter/material.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

/// Full-page branded loading state used while Hexora prepares the workspace.
class HexoraLoadingView extends StatefulWidget {
  const HexoraLoadingView({
    super.key,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;

  @override
  State<HexoraLoadingView> createState() => _HexoraLoadingViewState();
}

class _HexoraLoadingViewState extends State<HexoraLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final CurvedAnimation _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = HexoraMotion.reduceMotion(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final title =
        widget.title ?? (isEs ? 'Bienvenido a Hexora' : 'Welcome to Hexora');
    final message = widget.message ??
        (isEs
            ? 'Preparando tu espacio de trabajo…'
            : 'Preparing your workspace…');

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  child: const HexoraBrandIcon(
                    size: 68,
                    excludeFromSemantics: true,
                  ),
                  builder: (context, child) {
                    final value = _pulse.value;
                    return Transform.scale(
                      scale: 0.97 + (value * 0.03),
                      child: Opacity(
                        opacity: 0.82 + (value * 0.18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(
                                  alpha: 0.08 + (value * 0.08),
                                ),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 112,
                  child: LinearProgressIndicator(
                    value: _reduceMotion == true ? 0.68 : null,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(999),
                    color: cs.primary,
                    backgroundColor: cs.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
