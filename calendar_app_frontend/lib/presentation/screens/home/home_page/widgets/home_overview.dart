import 'package:flutter/material.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/announcements/announcements_screen.dart';
import 'package:hexora/presentation/shared/widgets/announcements/announcement_panel.dart';
import 'business_selector_section.dart';
import 'home_quick_guide.dart';

/// Home's responsive overview. All actions reuse existing workspace flows.
class HomeOverview extends StatelessWidget {
  const HomeOverview(
      {super.key,
      required this.user,
      required this.groupsKey,
      required this.onSettings,
      required this.onProfile});
  final User user;
  final GlobalKey groupsKey;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final completed = [
      user.name.trim().isNotEmpty,
      user.photoUrl?.trim().isNotEmpty == true,
      user.location?.trim().isNotEmpty == true
    ].where((value) => value).length;
    final main =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Surface(
          child: AnnouncementPanel(
        placement: 'home',
        limit: 3,
        tiles: true,
        showEmptyState: true,
        onViewAll: () => showAnnouncementsDialog(context),
      )),
      const SizedBox(height: 16),
      _Surface(
          key: groupsKey,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const BusinessSelectorSection(showHelp: false)),
    ]);
    final sidebar =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                Color.lerp(cs.primary, const Color(0xFF062C80), .55)!
              ]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.fact_check_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 14),
          Text(es ? 'Saca más partido a Hexora' : 'Make the most of Hexora',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              es
                  ? 'Completa tu perfil con tu nombre, foto y ubicación.'
                  : 'Complete your profile with your name, photo and location.',
              style: const TextStyle(color: Colors.white, height: 1.5)),
          const SizedBox(height: 20),
          Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                es
                                    ? '$completed de 3 datos completados'
                                    : '$completed of 3 details completed',
                                style: const TextStyle(
                                    color: Color(0xFF344564), fontSize: 12)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                                value: completed / 3,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF2463FF),
                                backgroundColor: const Color(0xFFE3EBFA)),
                          ])),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right, color: Color(0xFF344564)),
                    ])),
              )),
        ]),
      ),
      const SizedBox(height: 18),
      _Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(context, Icons.bolt_rounded,
            es ? 'Accesos rápidos' : 'Quick actions'),
        const SizedBox(height: 18),
        LayoutBuilder(
            builder: (context, constraints) =>
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final action in <(IconData, String, VoidCallback)>[
                    (
                      Icons.add_rounded,
                      es ? 'Crear negocio' : 'Create business',
                      () => openHomeCreateBusiness(context)
                    ),
                    (
                      Icons.person_outline,
                      es ? 'Mi perfil' : 'My profile',
                      onProfile
                    ),
                    (
                      Icons.tune_rounded,
                      es ? 'Configuración' : 'Settings',
                      onSettings
                    ),
                    (
                      Icons.calendar_today_outlined,
                      es ? 'Ver calendario' : 'View calendar',
                      () => Navigator.pushNamed(context, AppRoutes.agenda)
                    ),
                  ])
                    SizedBox(
                      width: (constraints.maxWidth - 10) / 2,
                      child: OutlinedButton(
                          onPressed: action.$3,
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 18),
                              side: BorderSide(
                                  color: cs.primary.withValues(alpha: .14)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: Column(children: [
                            Icon(action.$1, size: 24),
                            const SizedBox(height: 8),
                            Text(action.$2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: cs.onSurface, fontSize: 12))
                          ])),
                    ),
                ])),
      ])),
      const SizedBox(height: 18),
      _Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(context, Icons.help_outline,
            es ? '¿Necesitas ayuda?' : 'Need help?'),
        const SizedBox(height: 12),
        Text(
            es
                ? 'Crea un negocio, organiza tu espacio y encuentra tus herramientas de trabajo.'
                : 'Create a business, organize your space and find your everyday tools.',
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 18),
        OutlinedButton.icon(
            onPressed: () => showHomeQuickGuide(context),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text(es ? 'Ver guía rápida' : 'Quick guide')),
      ])),
    ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(children: [main, const SizedBox(height: 18), sidebar]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 7, child: main),
          const SizedBox(width: 18),
          Expanded(flex: 3, child: sidebar),
        ]);
      }),
    );
  }

  Widget _title(BuildContext context, IconData icon, String text) =>
      Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800))),
      ]);
}

class _Surface extends StatelessWidget {
  const _Surface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.primary.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
                color: cs.primary.withValues(alpha: .04),
                blurRadius: 18,
                offset: const Offset(0, 5))
          ],
        ),
        child: child);
  }
}
