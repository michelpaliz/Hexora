import 'package:hexora/presentation/shared/widgets/navigation_group.dart';

/// Compatibility adapter for existing module callers.
class GroupInvoicesNavSection extends NavigationGroup {
  const GroupInvoicesNavSection(
      {super.key,
      required super.title,
      required super.icon,
      required super.expanded,
      required super.onToggle,
      required super.child});
}
