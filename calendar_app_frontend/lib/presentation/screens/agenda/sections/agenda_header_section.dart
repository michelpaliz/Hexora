// lib/presentation/b-calendar-section/screens/agenda/widgets/agenda_header_section.dart
import 'package:hexora/models/group_model/agenda/agenda_model.dart';
import 'package:hexora/presentation/screens/agenda/widgets/agenda_header.dart';
import 'package:flutter/material.dart';

class AgendaHeaderSection extends StatelessWidget {
  final List<AgendaItem> items; // pass FILTERED list here
  final int daysRange;
  final VoidCallback onToggleDays;
  final VoidCallback onRefresh;

  const AgendaHeaderSection({
    super.key,
    required this.items,
    required this.daysRange,
    required this.onToggleDays,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: AgendaHeader(
          items: items, // <- filtered by caller
          daysRange: daysRange,
          onExpandRange: onToggleDays,
          onRefresh: onRefresh,
          showGreeting: false,
        ),
      ),
    );
  }
}
