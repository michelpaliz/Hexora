import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';

/// Lightweight view models used by the work-visit form (no backend changes needed).
class ClientLite {
  final String id;
  final String? name;
  const ClientLite({required this.id, this.name});
}

class ServiceLite {
  final String id;
  final String? name;
  const ServiceLite({required this.id, this.name});
}

abstract class BaseEventLogic<T extends StatefulWidget> extends State<T> {
  // ---------------- Controllers ----------------
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();

  // Public reactive validity
  final ValueNotifier<bool> canSubmit = ValueNotifier<bool>(false);

  // ---------------- UI state ----------------
  late Color _selectedEventColor;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  @protected
  bool get requireAssignees => false;
  // --- Config: should the form require at least one assigned user? ---

  bool _isDisposed = false;

  @protected
  bool get requireTitle => true;

  @protected
  bool get requireClientServiceForWorkVisit => true;

  /// For simple events you can choose to force a category (set to true if you want)
  @protected
  bool get requireCategoryForSimple => false;

  // Recurrence
  LegacyRecurrenceRule? _recurrenceRule;
  bool _isRepetitive = false;

  // Misc UI
  final double _toggleWidth = 50.0;
  int _reminderMinutes = 10;

  // Users
  @protected
  List<User> _users = [];
  @protected
  List<User> _selectedUsers = [];

  // Categories (only for type='simple')
  String? _categoryId;
  String? _subcategoryId;

  // ---------------- NEW: Event type & work-visit fields ----------------
  /// 'simple' | 'work_visit' (default)
  String _eventType = 'work_visit';

  /// Work-visit selections
  String? _clientId;
  String? _primaryServiceId;

  /// Data sources for pickers (optional; provide from your screen/controller)
  @protected
  List<ClientLite>? availableClients;
  @protected
  List<ServiceLite>? availableServices;

  /// Optional hooks the UI may call (assign in your concrete logic if preferred).
  /// If you don't override, we wire sensible defaults in initState.
  void Function(String type)? setEventType;
  void Function(String? clientId)? setClientId;
  void Function(String? serviceId)? setPrimaryServiceId;

  // setters to feed data
  void setAvailableClients(List<ClientLite> items) {
    availableClients = items;
    _safeRebuild(); // use the safe rebuild helper you added earlier
  }

  void setAvailableServices(List<ServiceLite> items) {
    availableServices = items;
    _safeRebuild();
  }

