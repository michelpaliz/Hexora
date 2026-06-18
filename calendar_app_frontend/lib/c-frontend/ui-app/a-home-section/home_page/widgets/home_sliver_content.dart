import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/widgets/home_section_nav.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/widgets/see_all_groups_button.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/motivational_phrase/motivation_banner.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/user_profile_popup.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/greeting_card.dart';
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
        // ── Wide: hero greeting + weather & quote side by side ────────
        if (isWide) ...[
          SliverToBoxAdapter(
            key: summaryKey,
            child: _HeroGreeting(user: user),
          ),
          SliverToBoxAdapter(
            key: phraseKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 55,
                      // ClipRect prevents the 1px rounding overflow from showing
                      child: ClipRect(
                        child: GreetingCard(
                          user: user,
                          showGreeting: false,
                          daySummary: mapToDaySummary(
                            weatherCode: 1, // TODO: replace with real weather code
                            precip: 0,
                            tempMax: 26,
                            tempMin: 17,
                          ),
                          tempMax: 26,
                          tempMin: 17,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: const MotivationBanner(
                                  dailyRotate: true,
                                  height: null,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              left: 18,
                              child: _QuoteLabel(
                                isEs: Localizations.localeOf(context)
                                        .languageCode ==
                                    'es',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]
        // ── Narrow: stacked weather then quote ────────────────────────
        else ...[
          SliverToBoxAdapter(
            key: summaryKey,
            child: GreetingCard(
              user: user,
              daySummary: mapToDaySummary(
                weatherCode: 1, // TODO: replace with real weather code
                precip: 0,
                tempMax: 26,
                tempMin: 17,
              ),
              tempMax: 26,
              tempMin: 17,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            key: phraseKey,
            child: SectionHeader(
              title: loc.motivationSectionTitle,
              markerHeight: 24,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 2)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: MotivationBanner(dailyRotate: true, height: 180),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
                  : null,
            ),
          ),
        ),
        if (!isWide)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Spacer(),
                  SeeAllGroupsButton(),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: 6,
              bottom: isWide ? 24 : bottomSafePadding,
            ),
            child: const GroupListSection(
              maxItems: 5,
              fullPage: false,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Desktop-only hero greeting ────────────────────────────────────────────────

class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({required this.user});

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
    final initial =
        displayName.isEmpty ? 'U' : displayName[0].toUpperCase();
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final rawDate = DateFormat('EEEE, d MMMM y', localeTag).format(now);
    final dateStr = rawDate.isEmpty
        ? rawDate
        : rawDate[0].toUpperCase() + rawDate.substring(1);

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
                : () =>
                    Navigator.pushNamed(context, AppRoutes.profileDetails),
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
                        size: 18,
                        color: cs.primary.withValues(alpha: 0.85)),
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
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

// ── "Quote of the day" frosted label overlaid on the motivation banner ─────────

class _QuoteLabel extends StatelessWidget {
  const _QuoteLabel({required this.isEs});

  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_quote_rounded,
              size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isEs ? 'Frase del día' : 'Quote of the day',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
