import 'package:flutter/material.dart';

class LocationInputWidget extends StatelessWidget {
  final TextEditingController locationController;

  const LocationInputWidget({
    Key? key,
    required this.locationController,
  }) : super(key: key);

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