  void _safeRebuild() {
    if (!mounted) return;
    // If we're in the build/layout phase, defer to after the frame.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Optional recurrence dialog hook (UI checks for null before using).
  /// Renamed to avoid clashing with EventDialogs.showRepetitionDialog.
  Future<List?> Function(
    BuildContext context, {
    required DateTime selectedStartDate,
    required DateTime selectedEndDate,
    LegacyRecurrenceRule? initialRule,
  })? onShowRepetitionDialog;

  // ---------------- Lifecycle ----------------
  @mustCallSuper
  @override
  void initState() {
    super.initState();
    initializeBaseDefaults();
    _attachFormListeners();

    setEventType ??= (t) {
      _eventType = (t.isEmpty ? 'work_visit' : t).toLowerCase();
      _safeRebuild();
      // If your validity depends on type, also defer validity:
      WidgetsBinding.instance.addPostFrameCallback((_) => recomputeValidity());
    };

    setClientId ??= (v) {
      _clientId = v;
      _safeRebuild();
      WidgetsBinding.instance.addPostFrameCallback((_) => recomputeValidity());
    };

    setPrimaryServiceId ??= (v) {
      _primaryServiceId = v;
      _safeRebuild();
      WidgetsBinding.instance.addPostFrameCallback((_) => recomputeValidity());
    };

    recomputeValidity();
  }

  @mustCallSuper
  @override
  void dispose() {
    _isDisposed = true;
    _detachFormListeners();
    canSubmit.dispose();

    // Defer actual controller disposal to avoid dispose-order issues on hot reload.
    final title = _titleController;
    final desc = _descriptionController;
    final note = _noteController;
    final loc = _locationController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        title.dispose();
      } catch (_) {}
      try {
        desc.dispose();
      } catch (_) {}
      try {
        note.dispose();
      } catch (_) {}
      try {
        loc.dispose();
      } catch (_) {}
    });

    super.dispose();
  }

  // ---------------- Initialization ----------------
  @mustCallSuper
  void initializeBaseDefaults() {
    _selectedEventColor = ColorManager.eventColors.last;
    _selectedStartDate = DateTime.now();
    _selectedEndDate = _selectedStartDate.add(const Duration(hours: 1));
    _recurrenceRule = null;
    _isRepetitive = false;
    _users = [];
    _selectedUsers = [];
    _categoryId = null;
    _subcategoryId = null;

    // sensible defaults for the new fields
    _eventType = 'work_visit';
    _clientId = null;
    _primaryServiceId = null;

    recomputeValidity();
  }

  void _attachFormListeners() {
    _titleController.addListener(recomputeValidity);
    _locationController.addListener(recomputeValidity);
    _descriptionController.addListener(recomputeValidity);
    _noteController.addListener(recomputeValidity);
  }

  void _detachFormListeners() {
    _titleController.removeListener(recomputeValidity);
    _locationController.removeListener(recomputeValidity);
    _descriptionController.removeListener(recomputeValidity);
    _noteController.removeListener(recomputeValidity);
  }

  // ---------------- Controller access ----------------
  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get noteController => _noteController;
  TextEditingController get locationController => _locationController;

  // ---------------- State access ----------------
  /// Returns ARGB int color for widgets that expect an int
  int? get selectedEventColor => _selectedEventColor.value;
  List<int> get colorList =>
      ColorManager.eventColors.map((c) => c.value).toList();

  DateTime get selectedStartDate => _selectedStartDate;
  DateTime get selectedEndDate => _selectedEndDate;

  LegacyRecurrenceRule? get recurrenceRule => _recurrenceRule;
  bool get isRepetitive => _isRepetitive;

  double get toggleWidth => _toggleWidth;

  List<User> get users => _users;
  List<User> get selectedUsers => _selectedUsers;
  List<User>? get selectedUsersOrNull =>
      _selectedUsers.isEmpty ? null : _selectedUsers;

  // Categories (simple)
  String? get categoryId => _categoryId;
  String? get subcategoryId => _subcategoryId;

  // NEW: event type & work-visit getters used by the forms/router
  String get eventType => _eventType;
  String? get clientId => _clientId;
  String? get primaryServiceId => _primaryServiceId;
  List<ClientLite> get clients => availableClients ?? const [];
  List<ServiceLite> get services => availableServices ?? const [];

  // ---------------- Mutators ----------------
  void setSelectedColor(int colorValue) {
    _selectedEventColor = Color(colorValue);
    if (mounted) setState(() {});
    recomputeValidity();
  }

  void toggleRepetition(bool value, LegacyRecurrenceRule? rule) {
    _isRepetitive = value;
    _recurrenceRule = value ? rule : null;
    if (mounted) setState(() {});
    recomputeValidity();
  }

  void setRecurrenceRule(LegacyRecurrenceRule? rule) {
    _recurrenceRule = rule;
    _isRepetitive = rule != null ? true : _isRepetitive;
    if (mounted) setState(() {});
    recomputeValidity();
  }

  void setSelectedUsers(List<User> users) {
    _selectedUsers = users;
    if (mounted) setState(() {});
    recomputeValidity();
  }

  set categoryId(String? v) {
    _categoryId = v;
    if (mounted) setState(() {});
    recomputeValidity();
  }

  set subcategoryId(String? v) {
    _subcategoryId = v;
    if (mounted) setState(() {});
    recomputeValidity();
  }

  void setStartDate(DateTime dt) => setState(() {
        _selectedStartDate = dt;
        if (_selectedEndDate.isBefore(dt)) {
          _selectedEndDate = dt.add(const Duration(hours: 1));
        }
        recomputeValidity();
      });

  void setEndDate(DateTime dt) => setState(() {
        _selectedEndDate = dt;
        recomputeValidity();
      });

  Future<void> selectDate(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStart ? _selectedStartDate : _selectedEndDate,
        ),
      );

      if (pickedTime != null) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        isStart ? setStartDate(combined) : setEndDate(combined);
      }
    }
  }

  void disposeBaseControllers() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _locationController.dispose();
  }

  // ---------------- Abstracts ----------------
  /// Implemented by concrete logic (Add flow)
  Future<bool> addEvent(BuildContext context);

  // ---------------- Reminder ----------------
  void setReminderMinutes(int minutes) {
    _reminderMinutes = minutes;
    recomputeValidity();
  }

  int get reminderMinutes => _reminderMinutes;

  // ---------------- Validation ----------------
  @protected
  bool isFormValid() {
    if (_isDisposed) return false;

    // dates
    final datesOk = _selectedStartDate.isBefore(_selectedEndDate) ||
        _selectedStartDate.isAtSameMomentAs(_selectedEndDate);

    // title
    final titleOk = !requireTitle || _titleController.text.trim().isNotEmpty;

    // assignees (already have the flag)
    final assigneesOk = !requireAssignees || _selectedUsers.isNotEmpty;

    // type-specific
    final isWorkVisit = _eventType == 'work_visit';

    final clientOk = !requireClientServiceForWorkVisit || !isWorkVisit
        ? true
        : (_clientId != null && _clientId!.isNotEmpty);

    final serviceOk = !requireClientServiceForWorkVisit || !isWorkVisit
        ? true
        : (_primaryServiceId != null && _primaryServiceId!.isNotEmpty);

    final categoryOk = !requireCategoryForSimple || isWorkVisit
        ? true
        : (_categoryId != null && _categoryId!.isNotEmpty);

    return datesOk &&
        titleOk &&
        assigneesOk &&
        clientOk &&
        serviceOk &&
        categoryOk;
  }

  @protected
  @mustCallSuper
  void recomputeValidity() {
    if (_isDisposed) return;
    canSubmit.value = isFormValid();
  }

  bool canSubmitNow() => isFormValid();
}
