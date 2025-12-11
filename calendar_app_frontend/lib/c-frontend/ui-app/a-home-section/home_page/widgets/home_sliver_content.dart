import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/widgets/home_section_nav.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/widgets/see_all_groups_button.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/motivational_phrase/motivation_banner.dart';
import 'package:hexora/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 20 : 0,
              vertical: isWide ? 8 : 0,
            ),
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
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          key: phraseKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 0),
            child: SectionHeader(title: loc.motivationSectionTitle),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MotivationBanner(dailyRotate: true),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          key: groupsKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(title: loc.groupSectionTitle),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Spacer(),
                SeeAllGroupsButton(),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: 12,
              bottom: isWide ? 24 : bottomSafePadding,
            ),
            child: GroupListSection(
              maxItems: 5,
              fullPage: false,
            ),
          ),
        ),
      ],
    );
  }
}
