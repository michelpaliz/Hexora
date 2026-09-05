import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/i_time_tracking_api_client.dart';
import 'package:hexora/b-backend/maps/maps_api.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:provider/provider.dart';

import 'widgets/azure_maps_view.dart';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({
    super.key,
    required this.group,
    this.embedded = false,
    this.canEdit = true,
    this.mapsApi,
    this.clientsApi,
  });

  final Group group;
  final bool embedded;
  final bool canEdit;
  final MapsApi? mapsApi;
  final ClientsApi? clientsApi;

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  late final MapsApi _mapsApi;
  late final ClientsApi _clientsApi;
  final _clientFilter = TextEditingController();
  final _addressSearch = TextEditingController();
  final _labelController = TextEditingController();

  AzureMapsToken? _mapToken;
  List<GroupClient> _clients = const <GroupClient>[];
  List<ClientServiceLocation> _locations = const <ClientServiceLocation>[];
  GroupClient? _selectedClient;
  AzureMapSelection? _selection;
  AzureMapUserLocation? _userLocation;
  AzureMapCameraTarget? _cameraTarget;
  String? _resolvedAddress;
  String? _error;
  String? _mapError;
  bool _loading = true;
  bool _mapReady = false;
  bool _editing = false;
  bool _saving = false;
  bool _searching = false;
  bool _locating = false;
  bool _autoLocationRequested = false;
  bool _enabled = true;
  double _radius = 75;
  int _cameraRequestId = 0;
  int _mapGeneration = 0;
  Timer? _tokenTimer;
  Timer? _reverseGeocodeTimer;
  Timer? _mapReadyTimer;

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  void initState() {
    super.initState();
    _mapsApi = widget.mapsApi ?? MapsApi();
    _clientsApi = widget.clientsApi ?? ClientsApi();
    _load();
  }

  @override
  void dispose() {
    _tokenTimer?.cancel();
    _reverseGeocodeTimer?.cancel();
    _mapReadyTimer?.cancel();
    _clientFilter.dispose();
    _addressSearch.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _mapError = null;
      _mapReady = false;
    });
    try {
      final userDomain = context.read<UserDomain>();
      final timeTrackingApi = context.read<ITimeTrackingApiClient>();
      final authToken = await userDomain.getAuthToken();
      final clientsFuture = widget.canEdit
          ? _clientsApi
              .list(groupId: widget.group.id, active: true)
              .catchError((_) => <GroupClient>[])
          : Future<List<GroupClient>>.value(const <GroupClient>[]);
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _mapsApi.getToken(forceRefresh: true),
        clientsFuture,
        timeTrackingApi.getClientLocations(widget.group.id, authToken),
      ]);
      if (!mounted) return;
      final mapToken = results[0] as AzureMapsToken;
      final clients = results[1] as List<GroupClient>;
      final locations = results[2] as List<ClientServiceLocation>;
      setState(() {
        _mapToken = mapToken;
        _clients = clients;
        _locations = locations;
        _mapGeneration++;
      });
      _scheduleTokenRefresh(mapToken);
      _startMapReadyTimeout();
      if (!_autoLocationRequested) {
        _autoLocationRequested = true;
        unawaited(_loadUserLocation(showErrors: false));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFromError(error);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startMapReadyTimeout() {
    _mapReadyTimer?.cancel();
    _mapReadyTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _mapReady) return;
      setState(() {
        _mapError = _isSpanish
            ? 'Azure Maps está tardando demasiado en responder. Comprueba la conexión e inténtalo de nuevo.'
            : 'Azure Maps is taking too long to respond. Check the connection and try again.';
      });
    });
  }

  void _handleMapReady() {
    _mapReadyTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _mapReady = true;
      _mapError = null;
    });
  }

  void _handleMapError(String message) {
    if (_mapReady) {
      _showMessage(
        message.trim().isEmpty
            ? (_isSpanish
                ? 'No se pudo cargar una parte del mapa.'
                : 'Part of the map could not be loaded.')
            : message.trim(),
      );
      return;
    }
    _mapReadyTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _mapReady = false;
      _mapError = message.trim().isEmpty
          ? (_isSpanish
              ? 'No se pudo cargar Azure Maps.'
              : 'Azure Maps could not be loaded.')
          : message.trim();
    });
  }

  void _scheduleTokenRefresh(AzureMapsToken token) {
    _tokenTimer?.cancel();
    var delay = token.expiresAt.difference(DateTime.now().toUtc()) -
        const Duration(minutes: 2);
    if (delay < const Duration(seconds: 30)) {
      delay = const Duration(seconds: 30);
    }
    _tokenTimer = Timer(delay, _refreshMapToken);
  }

  Future<void> _refreshMapToken() async {
    try {
      final token = await _mapsApi.getToken(forceRefresh: true);
      if (!mounted) return;
      setState(() => _mapToken = token);
      _scheduleTokenRefresh(token);
    } catch (_) {
      if (!mounted) return;
      _tokenTimer = Timer(const Duration(seconds: 30), _refreshMapToken);
    }
  }

  List<AzureMapPin> get _pins => _locations
      .map(
        (location) => AzureMapPin(
          id: location.clientId,
          title: _clientName(location.clientId, location.clientName),
          latitude: location.latitude,
          longitude: location.longitude,
          radiusMeters: location.radiusMeters,
        ),
      )
      .toList(growable: false);

  List<GroupClient> get _filteredClients {
    final query = _clientFilter.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients
        .where((client) => client.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  ClientServiceLocation? _locationFor(String clientId) {
    for (final location in _locations) {
      if (location.clientId == clientId) return location;
    }
    return null;
  }

  String _clientName(String clientId, String? fallback) {
    for (final client in _clients) {
      if (client.id == clientId) return client.name;
    }
    return fallback?.trim().isNotEmpty == true ? fallback!.trim() : 'Cliente';
  }

  void _selectClient(String clientId) {
    GroupClient? client;
    for (final item in _clients) {
      if (item.id == clientId) {
        client = item;
        break;
      }
    }
    final location = _locationFor(clientId);
    if (client == null || location == null) return;
    setState(() {
      _selectedClient = client;
      _editing = false;
      _selection = null;
      _resolvedAddress = location.label;
      _cameraTarget = AzureMapCameraTarget(
        latitude: location.latitude,
        longitude: location.longitude,
        zoom: 17,
        requestId: ++_cameraRequestId,
      );
    });
  }

  Future<void> _chooseClient() async {
    if (!widget.canEdit || _clients.isEmpty) return;
    final selected = await showDialog<GroupClient>(
      context: context,
      builder: (dialogContext) => _ClientPickerDialog(
        clients: _clients,
        configuredClientIds:
            _locations.map((location) => location.clientId).toSet(),
        isSpanish: _isSpanish,
      ),
    );
    if (selected != null && mounted) await _beginEditing(selected);
  }

  Future<void> _beginEditing(GroupClient client) async {
    final location = _locationFor(client.id) ?? client.serviceLocation;
    setState(() {
      _selectedClient = client;
      _editing = true;
      _enabled = location?.isEnabled ?? true;
      _radius = (location?.radiusMeters ?? 75).clamp(10, 1000).toDouble();
      _labelController.text = location?.label ?? '';
      _resolvedAddress = location?.label;
      _selection = location == null
          ? null
          : AzureMapSelection(
              latitude: location.latitude,
              longitude: location.longitude,
              radiusMeters: _radius,
            );
      if (location != null) {
        _cameraTarget = AzureMapCameraTarget(
          latitude: location.latitude,
          longitude: location.longitude,
          zoom: 17,
          requestId: ++_cameraRequestId,
        );
      }
    });
    if (location == null) {
      final address = _billingAddress(client);
      if (address.isNotEmpty) {
        _addressSearch.text = address;
        await _searchAddress(autoSelectFirst: true);
      }
    }
  }

  String _billingAddress(GroupClient client) {
    final billing = client.billing;
    if (billing == null) return '';
    return <String?>[
      billing.addressStreet,
      billing.addressExtra,
      billing.addressPostalCode,
      billing.addressCity,
      billing.addressProvince,
      billing.addressCountry,
    ]
        .where((part) => part?.trim().isNotEmpty == true)
        .map((part) => part!.trim())
        .join(', ');
  }

  void _onSelectionChanged(AzureMapSelection selection) {
    if (!_editing) return;
    setState(() {
      _selection = AzureMapSelection(
        latitude: selection.latitude,
        longitude: selection.longitude,
        radiusMeters: _radius,
      );
    });
    _scheduleReverseGeocode(selection.latitude, selection.longitude);
  }

  void _scheduleReverseGeocode(double latitude, double longitude) {
    _reverseGeocodeTimer?.cancel();
    _reverseGeocodeTimer = Timer(const Duration(milliseconds: 550), () async {
      final address = await _mapsApi.reverseGeocode(latitude, longitude);
      if (!mounted ||
          _selection?.latitude != latitude ||
          _selection?.longitude != longitude) {
        return;
      }
      setState(() => _resolvedAddress = address);
    });
  }

  Future<void> _searchAddress({bool autoSelectFirst = false}) async {
    final query = _addressSearch.text.trim();
    if (!_editing || query.length < 3 || _searching) return;
    setState(() => _searching = true);
    try {
      final results = await _mapsApi.searchAddress(query);
      if (!mounted) return;
      if (results.isEmpty) {
        _showMessage(_isSpanish
            ? 'No encontramos esa dirección.'
            : 'No matching address was found.');
        return;
      }
      AzureMapSearchResult? selected;
      if (autoSelectFirst || results.length == 1) {
        selected = results.first;
      } else {
        selected = await showDialog<AzureMapSearchResult>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_isSpanish ? 'Elegir dirección' : 'Choose address'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) => ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(results[index].address),
                  onTap: () => Navigator.pop(context, results[index]),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_isSpanish ? 'Cancelar' : 'Cancel'),
              ),
            ],
          ),
        );
      }
      if (selected == null || !mounted) return;
      setState(() {
        _resolvedAddress = selected!.address;
        _selection = AzureMapSelection(
          latitude: selected.latitude,
          longitude: selected.longitude,
          radiusMeters: _radius,
        );
        _cameraTarget = AzureMapCameraTarget(
          latitude: selected.latitude,
          longitude: selected.longitude,
          zoom: 17,
          requestId: ++_cameraRequestId,
        );
      });
    } catch (error) {
      if (mounted) _showMessage(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _loadUserLocation({
    required bool showErrors,
    bool selectForClient = false,
  }) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(_isSpanish
            ? 'Activa la ubicación del dispositivo.'
            : 'Enable device location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(_isSpanish
            ? 'No se ha concedido permiso de ubicación.'
            : 'Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final userLocation = AzureMapUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      setState(() {
        _userLocation = userLocation;
        if (selectForClient && _editing) {
          _selection = AzureMapSelection(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusMeters: _radius,
          );
        }
        _cameraTarget = AzureMapCameraTarget(
          latitude: position.latitude,
          longitude: position.longitude,
          zoom: 17,
          requestId: ++_cameraRequestId,
        );
      });
      if (selectForClient && _editing) {
        _scheduleReverseGeocode(position.latitude, position.longitude);
      }
    } catch (error) {
      if (mounted && showErrors) _showMessage(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _useCurrentLocation() => _loadUserLocation(
        showErrors: true,
        selectForClient: true,
      );

  Future<void> _saveLocation() async {
    final client = _selectedClient;
    final selection = _selection;
    if (client == null || selection == null || _saving) {
      if (selection == null) {
        _showMessage(_isSpanish
            ? 'Busca una dirección o coloca el pin en el mapa.'
            : 'Search an address or place the pin on the map.');
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _clientsApi.updateServiceLocation(
        client.id,
        ClientServiceLocation(
          clientId: client.id,
          clientName: client.name,
          latitude: selection.latitude,
          longitude: selection.longitude,
          radiusMeters: _radius,
          label: _labelController.text.trim().isEmpty
              ? _resolvedAddress
              : _labelController.text.trim(),
          isEnabled: _enabled,
        ),
      );
      if (!mounted) return;
      setState(() {
        _locations = <ClientServiceLocation>[
          ..._locations.where((item) => item.clientId != client.id),
          if (saved.isEnabled) saved,
        ];
        _clients = _clients
            .map((item) => item.id == client.id
                ? item.copyWith(serviceLocation: saved)
                : item)
            .toList(growable: false);
        _selectedClient = client.copyWith(serviceLocation: saved);
        _editing = false;
        _selection = null;
        _resolvedAddress = saved.label;
        _cameraTarget = AzureMapCameraTarget(
          latitude: saved.latitude,
          longitude: saved.longitude,
          zoom: 17,
          requestId: ++_cameraRequestId,
        );
      });
      _showMessage(
        _isSpanish ? 'Ubicación guardada correctamente.' : 'Location saved.',
      );
    } catch (error) {
      if (mounted) _showMessage(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _selection = null;
      _resolvedAddress = _selectedClient == null
          ? null
          : _locationFor(_selectedClient!.id)?.label;
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFromError(Object error) => error
      .toString()
      .replaceFirst(RegExp(r'^(Exception|MapsApiException):\s*'), '');

  @override
  Widget build(BuildContext context) {
    final token = _mapToken;
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : token == null
                ? _ErrorState(
                    message: _isSpanish
                        ? 'No hay credenciales disponibles para el mapa.'
                        : 'Map credentials are unavailable.',
                    onRetry: _load,
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildResponsiveBody(token)),
                    ],
                  );

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: content,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isSpanish ? 'Mapa' : 'Map')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.map_outlined, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSpanish ? 'Mapa de clientes' : 'Client map',
                  style: typography.titleLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSpanish
                      ? '${_locations.length} ubicaciones configuradas'
                      : '${_locations.length} configured locations',
                  style: typography.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _isSpanish ? 'Mi ubicación' : 'My location',
            onPressed:
                _locating ? null : () => _loadUserLocation(showErrors: true),
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: _userLocation == null ? null : cs.primary,
                  ),
          ),
          IconButton(
            tooltip: _isSpanish ? 'Actualizar' : 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (widget.canEdit) ...[
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: _chooseClient,
              icon: const Icon(Icons.add_location_alt_outlined, size: 19),
              label:
                  Text(_isSpanish ? 'Ubicar cliente' : 'Set client location'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveBody(AzureMapsToken token) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final map = _buildMap(token);
        final panel = _buildSidePanel();
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: map),
              const SizedBox(width: 12),
              SizedBox(width: 360, child: panel),
            ],
          );
        }
        return Column(
          children: [
            Expanded(flex: 5, child: map),
            const SizedBox(height: 10),
            Expanded(flex: 4, child: panel),
          ],
        );
      },
    );
  }

  Widget _buildMap(AzureMapsToken token) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AzureMapsView(
                key: ValueKey('azure-map-$_mapGeneration'),
                clientId: token.clientId,
                accessToken: token.accessToken,
                pins: _pins,
                selection: _selection,
                userLocation: _userLocation,
                cameraTarget: _cameraTarget,
                onSelectionChanged: _onSelectionChanged,
                onPinTapped: _selectClient,
                onReady: _handleMapReady,
                onError: _handleMapError,
              ),
            ),
            if (!_mapReady && _mapError == null)
              Positioned.fill(
                child: ColoredBox(
                  color: cs.surfaceContainerLow,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_mapError != null)
              Positioned.fill(
                child: ColoredBox(
                  color: cs.surfaceContainerLow,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 46,
                              color: cs.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _mapError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                _isSpanish ? 'Reintentar' : 'Retry',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_editing)
              Positioned(
                left: 12,
                top: 12,
                right: 86,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 10),
                      ],
                    ),
                    child: Text(
                      _isSpanish
                          ? 'Haz clic en el mapa o arrastra el pin.'
                          : 'Click the map or drag the pin.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            if (_userLocation != null && !_editing)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1677FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _isSpanish ? 'Tu ubicación' : 'Your location',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: _editing ? _buildEditor() : _buildClientBrowser(),
    );
  }

  Widget _buildClientBrowser() {
    final selected = _selectedClient;
    final selectedLocation =
        selected == null ? null : _locationFor(selected.id);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: TextField(
            controller: _clientFilter,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _isSpanish ? 'Buscar cliente' : 'Search clients',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _clientFilter.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _clientFilter.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              isDense: true,
            ),
          ),
        ),
        if (selected != null && selectedLocation != null)
          _SelectedClientCard(
            client: selected,
            location: selectedLocation,
            isSpanish: _isSpanish,
            canEdit: widget.canEdit,
            onEdit: () => _beginEditing(selected),
          ),
        const Divider(height: 1),
        Expanded(
          child: _filteredClients.isEmpty
              ? Center(
                  child: Text(
                    _isSpanish ? 'No hay clientes.' : 'No clients found.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _filteredClients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, index) {
                    final client = _filteredClients[index];
                    final location = _locationFor(client.id);
                    return ListTile(
                      selected: _selectedClient?.id == client.id,
                      leading: CircleAvatar(
                        child: Text(
                          client.name.trim().isEmpty
                              ? '?'
                              : client.name.trim()[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        client.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        location == null
                            ? (_isSpanish ? 'Sin ubicación' : 'No location')
                            : location.label ??
                                '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        location == null
                            ? Icons.add_location_alt_outlined
                            : Icons.location_on_rounded,
                        color: location == null ? null : Colors.green.shade600,
                      ),
                      onTap: location == null
                          ? widget.canEdit
                              ? () => _beginEditing(client)
                              : null
                          : () => _selectClient(client.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final cs = Theme.of(context).colorScheme;
    final client = _selectedClient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSpanish ? 'Ubicar cliente' : 'Set client location',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _isSpanish ? 'Cancelar' : 'Cancel',
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressSearch,
            onSubmitted: (_) => _searchAddress(),
            decoration: InputDecoration(
              labelText: _isSpanish ? 'Buscar dirección' : 'Search address',
              hintText: _isSpanish
                  ? 'Calle, numero, ciudad...'
                  : 'Street, number, city...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: _isSpanish ? 'Buscar' : 'Search',
                onPressed: _searching ? null : _searchAddress,
                icon: _searching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(
              _isSpanish ? 'Usar mi ubicación actual' : 'Use my location',
            ),
          ),
          if (_resolvedAddress?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_resolvedAddress!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: _isSpanish ? 'Etiqueta opcional' : 'Optional label',
              hintText: _isSpanish ? 'Entrada principal' : 'Main entrance',
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSpanish ? 'Radio de la geocerca' : 'Geofence radius',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${_radius.round()} m'),
            ],
          ),
          Slider(
            value: _radius,
            min: 10,
            max: 300,
            divisions: 58,
            label: '${_radius.round()} m',
            onChanged: (value) {
              setState(() {
                _radius = value;
                final selection = _selection;
                if (selection != null) {
                  _selection = AzureMapSelection(
                    latitude: selection.latitude,
                    longitude: selection.longitude,
                    radiusMeters: value,
                  );
                }
              });
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: Text(_isSpanish ? 'Geocerca activa' : 'Geofence enabled'),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              _isSpanish ? 'Detalles avanzados' : 'Advanced details',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  _selection == null
                      ? (_isSpanish ? 'Sin coordenadas' : 'No coordinates')
                      : '${_selection!.latitude.toStringAsFixed(6)}, '
                          '${_selection!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving ? null : _saveLocation,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSpanish ? 'Guardar ubicación' : 'Save location'),
          ),
        ],
      ),
    );
  }
}

class _SelectedClientCard extends StatelessWidget {
  const _SelectedClientCard({
    required this.client,
    required this.location,
    required this.isSpanish,
    required this.canEdit,
    required this.onEdit,
  });

  final GroupClient client;
  final ClientServiceLocation location;
  final bool isSpanish;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(location.label ??
              '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Radio: ${location.radiusMeters.round()} m'
                : 'Radius: ${location.radiusMeters.round()} m',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: Text(isSpanish ? 'Editar ubicación' : 'Edit location'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientPickerDialog extends StatefulWidget {
  const _ClientPickerDialog({
    required this.clients,
    required this.configuredClientIds,
    required this.isSpanish,
  });

  final List<GroupClient> clients;
  final Set<String> configuredClientIds;
  final bool isSpanish;

  @override
  State<_ClientPickerDialog> createState() => _ClientPickerDialogState();
}

class _ClientPickerDialogState extends State<_ClientPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.clients
        .where((client) => client.name.toLowerCase().contains(_query))
        .toList(growable: false);
    return AlertDialog(
      title: Text(widget.isSpanish ? 'Seleccionar cliente' : 'Select client'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText:
                    widget.isSpanish ? 'Buscar cliente' : 'Search clients',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (_, index) {
                  final client = visible[index];
                  final configured =
                      widget.configuredClientIds.contains(client.id);
                  return ListTile(
                    leading: Icon(configured
                        ? Icons.location_on_rounded
                        : Icons.add_location_alt_outlined),
                    title: Text(client.name),
                    subtitle: Text(
                      configured
                          ? (widget.isSpanish
                              ? 'Ubicación configurada'
                              : 'Location configured')
                          : (widget.isSpanish
                              ? 'Sin ubicación'
                              : 'No location'),
                    ),
                    onTap: () => Navigator.pop(context, client),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isSpanish ? 'Cancelar' : 'Cancel'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
