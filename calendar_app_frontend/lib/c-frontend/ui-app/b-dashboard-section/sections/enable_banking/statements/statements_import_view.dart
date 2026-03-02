import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_tab.dart';
import '../widgets/folder_section_card.dart';

class StatementsImportView extends StatelessWidget {
  const StatementsImportView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: FolderSectionCard(
        label: l.statementsImportTabTitle,
        leftTabOffset: 0,
        child: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: StatementsTab(),
        ),
      ),
    );
  }
}
