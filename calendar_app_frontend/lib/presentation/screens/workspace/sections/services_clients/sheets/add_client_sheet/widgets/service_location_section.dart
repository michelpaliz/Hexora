import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

import '../add_client_controller.dart';
import 'client_form_fields.dart';
import 'input_border.dart';

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
    final latitude = double.tryParse(controller.serviceLatitude.text.trim());
    final longitude = double.tryParse(controller.serviceLongitude.text.trim());
    final radius = double.tryParse(controller.serviceRadius.text.trim());
    final hasValidLocation = latitude != null &&
        longitude != null &&
        radius != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0) &&
        radius >= 10 &&
        radius <= 1000;
    final locationLabel = controller.serviceLocationLabel.text.trim();
    final coordinateLabel = latitude != null && longitude != null
        ? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
        : (isSpanish ? 'Sin ubicación configurada' : 'No location configured');
    final summary = locationLabel.isNotEmpty ? locationLabel : coordinateLabel;
    final statusLabel = controller.serviceLocationEnabled && hasValidLocation
        ? (isSpanish ? 'Geocerca activa' : 'Geofence active')
        : (isSpanish ? 'Geocerca inactiva' : 'Geofence inactive');

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        expansionAnimationStyle: HexoraMotion.expansionStyle(context),
        initiallyExpanded: controller.serviceLocationExpanded,
        onExpansionChanged: (value) {
          controller.serviceLocationExpanded = value;
          onChanged();
        },
        shape: const Border(),
        collapsedShape: const Border(),
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: Icon(Icons.location_on_outlined, size: 19, color: cs.primary),
        title: Text(
          isSpanish ? 'Ubicación del servicio' : 'Service location',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text.rich(
          TextSpan(children: [
            TextSpan(text: summary),
            const TextSpan(text: '  ·  '),
            TextSpan(
              text: statusLabel,
              style: TextStyle(
                color: controller.serviceLocationEnabled && hasValidLocation
                    ? cs.primary
                    : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: HexoraButton(
              icon: Icons.my_location_rounded,
              label: isSpanish
                  ? 'Usar mi ubicación actual'
                  : 'Use current location',
              onPressed: locating ? null : onUseCurrentLocation,
              loading: locating,
              variant: HexoraButtonVariant.tonal,
              size: HexoraButtonSize.compact,
            ),
          ),
          const SizedBox(height: 8),
          ClientFormFields(
            first: _CoordinateField(
              controller: controller.serviceLatitude,
              label: isSpanish ? 'Latitud' : 'Latitude',
              hint: '38.840100',
              onChanged: onChanged,
            ),
            second: _CoordinateField(
              controller: controller.serviceLongitude,
              label: isSpanish ? 'Longitud' : 'Longitude',
              hint: '0.105700',
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 8),
          ClientFormFields(
            first: TextFormField(
              controller: controller.serviceLocationLabel,
              onChanged: (_) => onChanged(),
              decoration: buildInputDecoration(
                context,
                label: isSpanish ? 'Etiqueta' : 'Label',
                hintText: isSpanish ? 'Entrada principal' : 'Main entrance',
                prefixIcon: const Icon(Icons.label_outline_rounded),
                isFilled:
                    controller.serviceLocationLabel.text.trim().isNotEmpty,
              ),
            ),
            second: TextFormField(
              controller: controller.serviceRadius,
              onChanged: (_) => onChanged(),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: buildInputDecoration(
                context,
                label: isSpanish ? 'Radio' : 'Radius',
                prefixIcon: const Icon(Icons.radar_rounded),
                isFilled: controller.serviceRadius.text.trim().isNotEmpty,
              ).copyWith(suffixText: 'm'),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            // Invalid coordinates must never auto-enable the geofence; the
            // switch itself is disabled until the user supplies valid data,
            // or until they explicitly toggle an already-enabled geofence off.
            value: controller.serviceLocationEnabled && hasValidLocation,
            onChanged: hasValidLocation || controller.serviceLocationEnabled
                ? (value) {
                    if (value && !hasValidLocation) return;
                    controller.serviceLocationEnabled = value;
                    onChanged();
                  }
                : null,
            title: Text(
              isSpanish ? 'Geocerca activa' : 'Geofence enabled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            // Keep the subtitle only when it adds information the label
            // doesn't convey — i.e. explaining why the switch is disabled.
            subtitle: hasValidLocation
                ? null
                : Text(
                    isSpanish
                        ? 'Configura coordenadas y radio válidos para activarla.'
                        : 'Configure valid coordinates and radius to enable it.',
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
      decoration: buildInputDecoration(
        context,
        label: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.pin_drop_outlined),
        isFilled: controller.text.trim().isNotEmpty,
      ),
    );
  }
}
