import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:provider/provider.dart';

class UndoneEventsSegmentedTabBar extends StatelessWidget {
  const UndoneEventsSegmentedTabBar({super.key});

  static double height(BuildContext context) =>
      32 + MediaQuery.textScalerOf(context).scale(36);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<GroupUndoneEventsViewModel>();
    final es = Localizations.localeOf(context).languageCode == 'es';
    Widget tab(String label, int count) => Tab(
          height: height(context) - 20,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$count', style: const TextStyle(fontSize: 12)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14)),
        child: TabBar(
          padding: const EdgeInsets.all(2),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            tab(es ? 'Pendientes' : 'Pending', vm.pendingEvents.length),
            tab(es ? 'Completados' : 'Completed', vm.completedEvents.length)
          ],
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          indicator: BoxDecoration(
              color: cs.primary, borderRadius: BorderRadius.circular(12)),
          splashBorderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
