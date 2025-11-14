import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/c-frontend/utils/app_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';

class LocationInputWidget extends StatelessWidget {
  final TextEditingController locationController;

  /// If true, show the field's own label; if false, rely on the outer section title.
  final bool showFieldLabel;

  /// Overrides the hint; if null we use l.locationHint.
  final String? hintText;

  const LocationInputWidget({
    super.key,
    required this.locationController,
    this.showFieldLabel = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return TypeAheadField<String>(
      controller: locationController,
      suggestionsCallback: (pattern) => AppUtils.getAddressSuggestions(pattern),
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            // Avoid duplicate title if the card already shows one:
            labelText: showFieldLabel ? l.location : null,
            labelStyle: typo.bodySmall,
            // Ensure a visible hint (fallback to l10n):
            hintText: hintText ?? (l.location),
            hintStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            isDense: true,
            border: InputBorder.none, // SectionCard provides the chrome
            contentPadding: EdgeInsets.zero,
          ),
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          dense: true,
          title: Text(suggestion, style: typo.bodyMedium),
        );
      },
      onSelected: (suggestion) => locationController.text = suggestion,
      hideOnLoading: true,
      hideOnEmpty: false,
      hideOnError: false,
    );
  }
}
