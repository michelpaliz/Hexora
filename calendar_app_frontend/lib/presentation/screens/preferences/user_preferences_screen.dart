import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/preferences/preference_controls.dart';

/// Full-screen preferences route used from the profile, home and account menus.
///
/// The Settings workspace lays the same controls (see
/// `preference_controls.dart`) out in its own two-column dashboard.
class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.preferencesTitle),
      ),
      body: const SafeArea(child: UserPreferencesView()),
    );
  }
}

/// Embeddable preferences content (no Scaffold or AppBar), so it can be hosted
/// either by [UserPreferencesScreen] or inline inside the Settings screen.
class UserPreferencesView extends StatelessWidget {
  const UserPreferencesView({
    super.key,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 40),
    this.alignment = Alignment.topCenter,
  });

  /// Maximum content width; callers align it with the surrounding layout.
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Horizontal/vertical anchor of the capped content. The standalone route
  /// centers it.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreferencesGroup(
          icon: Icons.navigation_outlined,
          label: l.preferencesNavigation,
          child: const NavigationPreference(),
        ),
        const SizedBox(height: 12),
        _PreferencesGroup(
          icon: Icons.palette_outlined,
          label: l.preferencesAppearance,
          child: const AppearancePreference(),
        ),
        const SizedBox(height: 12),
        _PreferencesGroup(
          icon: Icons.language_rounded,
          label: l.preferencesLanguage,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: LanguagePreference(),
          ),
        ),
      ],
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        padding: padding,
        child: constrained,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreferencesGroup extends StatelessWidget {
  const _PreferencesGroup({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(icon: icon, label: label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
