import 'package:flutter/material.dart';

import 'azure_maps_types.dart';

class AzureMapsView extends StatelessWidget {
  const AzureMapsView({
    super.key,
    required this.clientId,
    required this.accessToken,
    required this.pins,
    required this.selectedPinId,
    required this.selection,
    required this.userLocation,
    required this.cameraTarget,
    required this.onSelectionChanged,
    required this.onPinTapped,
    this.onReady,
    this.onError,
  });

  final String clientId;
  final String accessToken;
  final List<AzureMapPin> pins;
  final String? selectedPinId;
  final AzureMapSelection? selection;
  final AzureMapUserLocation? userLocation;
  final AzureMapCameraTarget? cameraTarget;
  final ValueChanged<AzureMapSelection> onSelectionChanged;
  final ValueChanged<String> onPinTapped;
  final VoidCallback? onReady;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'El mapa interactivo está disponible en la versión web. '
            'La selección guardada sigue disponible desde un navegador.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
