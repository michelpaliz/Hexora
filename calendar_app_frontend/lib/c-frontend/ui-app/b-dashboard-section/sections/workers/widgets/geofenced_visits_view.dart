import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/i_time_tracking_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/utils/location/geofenced_visit_tracking_service.dart';

Worker? findCurrentActiveWorker(List<Worker> workers, String? userId) {
  final normalizedUserId = userId?.trim() ?? '';
  if (normalizedUserId.isEmpty) return null;
  for (final worker in workers) {
    if (worker.status == WorkerStatus.active &&
        worker.userId?.trim() == normalizedUserId) {
      return worker;
    }
  }
  return null;
}

List<Worker> companionWorkerChoices(
  List<Worker> workers,
  String responsibleWorkerId,
) {
  final byId = <String, Worker>{};
  for (final worker in workers) {
    if (worker.status != WorkerStatus.active ||
        worker.id.isEmpty ||
        worker.id == responsibleWorkerId) {
      continue;
    }
    byId.putIfAbsent(worker.id, () => worker);
  }
  final result = byId.values.toList(growable: false);
  result.sort((a, b) =>
      workerLabel(a).toLowerCase().compareTo(workerLabel(b).toLowerCase()));
  return result;
}

String workerLabel(Worker worker) =>
    worker.displayName?.trim().isNotEmpty == true
        ? worker.displayName!.trim()
        : worker.externalId?.trim().isNotEmpty == true
            ? worker.externalId!.trim()
            : worker.id;

bool canManageWorkerVisits(Group group, String? userId) {
  final id = userId?.trim() ?? '';
  if (id.isEmpty) return false;
  if (group.ownerId == id) return true;
  final role = group.userRoles[id]?.trim().toLowerCase();
  return role == 'owner' || role == 'admin' || role == 'co-admin';
}

String? visitWorkerFilterId(bool canManage, String? selectedWorkerId) =>
    canManage ? selectedWorkerId : null;

({String title, String message}) visitEmptyStateCopy(
  bool canManage,
  bool isSpanish,
) {
  if (canManage) {
    return (
      title: isSpanish
          ? 'No hay visitas en este periodo.'
          : 'No visits in this period.',
      message: isSpanish
          ? 'Prueba otro intervalo o trabajador.'
          : 'Try another date range or worker.',
    );
  }
  return (
    title: isSpanish
        ? 'No tienes visitas en este periodo.'
        : 'You have no visits in this period.',
    message: isSpanish
        ? 'Las visitas aparecer\u00e1n cuando registres una llegada o participes como acompa\u00f1ante.'
        : 'Visits will appear when you register an arrival or participate as a companion.',
  );
}

bool isWorkerProfileRequiredError(Object error) =>
    error is BackendApiException && error.code == 'WORKER_PROFILE_REQUIRED';

String workerProfileRequiredMessage(bool isSpanish) => isSpanish
    ? 'Tu usuario no est\u00e1 vinculado a un trabajador activo. Contacta con un administrador.'
    : 'Your user is not linked to an active worker. Contact an administrator.';

bool workerVisitIsActive(WorkerVisit visit) {
  final status = visit.status?.trim().toLowerCase() ?? '';
  if (status.isNotEmpty) return status == 'active';
  return visit.departedAt == null;
}

bool workerVisitIsCompleted(WorkerVisit visit) {
  final status = visit.status?.trim().toLowerCase() ?? '';
  if (status.isNotEmpty) return status == 'completed';
  return visit.departedAt != null;
}

Duration? workerVisitDuration(WorkerVisit visit, DateTime now) {
  final arrivedAt = visit.arrivedAt;
  if (arrivedAt == null) return null;
  final end = workerVisitIsActive(visit) ? now : visit.departedAt;
  if (end == null) return null;
  final duration = end.difference(arrivedAt);
  return duration.isNegative ? Duration.zero : duration;
}

DateTimeRange inclusiveLocalVisitRangeToUtc(
  DateTime start,
  DateTime inclusiveEnd,
) =>
    DateTimeRange(
      start: DateTime(start.year, start.month, start.day).toUtc(),
      end: DateTime(
        inclusiveEnd.year,
        inclusiveEnd.month,
        inclusiveEnd.day + 1,
      ).toUtc(),
    );

