import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/edit_screen/functions/edit/edit_event_logic.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_form_router.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit_style.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  final bool embedded;
  final VoidCallback? onSaved;

  const EditEventScreen({
    super.key,
    required this.event,
    this.embedded = false,
    this.onSaved,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends EditEventLogic<EditEventScreen>
    implements EventDialogs {
  bool _initialized = false;
  final _clientsApi = ClientsApi();
  final _servicesApi = ServiceApi();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initializeLogic();
  }

  Future<void> _initializeLogic() async {
    final groupDomain = context.read<GroupDomain>();
    final userDomain = context.read<UserDomain>();
    await initLogic(
      event: widget.event,
      gm: groupDomain,
      um: userDomain,
    );

    recomputeValidity();

    final group = groupDomain.currentGroup;
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

    recomputeValidity();
    if (mounted) setState(() {});
  }

  @override
  void afterSave() {
    if (widget.onSaved != null) {
      widget.onSaved!.call();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    disposeLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isEmbeddedWeb = widget.embedded && kIsWeb;

    final categoryApi = CategoryApi(
      baseUrl: ApiConstants.baseUrl,
      headersProvider: () => AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: true,
      ),
    );

    const outer = WorkVisitStyle.outerPadding;
    final runGap = WorkVisitStyle.sectionGap.height ?? 0.0;

    final body = isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding:
                isEmbeddedWeb ? const EdgeInsets.fromLTRB(0, 4, 0, 4) : outer,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 980 : double.infinity,
                ),
                child: Wrap(
                  runSpacing: runGap,
                  children: [
                    _FullWidth(
                      child: EventFormRouter(
                        logic: this,
                        onSubmit: () =>
                            saveEditedEvent(context.read<EventDomain>()),
                        ownerUserId: context.read<UserDomain>().user!.id,
                        categoryApi: categoryApi,
                        isEditing: true,
                        dialogs: this,
                      ),
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
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(
          l.editEvent,
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

  @override
  void showErrorDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.event),
        content: Text(AppLocalizations.of(context)!.errorEventCreation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
    return Navigator.of(context).push<List<Object?>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => RepetitionScreen(
          selectedStartDate: selectedStartDate,
          selectedEndDate: selectedEndDate,
          initialRecurrenceRule: initialRule,
        ),
      ),
    );
  }
}

class _FullWidth extends StatelessWidget {
  final Widget child;

  const _FullWidth({required this.child});

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
