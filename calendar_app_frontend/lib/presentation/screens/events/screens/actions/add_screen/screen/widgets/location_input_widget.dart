import 'package:flutter/material.dart';

class LocationInputWidget extends StatelessWidget {
  final TextEditingController locationController;

  const LocationInputWidget({
    super.key,
    required this.locationController,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: locationController,
      decoration: const InputDecoration(
        labelText: 'Location',
        border: OutlineInputBorder(),
        hintText: 'Enter event location',
      ),
    );
  }
}
