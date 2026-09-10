import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _controller;
  bool _ready = false;

  bool get _isSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _instanceId = 'hexora-azure-native-map-${_nextId++}';
    if (!_isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady?.call();
      });
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F4F8))
      ..addJavaScriptChannel(
        'HexoraMapChannel',
        onMessageReceived: (message) => _onMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              widget.onError?.call(error.description);
            }
          },
        ),
      )
      ..loadHtmlString(
        buildAzureMapsDocument(
          instanceId: _instanceId,
          clientId: widget.clientId,
          accessToken: widget.accessToken,
          pins: widget.pins,
          selectedPinId: widget.selectedPinId,
          selection: widget.selection,
          userLocation: widget.userLocation,
        ),
      );
    _controller = controller;
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

  void _onMessage(String message) {
    try {
      final decoded = jsonDecode(message);
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
    final payload = jsonEncode(<String, dynamic>{
      'instanceId': _instanceId,
      ...message,
    });
    _controller?.runJavaScript(
      'window.postMessage(${jsonEncode(payload)}, "*");',
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
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) return WebViewWidget(controller: controller);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Azure Maps no está disponible en esta plataforma.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
