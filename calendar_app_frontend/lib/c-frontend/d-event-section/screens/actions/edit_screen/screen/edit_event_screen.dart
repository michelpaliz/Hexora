// c-frontend/d-event-section/screens/actions/edit_screen/screen/edit_event_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/edit_screen/functions/edit/edit_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/event_form_router.dart';
// 🔹 Use the same style + typography as Work Visit:
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit_style.dart';
import 'package:hexora/c-frontend/d-event-section/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  const EditEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends EditEventLogic<EditEventScreen>
    implements EventDialogs {
  bool _initialized = false;

  // APIs just for loading pickers in work-visit mode
  final _clientsApi = ClientsApi();
  final _servicesApi = ServiceApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeLogic();
      _initialized = true;
    }
  }

  // Future<void> _initializeLogic() async {
  //   await initLogic(
  //     event: widget.event,
  //     gm: context.read<GroupDomain>(),
  //     um: context.read<UserDomain>(),
  //   );

  //   final group = context.read<GroupDomain>().currentGroup;
  //   if (group != null) {
  //     try {
  //       final clients = await _clientsApi.list(groupId: group.id);
  //       setAvailableClients(
  //         clients.map((c) => ClientLite(id: c.id, name: c.name)).toList(),
  //       );
  //     } catch (_) {
  //       setAvailableClients(const []);
  //     }
  //     try {
  //       final services = await _servicesApi.list(groupId: group.id);
  //       setAvailableServices(
  //         services.map((s) => ServiceLite(id: s.id, name: s.name)).toList(),
  //       );
  //     } catch (_) {
  //       setAvailableServices(const []);
  //     }
  //   }

  //   if (mounted) setState(() {});
  // }

  Future<void> _initializeLogic() async {
    await initLogic(
      event: widget.event,
      gm: context.read<GroupDomain>(),
      um: context.read<UserDomain>(),
    );

    // NEW: reflect hydrated values in the submit button state
    recomputeValidity(); // <- this updates logic.canSubmit for edit mode

    final group = context.read<GroupDomain>().currentGroup;
    if (group != null) {
      try {
        final clients = await _clientsApi.list(groupId: group.id);
        setAvailableClients(
          clients.map((c) => ClientLite(id: c.id, name: c.name)).toList(),
        );
      } catch (_) {
        setAvailableClients(const []);
      }
      try {
        final services = await _servicesApi.list(groupId: group.id);
        setAvailableServices(
          services.map((s) => ServiceLite(id: s.id, name: s.name)).toList(),
        );
      } catch (_) {
        setAvailableServices(const []);
      }
    }

    // (Optional) If your edit flow requires client/service when type == work_visit,
    // recompute again after async pickers load:
    recomputeValidity(); // NEW (optional but harmless)

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    disposeLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context); // 🔹 your font tokens

    final categoryApi = CategoryApi(
      baseUrl: ApiConstants.baseUrl,
      headersProvider: () async {
        final auth = context.read<AuthProvider>();
        final token = await auth.getToken();
        return {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
      },
    );

// Match WorkVisit spacing
    final outer = WorkVisitStyle.outerPadding;
// sectionGap is a SizedBox; its height is double?
    final runGap = WorkVisitStyle.sectionGap.height ?? 0.0; // <-- fix
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   l.event,
        //   style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        // ),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(
          l.editEvent,

          // use Typo bodySmall as requested, bolded for prominence
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: outer,
              child: Wrap(
                runSpacing: runGap,
                children: [
                  _FullWidth(
                    child: EventFormRouter(
                      logic: this, // <- same state (EditEventLogic)
                      onSubmit: () =>
                          saveEditedEvent(context.read<EventDomain>()),
                      ownerUserId: context.read<UserDomain>().user!.id,
                      categoryApi: categoryApi,
                      isEditing: true,
                      dialogs:
                          this, // enables repetition dialog where applicable
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // EventDialogs implementation (used by simple form only)
  @override
  Widget buildRepetitionDialog(BuildContext context) {
    return RepetitionDialog(
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
      initialRecurrenceRule: recurrenceRule,
    );
  }

  @override
  void showErrorDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.event),
        content: Text(AppLocalizations.of(context)!.errorEventCreation),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Future<List<Object?>?> showRepetitionDialog(
    BuildContext context, {
    required DateTime selectedStartDate,
    required DateTime selectedEndDate,
    LegacyRecurrenceRule? initialRule,
  }) {
    return showDialog<List<Object?>?>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => RepetitionDialog(
        selectedStartDate: selectedStartDate,
        selectedEndDate: selectedEndDate,
        initialRecurrenceRule: initialRule,
      ),
    );
  }
}

/// Forces children inside a Wrap to take full width (so Wrap is only used for runSpacing)
class _FullWidth extends StatelessWidget {
  final Widget child;
  const _FullWidth({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bc) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: bc.maxWidth),
        child: child,
      ),
    );
  }
}
