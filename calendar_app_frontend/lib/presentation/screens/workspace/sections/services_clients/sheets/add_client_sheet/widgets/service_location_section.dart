import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../add_client_controller.dart';
import 'client_form_fields.dart';
import 'input_border.dart';

/// Content of the client editor's "Ubicación" tab.
///
/// One content-sized surface split into three compact sections:
///   1. Dirección del servicio — descriptive address + "Ubicación actual".
///   2. Coordenadas — latitude/longitude, with an explicit validity status so a
///      valid street address is never mistaken for usable geofence data.
///   3. Geocerca — radius + enable switch, collapsed by default unless the
///      geofence is already enabled.
///
/// The client's own "Activo" status lives in the General tab, not here.
class ServiceLocationSection extends StatefulWidget {
  const ServiceLocationSection({
    super.key,
    required this.controller,
    required this.locating,
    required this.onUseCurrentLocation,
    required this.onChanged,
    this.enabled = true,
  });

  final AddClientController controller;
  final bool locating;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onChanged;

  /// False while creating a client: the location is stored against an
  /// existing client id, so it can only be configured after the first save.
  final bool enabled;

  @override
  State<ServiceLocationSection> createState() => _ServiceLocationSectionState();
}

class _ServiceLocationSectionState extends State<ServiceLocationSection> {
  late bool _geofenceExpanded = widget.controller.serviceLocationEnabled;

  AddClientController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    final latitude = double.tryParse(c.serviceLatitude.text.trim());
    final longitude = double.tryParse(c.serviceLongitude.text.trim());
    final radius = double.tryParse(c.serviceRadius.text.trim());
    final hasValidCoordinates = latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
    final hasValidRadius = radius != null && radius >= 10 && radius <= 1000;
    final hasValidLocation = hasValidCoordinates && hasValidRadius;
    final geofenceActive = c.serviceLocationEnabled && hasValidLocation;
    final hasAnyCoordinate = c.serviceLatitude.text.trim().isNotEmpty ||
        c.serviceLongitude.text.trim().isNotEmpty;

    final address = c.serviceLocationLabel.text.trim();
    final summary = address.isNotEmpty
        ? address
        : hasValidCoordinates
            ? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
            : (es ? 'Sin ubicación configurada' : 'No location configured');

