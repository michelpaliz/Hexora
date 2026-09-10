// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'azure_maps_document.dart';
import 'azure_maps_types.dart';

class AzureMapsView extends StatefulWidget {
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
  State<AzureMapsView> createState() => _AzureMapsViewState();
}

class _AzureMapsViewState extends State<AzureMapsView> {
  static int _nextId = 0;

  late final String _instanceId;
  late final String _viewType;
  late final html.IFrameElement _frame;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final id = _nextId++;
    _instanceId = 'hexora-azure-map-$id';
    _viewType = 'hexora-azure-map-view-$id';
    _frame = html.IFrameElement()
      ..title = 'Azure Maps'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'geolocation'
      ..srcdoc = buildAzureMapsDocument(
        instanceId: _instanceId,
        clientId: widget.clientId,
        accessToken: widget.accessToken,
        pins: widget.pins,
        selectedPinId: widget.selectedPinId,
        selection: widget.selection,
        userLocation: widget.userLocation,
      );
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _frame,
    );
    _messageSubscription = html.window.onMessage.listen(_onMessage);
  }

  @override
  void didUpdateWidget(covariant AzureMapsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (oldWidget.accessToken != widget.accessToken) {
      _post(<String, dynamic>{
        'action': 'token',
        'accessToken': widget.accessToken,
      });
    }
    if (!_samePins(oldWidget.pins, widget.pins)) {
      _post(<String, dynamic>{
        'action': 'pins',
        'pins': widget.pins.map((pin) => pin.toJson()).toList(growable: false),
      });
    }
    if (oldWidget.selectedPinId != widget.selectedPinId) {
      _post(<String, dynamic>{
        'action': 'selected-pin',
        'selectedPinId': widget.selectedPinId,
      });
    }
    if (!_sameSelection(oldWidget.selection, widget.selection)) {
      _post(<String, dynamic>{
        'action': 'selection',
        'selection': widget.selection?.toJson(),
      });
    }
    if (!_sameUserLocation(oldWidget.userLocation, widget.userLocation)) {
      _post(<String, dynamic>{
        'action': 'user-location',
        'userLocation': widget.userLocation?.toJson(),
      });
    }
    if (widget.cameraTarget != null &&
        oldWidget.cameraTarget?.requestId != widget.cameraTarget!.requestId) {
      _postCamera(widget.cameraTarget!);
    }
  }

  void _onMessage(html.MessageEvent event) {
    if (event.data is! String) return;
    try {
      final decoded = jsonDecode(event.data as String);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);
      if (data['instanceId'] != _instanceId) return;
      switch (data['type']) {
        case 'hexora-map-ready':
          _ready = true;
          _syncState();
          widget.onReady?.call();
          if (widget.cameraTarget != null) _postCamera(widget.cameraTarget!);
          break;
        case 'hexora-map-pin':
          final id = (data['id'] ?? '').toString();
          if (id.isNotEmpty) widget.onPinTapped(id);
          break;
        case 'hexora-map-selection':
          final latitude = _number(data['latitude']);
          final longitude = _number(data['longitude']);
          if (latitude == null || longitude == null) return;
          widget.onSelectionChanged(
            AzureMapSelection(
              latitude: latitude,
              longitude: longitude,
              radiusMeters: widget.selection?.radiusMeters ?? 75,
            ),
          );
          break;
        case 'hexora-map-error':
          widget.onError?.call(
            (data['message'] ?? 'No se pudo cargar Azure Maps.').toString(),
          );
          break;
      }
    } catch (_) {}
  }

  void _postCamera(AzureMapCameraTarget target) {
    _post(<String, dynamic>{
      'action': 'camera',
      'latitude': target.latitude,
      'longitude': target.longitude,
      'zoom': target.zoom,
    });
  }

  void _syncState() {
    _post(<String, dynamic>{
      'action': 'token',
      'accessToken': widget.accessToken,
    });
    _post(<String, dynamic>{
      'action': 'user-location',
      'userLocation': widget.userLocation?.toJson(),
    });
    _post(<String, dynamic>{
      'action': 'pins',
      'pins': widget.pins.map((pin) => pin.toJson()).toList(growable: false),
    });
    _post(<String, dynamic>{
      'action': 'selected-pin',
      'selectedPinId': widget.selectedPinId,
    });
    _post(<String, dynamic>{
      'action': 'selection',
      'selection': widget.selection?.toJson(),
    });
  }

  void _post(Map<String, dynamic> message) {
    _frame.contentWindow?.postMessage(
      jsonEncode(<String, dynamic>{'instanceId': _instanceId, ...message}),
      '*',
    );
  }

  bool _samePins(List<AzureMapPin> a, List<AzureMapPin> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].latitude != b[i].latitude ||
          a[i].longitude != b[i].longitude ||
          a[i].radiusMeters != b[i].radiusMeters) {
        return false;
      }
    }
    return true;
  }

  bool _sameSelection(AzureMapSelection? a, AzureMapSelection? b) =>
      a?.latitude == b?.latitude &&
      a?.longitude == b?.longitude &&
      a?.radiusMeters == b?.radiusMeters;

  bool _sameUserLocation(
    AzureMapUserLocation? a,
    AzureMapUserLocation? b,
  ) =>
      a?.latitude == b?.latitude &&
      a?.longitude == b?.longitude &&
      a?.accuracyMeters == b?.accuracyMeters;

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _frame.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
