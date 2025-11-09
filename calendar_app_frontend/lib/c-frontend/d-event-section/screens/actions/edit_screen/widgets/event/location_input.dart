import 'package:hexora/c-frontend/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class LocationInput extends StatelessWidget {
  final TextEditingController controller;

  const LocationInput({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.location,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        try {
          return await AppUtils.getAddressSuggestions(pattern);
        } catch (e) {
          debugPrint('Error getting suggestions: $e');
          return [];
        }
      },
      itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
      onSelected: (suggestion) => controller.text = suggestion,
      debounceDuration: const Duration(milliseconds: 300),
      loadingBuilder: (context) => Center(child: CircularProgressIndicator()),
      // noItemsFoundBuilder: (context) => Padding(
      //   padding: EdgeInsets.all(8.0),
      //   child: Text('No results found'), // Fallback text
      // ),
    );
  }
}