    if (!widget.enabled) {
      return _Header(
        title: es ? 'Ubicación del servicio' : 'Service location',
        subtitle: es
            ? 'Guarda el cliente para configurar su ubicación y geocerca.'
            : 'Save the client first to set up its location and geofence.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Header: title, summary and the occasional "current location"
        // action, kept secondary and compact. ----
        LayoutBuilder(builder: (context, box) {
          final iconOnly = box.maxWidth < 440;
          final tooltip = es
              ? 'Usar la ubicación actual del dispositivo'
              : "Use this device's current location";
          return _Header(
            title: es ? 'Ubicación del servicio' : 'Service location',
            subtitle: summary,
            trailing: iconOnly
                ? HexoraButton.iconOnly(
                    icon: LucideIcons.locateFixed,
                    tooltip: tooltip,
                    onPressed:
                        widget.locating ? null : widget.onUseCurrentLocation,
                    loading: widget.locating,
                    variant: HexoraButtonVariant.secondary,
                    size: HexoraButtonSize.compact,
                  )
                : HexoraButton(
                    icon: LucideIcons.locateFixed,
                    label: es ? 'Ubicación actual' : 'Current location',
                    tooltip: tooltip,
                    onPressed:
                        widget.locating ? null : widget.onUseCurrentLocation,
                    loading: widget.locating,
                    variant: HexoraButtonVariant.secondary,
                    size: HexoraButtonSize.compact,
                  ),
          );
        }),
        const SizedBox(height: 14),

        // ---- 1. Dirección del servicio ----
        _SectionLabel(
          icon: LucideIcons.mapPin,
          title: es ? 'Dirección del servicio' : 'Service address',
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c.serviceLocationLabel,
          onChanged: (_) => widget.onChanged(),
          textInputAction: TextInputAction.next,
          decoration: buildInputDecoration(
            context,
            label: es ? 'Dirección o referencia' : 'Address or reference',
            hintText: es
                ? 'Carrer del Roure 23, Dénia · Entrada principal'
                : '23 Main St · Main entrance',
            prefixIcon: const Icon(Icons.place_outlined),
            isFilled: address.isNotEmpty,
          ),
        ),
        const _SectionDivider(),

        // ---- 2. Coordenadas ----
        _SectionLabel(
          icon: LucideIcons.crosshair,
          title: es ? 'Coordenadas' : 'Coordinates',
          trailing: _StatusPill(
            label: hasValidCoordinates
                ? (es ? 'Válidas' : 'Valid')
                : hasAnyCoordinate
                    ? (es ? 'No válidas' : 'Invalid')
                    : (es ? 'Sin coordenadas' : 'Not set'),
            color: hasValidCoordinates
                ? const Color(0xFF17B26A)
                : hasAnyCoordinate
                    ? cs.error
                    : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ClientFormFields(
          first: _CoordinateField(
            controller: c.serviceLatitude,
            label: es ? 'Latitud' : 'Latitude',
            hint: '38.840100',
            onChanged: widget.onChanged,
          ),
          second: _CoordinateField(
            controller: c.serviceLongitude,
            label: es ? 'Longitud' : 'Longitude',
            hint: '0.105700',
            onChanged: widget.onChanged,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          es
              ? 'La dirección es descriptiva; la geocerca solo usa estas coordenadas.'
              : 'The address is descriptive; the geofence only uses these coordinates.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const _SectionDivider(),

        // ---- 3. Geocerca (collapsible) ----
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _geofenceExpanded = !_geofenceExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: _SectionLabel(
                    icon: LucideIcons.radar,
                    title: es ? 'Geocerca' : 'Geofence',
                    subtitle: es
                        ? 'Configura un radio para esta ubicación.'
                        : 'Set a radius for this location.',
                  ),
                ),
                _StatusPill(
                  label: geofenceActive
                      ? (es ? 'Activa' : 'Active')
                      : (es ? 'Inactiva' : 'Inactive'),
                  color: geofenceActive ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _geofenceExpanded ? .5 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  child: Icon(LucideIcons.chevronDown,
                      size: 18, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_geofenceExpanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClientFormFields(
                        first: TextFormField(
                          controller: c.serviceRadius,
                          onChanged: (_) => widget.onChanged(),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: buildInputDecoration(
                            context,
                            label: es ? 'Radio de geocerca' : 'Geofence radius',
                            hintText: '75',
                            prefixIcon: const Icon(Icons.radar_rounded),
                            isFilled: c.serviceRadius.text.trim().isNotEmpty,
                          ).copyWith(
                            suffixText: 'm',
                            helperText: hasValidRadius || radius == null
                                ? null
                                : (es ? 'Entre 10 y 1.000 m' : '10–1,000 m'),
                          ),
                        ),
                        second: const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 2),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        // Invalid data must never auto-enable the geofence:
                        // the switch stays disabled until coordinates and
                        // radius are valid, unless the user is turning an
                        // already-enabled geofence off.
                        value: geofenceActive,
                        onChanged: hasValidLocation || c.serviceLocationEnabled
                            ? (value) {
                                if (value && !hasValidLocation) return;
                                c.serviceLocationEnabled = value;
                                widget.onChanged();
                              }
                            : null,
                        title: Text(
                          es ? 'Activar geocerca' : 'Enable geofence',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: hasValidLocation
                            ? null
                            : Text(
                                es
                                    ? 'Necesita coordenadas y un radio válidos.'
                                    : 'Needs valid coordinates and radius.',
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 26,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: .45,
            ),
      );
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
