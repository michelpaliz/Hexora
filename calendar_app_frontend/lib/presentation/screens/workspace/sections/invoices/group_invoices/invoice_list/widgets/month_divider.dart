part of '../../widgets/group_invoices_invoices_view.dart';

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;
  @override
  Widget build(BuildContext context) =>
      CompactDocumentMonthHeading(label: label);
}
