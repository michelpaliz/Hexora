import 'package:hexora/presentation/shared/widgets/weather/weather_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/home/widgets/home_section_nav.dart';
import 'package:hexora/presentation/screens/home/widgets/see_all_groups_button.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/motivational_phrase/quotes/quotes_en.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/motivational_phrase/quotes/quotes_es.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/section_header.dart';

class HomeSliverContent extends StatelessWidget {
  final User user;
  final bool isWide;
  final double bottomSafePadding;
  final GlobalKey summaryKey;
  final GlobalKey phraseKey;
  final GlobalKey groupsKey;
  final ScrollController controller;
  final bool showSectionNavBar;
  final List<HomeSectionNavItem>? sectionItems;
  final String? activeSection;
  final ValueChanged<String>? onSectionSelected;

  const HomeSliverContent({
    super.key,
    required this.user,
    required this.isWide,
    required this.bottomSafePadding,
    required this.summaryKey,
    required this.phraseKey,
    required this.groupsKey,
    required this.controller,
    this.showSectionNavBar = false,
    this.sectionItems,
    this.activeSection,
    this.onSectionSelected,
  });

  Future<void> _openCreateGroup(BuildContext context) async {
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 900),
            child: const CreateGroupData(),
          ),
        ),
      );
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.createGroupData);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      controller: controller,
      slivers: [
        if (showSectionNavBar && sectionItems != null)
          SliverToBoxAdapter(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: HomeSectionNav(
                items: sectionItems!,
                selectedId: activeSection ?? '',
                onSelect: onSectionSelected ?? (_) {},
                isDark: Theme.of(context).brightness == Brightness.dark,
                axis: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              ),
            ),
          ),
        SliverToBoxAdapter(
          key: summaryKey,
          child: _HeroGreeting(user: user, compact: !isWide),
        ),
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeatherSummaryCard(location: user.location),
        )),
        SliverToBoxAdapter(
          key: phraseKey,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _DailyPhraseCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          key: groupsKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: loc.groupSectionTitle,
              markerHeight: isWide ? 30 : 24,
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
              trailing: isWide
                  ? Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openCreateGroup(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(loc.createGroup),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SeeAllGroupsButton(compact: true, outlined: true),
                      ],
                    )
                  : const SeeAllGroupsButton(compact: true, outlined: true),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: 6,
              bottom: 12,
            ),
            child: GroupListSection(
              maxItems: 5,
              fullPage: false,
            ),
          ),
        ),
        SliverToBoxAdapter(
            child: SizedBox(height: isWide ? 24 : bottomSafePadding)),
      ],
    );
  }
}

// ── Desktop-only hero greeting ────────────────────────────────────────────────

class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({required this.user, this.compact = false});

  final bool compact;

  final User user;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final hour = DateTime.now().hour;
    final String greeting;
    final IconData greetingIcon;
    if (hour >= 6 && hour < 12) {
      greeting = isEs ? 'Buenos días' : 'Good morning';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 20) {
      greeting = isEs ? 'Buenas tardes' : 'Good afternoon';
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = isEs ? 'Buenas noches' : 'Good evening';
      greetingIcon = Icons.nightlight_round;
    }

    final displayName = user.name.isNotEmpty ? user.name : user.userName;
    final name = displayName.isEmpty
        ? 'Usuario'
        : displayName[0].toUpperCase() + displayName.substring(1);
    final initial = displayName.isEmpty ? 'U' : displayName[0].toUpperCase();
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final rawDate = DateFormat('EEEE, d MMMM y', localeTag).format(now);
    final dateStr = rawDate.isEmpty
        ? rawDate
        : rawDate[0].toUpperCase() + rawDate.substring(1);

    if (compact) {
      final shortDate = DateFormat.MMMMEEEEd(localeTag).format(now);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer,
                Color.alphaBlend(cs.primary.withValues(alpha: 0.04), cs.surface)
              ],
            ),
            border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(greeting,
                      style: t.bodyMedium.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(name,
                      style: t.titleLarge.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(shortDate,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                ])),
            const SizedBox(width: 12),
            ExcludeSemantics(
                child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.65),
                  shape: BoxShape.circle),
              child: Icon(greetingIcon, color: cs.primary, size: 28),
            )),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — tappable; shows photo dialog or navigates to profile
          GestureDetector(
            onTap: hasPhoto
                ? () => showDialog<void>(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.72),
                      builder: (_) => UserAvatarViewerDialog(user: user),
                    )
                : () => Navigator.pushNamed(context, AppRoutes.profileDetails),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.tertiary],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: t.titleLarge.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(greetingIcon,
                        size: 18, color: cs.primary.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$greeting, $name',
                        style: t.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                          color: cs.onSurface,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    dateStr,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Navigation icons
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: loc.notifications,
            color: cs.onSurfaceVariant,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.showNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.settings,
            color: cs.onSurfaceVariant,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _DailyPhraseCard extends StatelessWidget {
  const _DailyPhraseCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final quotes = isEs ? quotesEs : quotesEn;
    final (quote, author) = quotes[dayKey % quotes.length];
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.format_quote_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '“$quote” — ${author.replaceFirst(RegExp(r'^[\s—–-]+'), '')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