class VisitWorkerFilter extends StatelessWidget {
  const VisitWorkerFilter({
    super.key,
    required this.canManage,
    required this.workers,
    required this.selectedWorkerId,
    required this.isSpanish,
    required this.decoration,
    required this.onChanged,
  });

  final bool canManage;
  final List<Worker> workers;
  final String? selectedWorkerId;
  final bool isSpanish;
  final InputDecoration decoration;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      final cs = Theme.of(context).colorScheme;
      return Semantics(
        label: isSpanish ? 'Filtro: mis visitas' : 'Filter: my visits',
        child: Chip(
          key: const ValueKey('my-visits-filter'),
          avatar: const Icon(Icons.person_outline_rounded, size: 17),
          label: Text(isSpanish ? 'Mis visitas' : 'My visits'),
          side: BorderSide(color: cs.outlineVariant),
          backgroundColor: cs.primaryContainer.withValues(alpha: 0.45),
        ),
      );
    }
    return SizedBox(
      width: 276,
      child: DropdownButtonFormField<String?>(
        key: const ValueKey('manager-worker-filter'),
        initialValue: selectedWorkerId,
        isExpanded: true,
        isDense: true,
        decoration: decoration.copyWith(
          labelText: isSpanish ? 'Trabajador' : 'Worker',
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              isSpanish ? 'Todos los trabajadores' : 'All workers',
            ),
          ),
          ...workers.map(
            (worker) => DropdownMenuItem<String?>(
              value: worker.id,
              child: Text(
                workerLabel(worker),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class GeofencedVisitsView extends StatefulWidget {
  const GeofencedVisitsView({
    super.key,
    required this.group,
    this.todayOnly = false,
    this.showTrackingCard = true,
    this.showVisits = true,
  });

  final Group group;
  final bool todayOnly;
  final bool showTrackingCard;
  final bool showVisits;

  @override
  State<GeofencedVisitsView> createState() => _GeofencedVisitsViewState();
}

class _GeofencedVisitsViewState extends State<GeofencedVisitsView> {
  List<WorkerVisit> _visits = const <WorkerVisit>[];
  List<Worker> _workers = const <Worker>[];
  bool _loading = true;
  bool _workersLoaded = false;
  bool _workersLoadFailed = false;
  bool _workerProfileRequired = false;
  String? _error;
  String? _workerId;
  String? _clientId;
  late DateTimeRange _range;
  Set<String> _selectedCompanionIds = <String>{};
  Timer? _elapsedTimer;

  Worker? get _currentWorker => findCurrentActiveWorker(
        _workers,
        context.read<UserDomain>().user?.id,
      );

  bool get _canManageVisits => canManageWorkerVisits(
        widget.group,
        context.read<UserDomain>().user?.id,
      );

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = widget.todayOnly
        ? DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 1),
          )
        : DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 1),
          );
    _elapsedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _visits.any(workerVisitIsActive)) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  List<WorkerVisit> get _visibleVisits => _clientId == null
      ? _visits
      : _visits
          .where((visit) => visit.clientId == _clientId)
          .toList(growable: false);

  List<({String id, String name})> get _visitClients {
    final byId = <String, String>{};
    for (final visit in _visits) {
      if (visit.clientId.isEmpty) continue;
      byId[visit.clientId] = visit.clientName?.trim().isNotEmpty == true
          ? visit.clientName!.trim()
          : visit.clientId;
    }
    final result = byId.entries
        .map((entry) => (id: entry.key, name: entry.value))
        .toList(growable: false);
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _workersLoadFailed = false;
      _workerProfileRequired = false;
    });
    try {
      final userDomain = context.read<UserDomain>();
      final api = context.read<ITimeTrackingApiClient>();
      final repository = context.read<ITimeTrackingRepository>();
      final token = await userDomain.getAuthToken();
      final visits = await api.getWorkerVisits(
        widget.group.id,
        token,
        from: _range.start,
        to: _range.end,
        workerId: visitWorkerFilterId(_canManageVisits, _workerId),
      );
      var workers = const <Worker>[];
      try {
        workers = await repository.getWorkers(
          widget.group.id,
          token,
          status: WorkerStatus.active,
        );
      } catch (_) {
        // Workers can still review their own visits without team-list access.
        _workersLoadFailed = true;
      }
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _workers = workers;
        _workersLoaded = true;
        if (_workerId != null &&
            !workers.any((worker) => worker.id == _workerId)) {
          _workerId = null;
        }
        _selectedCompanionIds = _selectedCompanionIds
            .where((id) => workers.any((worker) => worker.id == id))
            .toSet();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (isWorkerProfileRequiredError(error)) {
          _workerProfileRequired = true;
          _error = null;
        } else {
          _error = error.toString();
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDateRange: DateTimeRange(
        start: _range.start,
        end: _range.end.subtract(const Duration(days: 1)),
      ),
    );
    if (picked == null) return;
    setState(() {
      _range = DateTimeRange(
        start:
            DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
      );
    });
    await _load();
  }

  Future<void> _startTracking() async {
    final service = context.read<GeofencedVisitTrackingService>();
    final responsible = _currentWorker;
    if (responsible == null) return;
    final selection = await _chooseVisitTeam(responsible, starting: true);
    if (selection == null || !mounted) return;
    setState(() => _selectedCompanionIds = selection);
    try {
      await service.start(
        widget.group.id,
        participantWorkerIds: selection,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? 'Seguimiento de visitas iniciado.'
                : 'Visit tracking started.',
          ),
        ),
      );
    } on LocationTrackingPermissionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: error.openSettings
              ? SnackBarAction(
                  label: _isSpanish ? 'Ajustes' : 'Settings',
                  onPressed: service.openSettings,
                )
              : null,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final mapped = visitTrackingErrorMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapped ?? error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _editVisitTeam() async {
    final responsible = _currentWorker;
    if (responsible == null) return;
    final selection = await _chooseVisitTeam(responsible);
    if (selection == null || !mounted) return;
    setState(() => _selectedCompanionIds = selection);
    await context
        .read<GeofencedVisitTrackingService>()
        .updateParticipantWorkers(
          widget.group.id,
          selection,
        );
  }

  Future<Set<String>?> _chooseVisitTeam(
    Worker responsible, {
    bool starting = false,
  }) {
    final tracking = context.read<GeofencedVisitTrackingService>();
    final initial = _selectedCompanionIds.isEmpty
        ? tracking.participantWorkerIds.toSet()
        : _selectedCompanionIds;
    return showDialog<Set<String>>(
      context: context,
      builder: (context) => _VisitTeamDialog(
        responsible: responsible,
        choices: companionWorkerChoices(_workers, responsible.id),
        initialSelection: initial,
        isSpanish: _isSpanish,
        starting: starting,
      ),
    );
  }

  Future<void> _stopTracking() async {
    try {
      await context.read<GeofencedVisitTrackingService>().stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? 'Seguimiento de visitas detenido.'
                : 'Visit tracking stopped.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (widget.showTrackingCard)
          if (!_workersLoaded)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_workersLoadFailed)
            _WorkerProfileRequiredCard(
              isSpanish: _isSpanish,
              unavailable: true,
              onRetry: _load,
            )
          else if (_currentWorker == null)
            _WorkerProfileRequiredCard(
              isSpanish: _isSpanish,
              onRetry: _load,
            )
          else
            Consumer<GeofencedVisitTrackingService>(
              builder: (context, tracking, _) => _TrackingStatusCard(
                tracking: tracking,
                currentGroupId: widget.group.id,
                isSpanish: _isSpanish,
                responsibleName: workerLabel(_currentWorker!),
                companionNames: companionWorkerChoices(
                  _workers,
                  _currentWorker!.id,
                )
                    .where((worker) =>
                        tracking.participantWorkerIds.contains(worker.id))
                    .map(workerLabel)
                    .toList(growable: false),
                onStart: _startTracking,
                onStop: _stopTracking,
                onEditTeam: _editVisitTeam,
              ),
            ),
        if (widget.showVisits)
          Expanded(child: _buildVisitWorkspace(cs))
        else
          const Spacer(),
      ],
    );
  }

  Widget _buildVisitWorkspace(ColorScheme cs) {
    final visits = _visibleVisits;
    final activeCount = visits.where(workerVisitIsActive).length;
    final completedVisits = visits.where(workerVisitIsCompleted).toList();
    final completedCount = completedVisits.length;
    final durationValues = visits
        .where(workerVisitIsCompleted)
        .map((visit) => workerVisitDuration(visit, DateTime.now()))
        .whereType<Duration>()
        .map((duration) => duration.inMinutes)
        .toList(growable: false);
    final averageMinutes = durationValues.isEmpty
        ? null
        : durationValues.reduce((a, b) => a + b) ~/ durationValues.length;
    final title = widget.todayOnly
        ? (_isSpanish ? 'Visitas de hoy' : "Today's visits")
        : (_isSpanish ? 'Historial de visitas' : 'Visit history');
    final subtitle = widget.todayOnly
        ? (_isSpanish
            ? 'Consulta llegadas, salidas, duración y visitas que siguen en curso.'
            : 'Review arrivals, departures, duration, and visits in progress.')
        : (_isSpanish
            ? 'Filtra y revisa la actividad registrada por fecha, trabajador y cliente.'
            : 'Filter recorded activity by date, worker, and client.');

    return ColoredBox(
      color: cs.surfaceContainerLowest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.todayOnly
                        ? Icons.today_rounded
                        : Icons.history_rounded,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    '${visits.length} ${_isSpanish ? 'visitas' : 'visits'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 76,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = <Widget>[
                    _VisitMetricCard(
                      icon: Icons.place_outlined,
                      label: _isSpanish ? 'Registradas' : 'Recorded',
                      value: '${visits.length}',
                      color: cs.primary,
                    ),
                    _VisitMetricCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: _isSpanish ? 'Finalizadas' : 'Completed',
                      value: '$completedCount',
                      color: const Color(0xFF16813E),
                    ),
                    _VisitMetricCard(
                      icon: Icons.timelapse_rounded,
                      label: _isSpanish ? 'En curso' : 'In progress',
                      value: '$activeCount',
                      color: const Color(0xFFE08A16),
                    ),
                    _VisitMetricCard(
                      icon: Icons.schedule_outlined,
                      label: _isSpanish ? 'Duración media' : 'Avg. duration',
                      value: averageMinutes == null
                          ? '—'
                          : _durationLabel(averageMinutes),
                      color: cs.secondary,
                    ),
                  ];
                  if (constraints.maxWidth < 720) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: metrics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => SizedBox(
                        width: 160,
                        child: metrics[index],
                      ),
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        Expanded(child: metrics[index]),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildFilterToolbar(cs),
            const SizedBox(height: 12),
            Expanded(child: _buildVisits(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(ColorScheme cs) {
    final filterDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.todayOnly)
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.calendar_today_rounded, size: 17),
              label: Text(
                DateFormat('dd MMM yyyy', _isSpanish ? 'es' : 'en')
                    .format(_range.start),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(
                '${DateFormat('dd/MM/yyyy').format(_range.start)} – '
                '${DateFormat('dd/MM/yyyy').format(_range.end.subtract(const Duration(days: 1)))}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          VisitWorkerFilter(
            canManage: _canManageVisits,
            workers: _workers,
            selectedWorkerId: _workerId,
            isSpanish: _isSpanish,
            decoration: filterDecoration,
            onChanged: (value) {
              setState(() {
                _workerId = value;
                _clientId = null;
              });
              _load();
            },
          ),
          if (_visitClients.isNotEmpty)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                key: ValueKey(_clientId),
                initialValue: _clientId,
                isDense: true,
                decoration: filterDecoration.copyWith(
                  labelText: _isSpanish ? 'Cliente' : 'Client',
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_isSpanish ? 'Todos' : 'All'),
                  ),
                  ..._visitClients.map(
                    (client) => DropdownMenuItem<String?>(
                      value: client.id,
                      child: Text(
                        client.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _clientId = value),
              ),
            ),
          IconButton.filledTonal(
            tooltip: _isSpanish ? 'Actualizar' : 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size(46, 46),
              fixedSize: const Size(46, 46),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    return '${hours}h ${remainder.toString().padLeft(2, '0')}m';
  }

  Widget _buildVisits(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_workerProfileRequired) {
      return _VisitsMessageState(
        icon: Icons.badge_outlined,
        title: _isSpanish
            ? 'Perfil de trabajador necesario'
            : 'Worker profile required',
        message: workerProfileRequiredMessage(_isSpanish),
        actionLabel: _isSpanish ? 'Reintentar' : 'Retry',
        onAction: _load,
        error: true,
      );
    }
    if (_error != null) {
      return _VisitsMessageState(
        icon: Icons.error_outline_rounded,
        title: _isSpanish
            ? 'No se pudieron cargar las visitas'
            : 'Visits could not be loaded',
        message: _error!,
        actionLabel: _isSpanish ? 'Reintentar' : 'Retry',
        onAction: _load,
        error: true,
      );
    }
    final visits = _visibleVisits;
    if (visits.isEmpty && _clientId == null) {
      final copy = visitEmptyStateCopy(_canManageVisits, _isSpanish);
      return _VisitsMessageState(
        icon: Icons.location_off_outlined,
        title: copy.title,
        message: copy.message,
        actionLabel: _isSpanish ? 'Actualizar' : 'Refresh',
        onAction: _load,
      );
    }
    if (visits.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 28,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.todayOnly
                      ? (_isSpanish
                          ? 'Aún no hay visitas hoy'
                          : 'No visits yet today')
                      : (_isSpanish
                          ? 'No hay visitas en este periodo'
                          : 'No visits in this period'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 7),
                Text(
                  _clientId != null
                      ? (_isSpanish
                          ? 'No hay resultados para el cliente seleccionado.'
                          : 'There are no results for the selected client.')
                      : widget.todayOnly
                          ? (_isSpanish
                              ? 'Las llegadas aparecerán aquí cuando un trabajador entre en la ubicación configurada de un cliente.'
                              : 'Arrivals will appear here when a worker enters a configured client location.')
                          : (_isSpanish
                              ? 'Prueba a seleccionar otro intervalo o trabajador.'
                              : 'Try selecting another date range or worker.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_isSpanish ? 'Actualizar' : 'Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1050) {
          return _VisitDesktopTable(
            visits: visits,
            isSpanish: _isSpanish,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: visits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: _VisitCard(
                visit: visits[index],
                isSpanish: _isSpanish,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VisitMetricCard extends StatelessWidget {
  const _VisitMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitsMessageState extends StatelessWidget {
  const _VisitsMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = error ? cs.error : cs.primary;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: title,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 7),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerProfileRequiredCard extends StatelessWidget {
  const _WorkerProfileRequiredCard({
    required this.isSpanish,
    required this.onRetry,
    this.unavailable = false,
  });

  final bool isSpanish;
  final VoidCallback onRetry;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('worker-profile-required'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unavailable
                  ? (isSpanish
                      ? 'No se pudieron cargar los trabajadores activos.'
                      : 'Active workers could not be loaded.')
                  : (isSpanish
                      ? 'Para registrar visitas, a\u00f1ade tu usuario como trabajador activo.'
                      : 'To register visits, add your user as an active worker.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isSpanish ? 'Actualizar' : 'Refresh',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _VisitTeamDialog extends StatefulWidget {
  const _VisitTeamDialog({
    required this.responsible,
    required this.choices,
    required this.initialSelection,
    required this.isSpanish,
    required this.starting,
  });

  final Worker responsible;
  final List<Worker> choices;
  final Set<String> initialSelection;
  final bool isSpanish;
  final bool starting;

  @override
  State<_VisitTeamDialog> createState() => _VisitTeamDialogState();
}

class _VisitTeamDialogState extends State<_VisitTeamDialog> {
  late final Set<String> _selected;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final validIds = widget.choices.map((worker) => worker.id).toSet();
    _selected =
        widget.initialSelection.where(validIds.contains).take(20).toSet();
  }

  void _toggle(String workerId, bool selected) {
    setState(() {
      if (selected) {
        if (_selected.length < 20) _selected.add(workerId);
      } else {
        _selected.remove(workerId);
      }
    });
  }

  List<Worker> get _visibleChoices {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.choices;
    return widget.choices
        .where((worker) => workerLabel(worker).toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.groups_2_rounded, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.isSpanish ? 'Equipo de la visita' : 'Visit team'),
                const SizedBox(height: 3),
                Text(
                  widget.isSpanish
                      ? 'Elige qui\u00e9n acompa\u00f1ar\u00e1 al responsable en esta visita.'
                      : 'Choose who will accompany the responsible worker.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: widget.isSpanish ? 'Cerrar' : 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  _WorkerAvatar(
                    name: workerLabel(widget.responsible),
                    selected: true,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSpanish ? 'Responsable' : 'Lead',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Text(
                          workerLabel(widget.responsible),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isSpanish
                        ? 'A\u00f1adir acompa\u00f1antes'
                        : 'Add companions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_selected.length}/20',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText:
                    widget.isSpanish ? 'Buscar trabajador' : 'Search workers',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final worker in widget.choices.where(
                      (worker) => _selected.contains(worker.id),
                    ))
                      InputChip(
                        avatar: _WorkerAvatar(
                          name: workerLabel(worker),
                          selected: true,
                          compact: true,
                        ),
                        label: Text(workerLabel(worker)),
                        onDeleted: () => _toggle(worker.id, false),
                        side: BorderSide.none,
                        backgroundColor: cs.surface,
                      ),
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text(widget.isSpanish ? 'Quitar todos' : 'Clear'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: widget.choices.isEmpty
                  ? _TeamEmptyState(
                      icon: Icons.person_off_outlined,
                      message: widget.isSpanish
                          ? 'No hay otros trabajadores activos.'
                          : 'There are no other active workers.',
                    )
                  : _visibleChoices.isEmpty
                      ? _TeamEmptyState(
                          icon: Icons.search_off_rounded,
                          message: widget.isSpanish
                              ? 'No hay trabajadores que coincidan.'
                              : 'No workers match your search.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _visibleChoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final worker = _visibleChoices[index];
                            final selected = _selected.contains(worker.id);
                            final disabled =
                                !selected && _selected.length >= 20;
                            return Material(
                              color: selected
                                  ? cs.primaryContainer.withValues(alpha: 0.5)
                                  : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(13),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: disabled
                                    ? null
                                    : () => _toggle(worker.id, !selected),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      _WorkerAvatar(
                                        name: workerLabel(worker),
                                        selected: selected,
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(
                                          workerLabel(worker),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: selected,
                                        onChanged: disabled
                                            ? null
                                            : (value) => _toggle(
                                                  worker.id,
                                                  value == true,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (_selected.isEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    widget.isSpanish
                        ? 'Puedes continuar sin acompa\u00f1antes.'
                        : 'You can continue without companions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isSpanish ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, Set<String>.from(_selected)),
          child: Text(
            widget.starting
                ? (widget.isSpanish ? 'Iniciar seguimiento' : 'Start tracking')
                : (widget.isSpanish ? 'Guardar equipo' : 'Save team'),
          ),
        ),
      ],
    );
  }
}

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({
    required this.name,
    required this.selected,
    this.compact = false,
  });

  final String name;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = compact ? 22.0 : 36.0;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          fontSize: compact ? 10 : 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TeamEmptyState extends StatelessWidget {
  const _TeamEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({
    required this.tracking,
    required this.currentGroupId,
    required this.isSpanish,
    required this.responsibleName,
    required this.companionNames,
    required this.onStart,
    required this.onStop,
    required this.onEditTeam,
  });

  final GeofencedVisitTrackingService tracking;
  final String currentGroupId;
  final bool isSpanish;
  final String responsibleName;
  final List<String> companionNames;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEditTeam;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeHere =
        tracking.isActive && tracking.session?.groupId == currentGroupId;
    final runningHere = activeHere && tracking.isStreamActive;
    final color = runningHere
        ? const Color(0xFF198754)
        : activeHere
            ? const Color(0xFFE09B25)
            : cs.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              runningHere
                  ? Icons.location_on_rounded
                  : Icons.location_searching_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  runningHere
                      ? (isSpanish ? 'Seguimiento activo' : 'Tracking active')
                      : activeHere
                          ? (isSpanish
                              ? 'Seguimiento en pausa'
                              : 'Tracking paused')
                          : (isSpanish
                              ? 'Seguimiento de visitas'
                              : 'Visit tracking'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${isSpanish ? 'Responsable' : 'Lead'}: $responsibleName',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: tracking.isBusy ? null : onEditTeam,
                      icon: const Icon(Icons.groups_2_outlined, size: 17),
                      label: Text(
                        companionNames.isEmpty
                            ? (isSpanish
                                ? 'A\u00f1adir acompa\u00f1antes'
                                : 'Add companions')
                            : '${isSpanish ? 'Editar equipo' : 'Edit team'} · ${companionNames.length + 1}',
                      ),
                    ),
                  ],
                ),
                if (companionNames.isNotEmpty)
                  Text(
                    '${isSpanish ? 'Acompa\u00f1antes' : 'Companions'}: ${companionNames.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                const SizedBox(height: 3),
                Text(
                  runningHere
                      ? (isSpanish
                          ? '${tracking.clientLocationCount} ubicaciones activas · solo se guardan llegadas y salidas'
                          : '${tracking.clientLocationCount} active locations · only arrivals and departures are stored')
                      : activeHere
                          ? (isSpanish
                              ? 'Reanuda la ubicación en segundo plano para continuar.'
                              : 'Resume background location to continue.')
                          : (isSpanish
                              ? 'Inícialo antes de comenzar la ruta de trabajo.'
                              : 'Start it before beginning the work route.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                if ((tracking.error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tracking.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: tracking.isBusy
                ? null
                : runningHere
                    ? onStop
                    : activeHere
                        ? onStart
                        : tracking.isActive
                            ? null
                            : onStart,
            style: FilledButton.styleFrom(backgroundColor: color),
            icon: tracking.isBusy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(runningHere
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded),
            label: Text(
              runningHere
                  ? (isSpanish ? 'Detener' : 'Stop')
                  : activeHere
                      ? (isSpanish ? 'Reanudar' : 'Resume')
                      : (isSpanish ? 'Iniciar' : 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}

String _visitDurationLabel(Duration? duration) {
  if (duration == null) return '—';
  final minutes = duration.inMinutes;
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  return '${hours}h ${remainder.toString().padLeft(2, '0')}m';
}

Future<void> _showVisitTeamPopover(
  BuildContext context,
  WorkerVisit visit,
  bool isSpanish,
) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.groups_2_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Text(isSpanish ? 'Equipo de la visita' : 'Visit team'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VisitDetail(
                  label: isSpanish ? 'Responsable' : 'Lead',
                  value: visit.workerName ?? visit.workerId ?? '—',
                ),
                if (visit.participantWorkers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _VisitDetail(
                    label: isSpanish ? 'Acompa\u00f1antes' : 'Companions',
                    value: visit.participantWorkers
                        .map((worker) => worker.displayName ?? worker.id)
                        .join(', '),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isSpanish ? 'Cerrar' : 'Close'),
            ),
          ],
        );
      },
    );

class VisitTeamBadge extends StatelessWidget {
  const VisitTeamBadge({
    super.key,
    required this.visit,
    required this.isSpanish,
  });

  final WorkerVisit visit;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final label =
        '${visit.teamSize} ${isSpanish ? (visit.teamSize == 1 ? 'trabajador' : 'trabajadores') : (visit.teamSize == 1 ? 'worker' : 'workers')}';
    return Semantics(
      button: true,
      label: '${isSpanish ? 'Equipo de la visita' : 'Visit team'}: $label',
      child: Tooltip(
        message: isSpanish ? 'Ver equipo de la visita' : 'View visit team',
        child: ActionChip(
          avatar: const Icon(Icons.groups_2_outlined, size: 15),
          label: Text(label),
          onPressed: () => _showVisitTeamPopover(context, visit, isSpanish),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _VisitDesktopTable extends StatelessWidget {
  const _VisitDesktopTable({required this.visits, required this.isSpanish});

  final List<WorkerVisit> visits;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _VisitTableCell(label: isSpanish ? 'Fecha' : 'Date', flex: 11),
              _VisitTableCell(
                  label: isSpanish ? 'Cliente' : 'Client', flex: 18),
              _VisitTableCell(
                label: isSpanish ? 'Responsable' : 'Lead',
                flex: 15,
              ),
              _VisitTableCell(label: isSpanish ? 'Equipo' : 'Team', flex: 13),
              _VisitTableCell(
                  label: isSpanish ? 'Llegada' : 'Arrival', flex: 9),
              _VisitTableCell(
                  label: isSpanish ? 'Salida' : 'Departure', flex: 9),
              _VisitTableCell(
                label: isSpanish ? 'Duraci\u00f3n' : 'Duration',
                flex: 10,
              ),
              _VisitTableCell(label: isSpanish ? 'Estado' : 'Status', flex: 11),
              _VisitTableCell(
                label: isSpanish ? 'Acci\u00f3n' : 'Action',
                flex: 7,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, index) =>
                _VisitDesktopRow(visit: visits[index], isSpanish: isSpanish),
          ),
        ),
      ],
    );
  }
}

class _VisitDesktopRow extends StatelessWidget {
  const _VisitDesktopRow({required this.visit, required this.isSpanish});

  final WorkerVisit visit;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arrived = visit.arrivedAt?.toLocal();
    final departed = visit.departedAt?.toLocal();
    final active = workerVisitIsActive(visit);
    final statusColor =
        active ? const Color(0xFFE08A16) : const Color(0xFF16813E);
    final duration = workerVisitDuration(visit, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          _VisitTableCell(
            label: arrived == null
                ? '—'
                : DateFormat('dd/MM/yyyy').format(arrived),
            flex: 11,
          ),
          _VisitTableCell(
            label: visit.clientName ?? visit.clientId,
            flex: 18,
            strong: true,
          ),
          _VisitTableCell(
            label: visit.workerName ?? visit.workerId ?? '—',
            flex: 15,
          ),
          Expanded(
            flex: 13,
            child: Align(
              alignment: Alignment.centerLeft,
              child: VisitTeamBadge(visit: visit, isSpanish: isSpanish),
            ),
          ),
          _VisitTableCell(
            label: arrived == null ? '—' : DateFormat('HH:mm').format(arrived),
            flex: 9,
          ),
          _VisitTableCell(
            label:
                departed == null ? '—' : DateFormat('HH:mm').format(departed),
            flex: 9,
          ),
          _VisitTableCell(label: _visitDurationLabel(duration), flex: 10),
          Expanded(
            flex: 11,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: active
                    ? (isSpanish ? 'En curso' : 'In progress')
                    : (isSpanish ? 'Finalizada' : 'Completed'),
                color: statusColor,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Center(
              child: Semantics(
                button: true,
                label:
                    isSpanish ? 'Ver detalles del equipo' : 'View team details',
                child: IconButton(
                  tooltip: isSpanish ? 'Ver equipo' : 'View team',
                  onPressed: () =>
                      _showVisitTeamPopover(context, visit, isSpanish),
                  icon: const Icon(Icons.visibility_outlined, size: 19),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitTableCell extends StatelessWidget {
  const _VisitTableCell({
    required this.label,
    required this.flex,
    this.strong = false,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final int flex;
  final bool strong;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strong ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.isSpanish});

  final WorkerVisit visit;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = visit.arrivedAt?.toLocal();
    final formatter = DateFormat('dd/MM/yyyy · HH:mm');
    final departure = visit.departedAt?.toLocal();
    final duration = workerVisitDuration(visit, DateTime.now());
    final active = workerVisitIsActive(visit);
    final statusColor =
        active ? const Color(0xFFE08A16) : const Color(0xFF16813E);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: active
              ? statusColor.withValues(alpha: 0.32)
              : cs.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active
                  ? statusColor.withValues(alpha: 0.12)
                  : cs.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              active ? Icons.location_searching_rounded : Icons.place_rounded,
              size: 20,
              color: active ? statusColor : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visit.clientName ?? visit.clientId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: active
                          ? (isSpanish ? 'En curso' : 'In progress')
                          : (isSpanish ? 'Finalizada' : 'Completed'),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if ((visit.workerName ?? visit.workerId ?? '').isNotEmpty)
                  _VisitDetail(
                    label: isSpanish ? 'Responsable' : 'Lead',
                    value: visit.workerName ?? visit.workerId!,
                  ),
                if (visit.participantWorkers.isNotEmpty)
                  _VisitDetail(
                    label: isSpanish ? 'Acompa\u00f1antes' : 'Companions',
                    value: visit.participantWorkers
                        .map((worker) => worker.displayName ?? worker.id)
                        .join(', '),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _VisitTime(
                      icon: Icons.login_rounded,
                      label: date == null ? '—' : formatter.format(date),
                    ),
                    _VisitTime(
                      icon: Icons.logout_rounded,
                      label: departure == null
                          ? active
                              ? (isSpanish
                                  ? 'Visita en curso'
                                  : 'Visit in progress')
                              : '—'
                          : DateFormat('HH:mm').format(departure),
                    ),
                    VisitTeamBadge(visit: visit, isSpanish: isSpanish),
                    if (duration != null)
                      _VisitTime(
                        icon: Icons.schedule_rounded,
                        label: _visitDurationLabel(duration),
                        emphasized: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitDetail extends StatelessWidget {
  const _VisitDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Tooltip(
          message: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _VisitTime extends StatelessWidget {
  const _VisitTime({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? cs.primaryContainer.withValues(alpha: 0.55)
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasized ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: emphasized ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
