import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Visual variant for [HexoraButton].
enum HexoraButtonVariant {
  /// Blue filled — primary action per screen.
  primary,

  /// Outlined neutral — secondary or cancel actions.
  secondary,

  /// Soft filled — uses the secondary container, for secondary-but-emphasized actions.
  tonal,

  /// Transparent background — low-emphasis or toolbar actions.
  ghost,

  /// Red filled — destructive / irreversible actions.
  danger,
}

/// Size variant for [HexoraButton].
enum HexoraButtonSize {
  /// 30 px tall — for dense toolbars and inline rows.
  compact,

  /// 34 px tall — default for most UI.
  standard,

  /// 38 px tall — hero CTAs or prominent dialog actions.
  large,
}

/// Hexora's canonical button.
///
/// Covers all five action tiers (primary, secondary, ghost, danger, icon-only)
/// and three sizes (compact 30 px, standard 34 px, large 38 px).
///
/// Usage:
/// ```dart
/// HexoraButton(label: 'Save', onPressed: _save);
/// HexoraButton(icon: Icons.add, label: 'New invoice', onPressed: _create);
/// HexoraButton.iconOnly(icon: Icons.delete, tooltip: 'Delete', onPressed: _delete, variant: HexoraButtonVariant.danger);
/// HexoraButton(label: 'Save', onPressed: null, loading: true);
/// ```
class HexoraButton extends StatelessWidget {
  const HexoraButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.variant = HexoraButtonVariant.primary,
    this.size = HexoraButtonSize.standard,
    this.loading = false,
    this.tooltip,
    this.accentColor,
  }) : _iconOnly = false;

  const HexoraButton.iconOnly({
    super.key,
    required this.onPressed,
    required IconData this.icon,
    required String this.tooltip,
    this.variant = HexoraButtonVariant.ghost,
    this.size = HexoraButtonSize.standard,
    this.loading = false,
    this.accentColor,
  })  : _iconOnly = true,
        label = null,
        trailingIcon = null;

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final HexoraButtonVariant variant;
  final HexoraButtonSize size;
  final bool loading;
  final String? tooltip;
  final Color? accentColor;
  final bool _iconOnly;

  // ── sizing ────────────────────────────────────────────────────────────────

  double get _height => switch (size) {
        HexoraButtonSize.compact => HexoraDimensions.buttonCompact,
        HexoraButtonSize.standard => HexoraDimensions.buttonStandard,
        HexoraButtonSize.large => HexoraDimensions.buttonLarge,
      };

  double get _hPad => switch (size) {
        HexoraButtonSize.compact => 10,
        HexoraButtonSize.standard => HexoraTableTokens.cellPadding,
        HexoraButtonSize.large => 16,
      };

  double get _fontSize => switch (size) {
        HexoraButtonSize.compact => HexoraTypography.label,
        HexoraButtonSize.standard => HexoraTypography.label,
        HexoraButtonSize.large => HexoraTypography.body,
      };

  // ── style per variant ─────────────────────────────────────────────────────

  ButtonStyle _style(ColorScheme cs) {
    final base = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
          _iconOnly ? Size.square(_height) : Size(0, _height)),
      maximumSize:
          _iconOnly ? WidgetStatePropertyAll(Size.square(_height)) : null,
      fixedSize:
          _iconOnly ? WidgetStatePropertyAll(Size.square(_height)) : null,
      padding: WidgetStatePropertyAll(
        _iconOnly ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: _hPad),
      ),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(HexoraDimensions.radius)))),
      textStyle: WidgetStatePropertyAll(TextStyle(
        fontFamily: HexoraTypography.fontFamily,
        fontSize: _fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      )),
      iconSize: const WidgetStatePropertyAll(HexoraDimensions.buttonIconSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );

    return switch (variant) {
      HexoraButtonVariant.primary => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return cs.onSurface.withValues(alpha: 0.12);
            }
            if (s.contains(WidgetState.pressed)) {
              return cs.primary.withValues(alpha: 0.86);
            }
            if (s.contains(WidgetState.hovered)) {
              return cs.primary.withValues(alpha: 0.92);
            }
            return cs.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : cs.onPrimary),
          overlayColor:
              WidgetStatePropertyAll(cs.onPrimary.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      HexoraButtonVariant.secondary => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            if (s.contains(WidgetState.pressed)) {
              return cs.onSurface.withValues(alpha: 0.10);
            }
            if (s.contains(WidgetState.hovered)) {
              return cs.onSurface.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : cs.onSurface),
          overlayColor:
              WidgetStatePropertyAll(cs.onSurface.withValues(alpha: 0.06)),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.12)
                  : cs.outlineVariant)),
        ),
      HexoraButtonVariant.tonal => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return cs.onSurface.withValues(alpha: 0.12);
            }
            if (s.contains(WidgetState.pressed)) {
              return cs.secondaryContainer.withValues(alpha: 0.86);
            }
            if (s.contains(WidgetState.hovered)) {
              return cs.secondaryContainer.withValues(alpha: 0.92);
            }
            return cs.secondaryContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : cs.onSecondaryContainer),
          overlayColor: WidgetStatePropertyAll(
              cs.onSecondaryContainer.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      HexoraButtonVariant.ghost => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return Colors.transparent;
            if (s.contains(WidgetState.pressed)) {
              return (accentColor ?? cs.onSurface).withValues(alpha: 0.10);
            }
            if (s.contains(WidgetState.hovered)) {
              return (accentColor ?? cs.onSurface).withValues(alpha: 0.06);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : accentColor ?? cs.onSurfaceVariant),
          overlayColor:
              WidgetStatePropertyAll(cs.onSurface.withValues(alpha: 0.06)),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
      HexoraButtonVariant.danger => base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return cs.onSurface.withValues(alpha: 0.12);
            }
            if (s.contains(WidgetState.pressed)) {
              return cs.error.withValues(alpha: 0.86);
            }
            if (s.contains(WidgetState.hovered)) {
              return cs.error.withValues(alpha: 0.92);
            }
            return cs.error;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled)
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : cs.onError),
          overlayColor:
              WidgetStatePropertyAll(cs.onError.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
        ),
    };
  }

  // ── content ───────────────────────────────────────────────────────────────

  Widget _buildContent(bool disabled) {
    if (loading) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation(disabled
              ? Colors.grey
              : variant == HexoraButtonVariant.primary ||
                      variant == HexoraButtonVariant.danger
                  ? Colors.white
                  : null),
        ),
      );
    }

    if (_iconOnly) {
      return Icon(icon!, size: HexoraDimensions.buttonIconSize);
    }

    final parts = <Widget>[];
    if (icon != null) {
      parts.add(Icon(icon!, size: HexoraDimensions.buttonIconSize));
      if (label != null) {
        parts.add(const SizedBox(width: HexoraDimensions.buttonIconGap));
      }
    }
    if (label != null) {
      parts.add(Text(label!));
    }
    if (trailingIcon != null) {
      if (parts.isNotEmpty) {
        parts.add(const SizedBox(width: HexoraDimensions.buttonIconGap));
      }
      parts.add(Icon(trailingIcon!, size: HexoraDimensions.buttonIconSize));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: parts,
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _style(cs);
    final disabled = onPressed == null && !loading;
    final effectiveOnPressed = loading ? () {} : onPressed;

    Widget btn = TextButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: _buildContent(disabled),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      btn = Tooltip(
        message: tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: btn,
      );
    }

    return btn;
  }
}
