import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/shared/currency_options.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerRoleCard extends StatelessWidget {
  const WorkerRoleCard({
    super.key,
    required this.l,
    required this.t,
    required this.roleCtrl,
    required this.rateCtrl,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  final AppLocalizations l;
  final AppTypography t;
  final TextEditingController roleCtrl;
  final TextEditingController rateCtrl;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.roleLabel,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: roleCtrl,
              decoration: InputDecoration(
                hintText: l.roleHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.hourlyRateLabel,
                      hintText: l.hourlyRateHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: t.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      labelText: l.currencyLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: workerCurrencyOptions
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onCurrencyChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
