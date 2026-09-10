import 'package:flutter/material.dart';

import '../add_client_controller.dart';

class ServiceLocationSection extends StatelessWidget {
  const ServiceLocationSection({
    super.key,
    required this.controller,
    required this.locating,
    required this.onUseCurrentLocation,
    required this.onChanged,
  });

  final AddClientController controller;
  final bool locating;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: ExpansionTile(
        initiallyExpanded: controller.serviceLocationExpanded,
        onExpansionChanged: (value) {
          controller.serviceLocationExpanded = value;
          onChanged();
        },
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.location_on_outlined, color: cs.primary),
        title: Text(
          isSpanish ? 'Ubicación del servicio' : 'Service location',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          isSpanish
              ? 'Punto usado para detectar llegadas y salidas.'
              : 'Point used to detect arrivals and departures.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: locating ? null : onUseCurrentLocation,
              icon: locating
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                isSpanish ? 'Usar mi ubicación actual' : 'Use current location',
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final latitude = _CoordinateField(
                controller: controller.serviceLatitude,
                label: isSpanish ? 'Latitud' : 'Latitude',
                hint: '38.840100',
                onChanged: onChanged,
              );
              final longitude = _CoordinateField(
                controller: controller.serviceLongitude,
                label: isSpanish ? 'Longitud' : 'Longitude',
                hint: '0.105700',
                onChanged: onChanged,
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    latitude,
                    const SizedBox(height: 10),
                    longitude,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: latitude),
                  const SizedBox(width: 10),
                  Expanded(child: longitude),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.serviceLocationLabel,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Etiqueta' : 'Label',
                    hintText: isSpanish ? 'Entrada principal' : 'Main entrance',
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: controller.serviceRadius,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Radio' : 'Radius',
                    suffixText: 'm',
                    prefixIcon: const Icon(Icons.radar_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: controller.serviceLocationEnabled,
            onChanged: (value) {
              controller.serviceLocationEnabled = value;
              onChanged();
            },
            title: Text(
              isSpanish ? 'Geocerca activa' : 'Geofence enabled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              isSpanish
                  ? 'Los trabajadores podrán registrar visitas en este punto.'
                  : 'Workers can record visits at this location.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends StatelessWidget {
  const _CoordinateField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.pin_drop_outlined),
      ),
    );
  }
}
