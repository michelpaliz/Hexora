// add_event_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/function/helper/add_event_helpers.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_form_router.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../../../../b-backend/group_mng_flow/group/domain/group_domain.dart';
import '../../../../../../../b-backend/notification/domain/notification_domain.dart';
import '../add_recurrence_rule/add_event_dialogs.dart';
import '../function/logic/add_event_logic.dart';

class AddEventScreen extends StatefulWidget {
  final Group group;
  final bool embedded;
  final VoidCallback? onCreated;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const AddEventScreen({
    Key? key,
    required this.group,
    this.embedded = false,
    this.onCreated,
    this.initialStartDate,
    this.initialEndDate,
  }) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends AddEventLogic<AddEventScreen>
    with AddEventDialogs
    implements EventDialogs {
  bool _initialized = false;
  bool _isLoading = true;
  DateTime? _lastAppliedStartDate;
  DateTime? _lastAppliedEndDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      injectDependencies(
        groupDomain: context.read<GroupDomain>(),
        userDomain: context.read<UserDomain>(),
        notifMgmt: context.read<NotificationDomain>(),
      );
      _initialized = true;
      _initializeLogic();
    }
  }

  Future<void> _initializeLogic() async {
    try {
      await initializeLogic(widget.group, context);
      _applyInitialDateSelection();

      // keep reactive title validity update
      titleController.addListener(() {
        if (mounted) setState(() {});
      });

      // 🔗 Wire the repetition dialog hook so forms can open it
      onShowRepetitionDialog = (
        BuildContext _, {
        required DateTime selectedStartDate,
        required DateTime selectedEndDate,
        LegacyRecurrenceRule? initialRule,
      }) {
        return showRepetitionDialog(
          context,
          selectedStartDate: selectedStartDate,
          selectedEndDate: selectedEndDate,
          initialRule: initialRule,
        );
      };
    } catch (e, s) {
      debugPrint('AddEventScreen init failed: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load data, try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant AddEventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final startChanged = widget.initialStartDate != oldWidget.initialStartDate;
    final endChanged = widget.initialEndDate != oldWidget.initialEndDate;
    if (!_initialized || (!startChanged && !endChanged)) return;
    _applyInitialDateSelection();
  }

  void _applyInitialDateSelection() {
    final initialStart = widget.initialStartDate;
    if (initialStart == null) return;
    final initialEnd =
        widget.initialEndDate ?? initialStart.add(const Duration(hours: 1));
    final alreadyApplied =
        _lastAppliedStartDate == initialStart && _lastAppliedEndDate == initialEnd;
    if (alreadyApplied) return;
    _lastAppliedStartDate = initialStart;
    _lastAppliedEndDate = initialEnd;
    setStartDate(initialStart);
    setEndDate(initialEnd);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isEmbeddedWeb = widget.embedded && kIsWeb;

    // single source of truth for CategoryApi
    final categoryApi = CategoryApi(
      baseUrl: ApiConstants.baseUrl,
      headersProvider: () => AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: true,
      ),
    );

    // Always use work visit form (client/service pickers enabled)
    const isWorkVisit = true;

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 980 : 650),
              child: SingleChildScrollView(
                padding: isEmbeddedWeb
                    ? const EdgeInsets.fromLTRB(0, 4, 0, 4)
                    : const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EventFormRouter(
                      logic: this,
                      onSubmit: () async {
                        final ok = await withLoadingDialog<bool>(
                          context,
                          () => addEvent(context),
                          message: l.createEventMessage,
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          widget.onCreated?.call();
                          if (!widget.embedded) {
                            Navigator.pop(context, true);
                          }
                        } else {
                          showErrorDialog(context);
                        }
                      },
                      ownerUserId: context.read<UserDomain>().user!.id,
                      isEditing: false,
                      categoryApi: categoryApi,
                      dialogs: this,
                      enableClientServicePickers: isWorkVisit,
                    ),
                  ],
                ),
              ),
            ),
          );

    if (isEmbeddedWeb) {
      return ColoredBox(color: Colors.transparent, child: body);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(
          l.addEvent,
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        backgroundColor: ThemeColors.cardBg(context),
        elevation: 0,
      ),
      body: body,
    );
  }

  @override
  Widget buildRepetitionDialog(BuildContext context) {
    return RepetitionScreen(
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
      initialRecurrenceRule: recurrenceRule,
    );
  }
}
