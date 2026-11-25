import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/weather/weather_service.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/widgets/home_banking_charts.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/home/dashboard_preview/business_profile_card.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/shared/widgets/avatars/pulsing_ring_avatar.dart';
import 'package:provider/provider.dart';

/// A standalone, pixel-faithful preview of a proposed "home dashboard" design
/// (left sidebar + top bar + content panels), opened from Settings.
///
/// It reads REAL data where the app already exposes it (invoice counts,
/// client count, recent private documents and upcoming calendar events) and
/// falls back to representative mock data for a section when its source is
/// empty or unavailable. The chrome (sidebar/top bar) and the quick-action
/// tiles are visual only — this screen is a design preview, not wired
/// navigation.
class DashboardPreviewScreen extends StatefulWidget {
  const DashboardPreviewScreen({
    super.key,
    this.embedded = false,
    this.onOpenSection,
    this.onAskHexora,
    this.onOpenAssistant,
    this.onOpenBillingProfile,
  });

  /// When true the screen renders only the dashboard content (no Scaffold,
  /// sidebar, top bar or back ribbon) so it can sit inside the workspace shell,
  /// which already provides its own module rail and top bar.
  final bool embedded;
  final ValueChanged<String>? onOpenSection;
  final void Function(String text, List<Map<String, dynamic>> selectedCharts)?
      onAskHexora;
  final VoidCallback? onOpenAssistant;

  /// Opens the existing billing profile (fiscal data) editor.
  final VoidCallback? onOpenBillingProfile;

  @override
  State<DashboardPreviewScreen> createState() => _DashboardPreviewScreenState();
}

// ===== Accent palette (semantic colours, identical in light and dark) =====
class _Palette {
  static const blue = Color(0xFF2F6BFF);
  static const green = Color(0xFF17B26A);
  static const amber = Color(0xFFF5A524);
  static const purple = Color(0xFF7C5CFC);
}

// ===== Neutral tones, resolved from the active theme brightness =====
class _Tone {
  const _Tone({
    required this.scaffold,
    required this.surface,
    required this.heroBg,
    required this.inputBg,
    required this.hover,
    required this.navy,
    required this.ink,
    required this.muted,
    required this.border,
    required this.borderHover,
    required this.sidebarActive,
  });

  final Color scaffold;
  final Color surface;
  final Color heroBg;
  final Color inputBg;
  final Color hover;
  final Color navy;
  final Color ink;
  final Color muted;
  final Color border;
  final Color borderHover;
  final Color sidebarActive;

  static const _light = _Tone(
    scaffold: Color(0xFFF1F5FB),
    surface: Colors.white,
    heroBg: Color(0xFFE7EFFC),
    inputBg: Color(0xFFF4F7FD),
    hover: Color(0xFFF6F9FE),
    navy: Color(0xFF1B2A4A),
    ink: Color(0xFF1C2435),
    muted: Color(0xFF6B7489),
    border: Color(0xFFE1E8F2),
    borderHover: Color(0xFFC5D4EC),
    sidebarActive: Color(0xFFEAF1FF),
  );

  static const _dark = _Tone(
    scaffold: Color(0xFF0E1420),
    surface: Color(0xFF161E2C),
    heroBg: Color(0xFF17233A),
    inputBg: Color(0xFF1B2434),
    hover: Color(0xFF1C2637),
    navy: Color(0xFFE6ECF7),
    ink: Color(0xFFDCE3EF),
    muted: Color(0xFF94A0B6),
    border: Color(0xFF263247),
    borderHover: Color(0xFF3A4B69),
    sidebarActive: Color(0xFF1E2B45),
  );

  static _Tone of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

class _DashData {
  const _DashData({
    required this.facturas,
    required this.pagadas,
    required this.pendientes,
    required this.clientes,
    required this.activity,
    required this.tasks,
    required this.docs,
    required this.statsAreMock,
  });

  final int facturas;
  final int pagadas;
  final int pendientes;
  final int clientes;
  final List<_ActivityItem> activity;
  final List<_TaskItem> tasks;
  final List<_DocItem> docs;
  final bool statsAreMock;
}

class _ActivityItem {
  const _ActivityItem(
      this.title, this.subtitle, this.when, this.icon, this.color);
  final String title;
  final String subtitle;
  final DateTime? when;
  final IconData icon;
  final Color color;
}

class _TaskItem {
  const _TaskItem(this.title, this.date, this.color);
  final String title;
  final DateTime date;
  final Color color;
}

class _DocItem {
  const _DocItem(this.title, this.subtitle, this.when);
  final String title;
  final String subtitle;
  final DateTime? when;
}

class _DashboardPreviewScreenState extends State<DashboardPreviewScreen> {
  final _weatherService = WeatherService();
  late Future<_DashData> _future;
  Future<WeatherBundle>? _weather;
  final Map<String, Map<String, dynamic>> _selectedCharts = {};
  String? _selectedChartGroupId;

  void _updateChartSelection(String id, Map<String, dynamic>? chart) {
    setState(() {
      if (chart == null) {
        _selectedCharts.remove(id);
      } else {
        _selectedCharts[id] = chart;
      }
    });
  }

  void _askHexora(String text) {
    widget.onAskHexora?.call(text, _selectedCharts.values.toList());
  }

  bool get _isEs => Localizations.localeOf(context).languageCode == 'es';

  void _openSection(String section) {
    final callback = widget.onOpenSection;
    if (callback != null) {
      callback(section);
      return;
    }
    final group = context.read<GroupDomain>().currentGroup;
    if (group == null) return;
    final route = switch (section) {
      Sections.invoices => AppRoutes.groupIncome,
      Sections.budgets => AppRoutes.groupIncome,
      Sections.expenses => AppRoutes.groupExpenses,
      Sections.services => AppRoutes.groupServicesClients,
      Sections.calendar => AppRoutes.groupCalendar,
      Sections.enableBanking => AppRoutes.enableBanking,
      _ => null,
    };
    if (route != null) {
      Navigator.of(context).pushNamed(route, arguments: group);
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _weatherService.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.embedded || _weather != null) return;
    final user = context.read<AuthService>().currentUser;
    final location = user?.location?.trim();
    _weather = location == null || location.isEmpty
        ? Future.value(const WeatherBundle(today: null, forecast: []))
        : _weatherService.fetchWeatherBundle(location: location, days: 1);
  }

  Future<_DashData> _load() async {
    final groupDomain = context.read<GroupDomain>();
    final eventDomain = context.read<EventDomain?>();
    final groupId = groupDomain.currentGroup?.id;

    int facturas = 0, pagadas = 0, pendientes = 0, clientes = 0;
    final activity = <_ActivityItem>[];
    final docs = <_DocItem>[];
    bool statsLoaded = false;

    if (groupId != null && groupId.isNotEmpty) {
      // Invoices
      try {
        final invoices = await InvoicesApi().listByGroup(groupId);
        facturas = invoices.length;
        pagadas = invoices.where((i) {
          final ps = (i.paymentStatus ?? '').toLowerCase();
          return ps == 'paid' || ps == 'pagada' || (i.paidAmount ?? 0) > 0;
        }).length;
        pendientes = facturas - pagadas;
        statsLoaded = facturas > 0;

        final recent = [...invoices]..sort((a, b) =>
            (b.issueDate ?? DateTime(0)).compareTo(a.issueDate ?? DateTime(0)));
        for (final inv in recent.take(4)) {
          final number = inv.invoiceNumber.trim();
          final client = (inv.clientName ?? '').trim();
          activity.add(_ActivityItem(
            _isEs ? 'Factura creada' : 'Invoice created',
            [if (number.isNotEmpty) '#$number', if (client.isNotEmpty) client]
                .join(' · '),
            inv.issueDate,
            Icons.description_rounded,
            _Palette.blue,
          ));
        }
      } catch (_) {/* fall back below */}

      // Clients
      try {
        final list = await ClientsApi().list(groupId: groupId);
        clientes = list.length;
        statsLoaded = statsLoaded || clientes > 0;
      } catch (_) {}

      // Documents
      try {
        final list = await PrivateDocumentsApi().list(groupId: groupId);
        final sorted = [...list]..sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        for (final d in sorted.take(3)) {
          docs.add(_DocItem(d.displayTitle, d.category, d.createdAt));
        }
      } catch (_) {}
    }

    // Upcoming calendar events (already loaded in the EventDomain, if any).
    final tasks = <_TaskItem>[];
    final events = eventDomain?.eventsNotifier.value ?? const <Event>[];
    final now = DateTime.now();
    final upcoming = events
        .where((e) => !e.isCompleted && e.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    const taskColors = [
      _Palette.blue,
      _Palette.green,
      _Palette.amber,
      _Palette.purple
    ];
    for (var i = 0; i < upcoming.take(4).length; i++) {
      final e = upcoming[i];
      tasks.add(_TaskItem(e.title, e.startDate, taskColors[i % 4]));
    }

    final statsAreMock = !statsLoaded;
    return _DashData(
      facturas: statsLoaded ? facturas : 410,
      pagadas: statsLoaded ? pagadas : 286,
      pendientes: statsLoaded ? pendientes : 124,
      clientes: statsLoaded ? clientes : 87,
      activity: activity.isNotEmpty ? activity : _mockActivity(),
      tasks: tasks.isNotEmpty ? tasks : _mockTasks(),
      docs: docs.isNotEmpty ? docs : _mockDocs(),
      statsAreMock: statsAreMock,
    );
  }

  List<_ActivityItem> _mockActivity() {
    final es = _isEs;
    final now = DateTime.now();
    return [
      _ActivityItem(
          es ? 'Factura creada' : 'Invoice created',
          '#410-26 · Residencial Zurich',
          now,
          Icons.description_rounded,
          _Palette.blue),
      _ActivityItem(
          es ? 'Pago registrado' : 'Payment recorded',
          '#408-26 · Playasol II',
          now,
          Icons.check_circle_rounded,
          _Palette.green),
      _ActivityItem(
          es ? 'Presupuesto enviado' : 'Quote sent',
          '#P-120 · Brisas',
          now.subtract(const Duration(days: 1)),
          Icons.receipt_long_rounded,
          _Palette.purple),
      _ActivityItem(
          es ? 'Nuevo cliente' : 'New client',
          'Camos Molla Promociones',
          now.subtract(const Duration(days: 1)),
          Icons.person_add_alt_1_rounded,
          _Palette.amber),
    ];
  }

  List<_TaskItem> _mockTasks() {
    final es = _isEs;
    final d = DateTime.now();
    DateTime at(int add) =>
        DateTime(d.year, d.month, d.day).add(Duration(days: add));
    return [
      _TaskItem(
          es ? 'Mantenimiento piscina – Brisas' : 'Pool maintenance – Brisas',
          at(1),
          _Palette.blue),
      _TaskItem(
          es ? 'Revisión de riego – La Sella' : 'Irrigation check – La Sella',
          at(1),
          _Palette.green),
      _TaskItem(
          es
              ? 'Enviar presupuesto – Cabo del Sol'
              : 'Send quote – Cabo del Sol',
          at(2),
          _Palette.amber),
      _TaskItem(
          es ? 'Seguimiento de factura #407-26' : 'Follow up invoice #407-26',
          at(3),
          _Palette.purple),
    ];
  }

  List<_DocItem> _mockDocs() {
    final es = _isEs;
    final now = DateTime.now();
    return [
      _DocItem(es ? 'Factura #410-26' : 'Invoice #410-26', 'Residencial Zurich',
          now),
      _DocItem(es ? 'Presupuesto #P-120' : 'Quote #P-120', 'Brisas',
          now.subtract(const Duration(days: 1))),
      _DocItem(es ? 'Recibo #R025-26' : 'Receipt #R025-26', 'Playasol II',
          now.subtract(const Duration(days: 1))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final groupId = context.read<GroupDomain>().currentGroup?.id;
    if (_selectedChartGroupId != groupId) {
      _selectedCharts.clear();
      _selectedChartGroupId = groupId;
    }

    if (widget.embedded) {
      return Container(
        color: _Tone.of(context).scaffold,
        child: FutureBuilder<_DashData>(
          future: _future,
          builder: (context, snap) {
            final data = snap.data;
            final loading = snap.connectionState != ConnectionState.done;
            return _Content(
              isEs: es,
              data: data,
              loading: loading,
              onOpenSection: _openSection,
              onAskHexora: widget.onAskHexora == null ? null : _askHexora,
              onOpenAssistant: widget.onOpenAssistant,
              onOpenBillingProfile: widget.onOpenBillingProfile,
              selectedCharts: _selectedCharts,
              onChartSelectionChanged: _updateChartSelection,
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: _Tone.of(context).scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewRibbon(
                isEs: es, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 900;
                  return FutureBuilder<_DashData>(
                    future: _future,
                    builder: (context, snap) {
                      final data = snap.data;
                      final loading =
                          snap.connectionState != ConnectionState.done;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Sidebar(isEs: es, onOpenSection: _openSection),
                            Expanded(
                              child: Column(
                                children: [
                                  _TopBar(
                                      isEs: es, weather: _weather!, wide: true),
                                  Expanded(
                                    child: _Content(
                                        isEs: es,
                                        data: data,
                                        loading: loading,
                                        onOpenSection: _openSection,
                                        onAskHexora: widget.onAskHexora == null
                                            ? null
                                            : _askHexora,
                                        onOpenAssistant: widget.onOpenAssistant,
                                        onOpenBillingProfile:
                                            widget.onOpenBillingProfile,
                                        selectedCharts: _selectedCharts,
                                        onChartSelectionChanged:
                                            _updateChartSelection),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _TopBar(isEs: es, weather: _weather!, wide: false),
                          Expanded(
                            child: _Content(
                                isEs: es,
                                data: data,
                                loading: loading,
                                onOpenSection: _openSection,
                                onAskHexora: widget.onAskHexora == null
                                    ? null
                                    : _askHexora,
                                onOpenAssistant: widget.onOpenAssistant,
                                onOpenBillingProfile:
                                    widget.onOpenBillingProfile,
                                selectedCharts: _selectedCharts,
                                onChartSelectionChanged: _updateChartSelection),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Preview ribbon (back affordance) =====================
class _PreviewRibbon extends StatelessWidget {
  const _PreviewRibbon({required this.isEs, required this.onBack});
  final bool isEs;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Tone.of(context).navy,
      child: InkWell(
        onTap: onBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                isEs ? 'Vista previa del panel' : 'Dashboard preview',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                isEs ? 'Volver' : 'Back',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Sidebar =====================
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.isEs, required this.onOpenSection});
  final bool isEs;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final items = <_NavDef>[
      _NavDef(Icons.home_rounded, isEs ? 'Inicio' : 'Home',
          active: true, section: Sections.home),
      _NavDef(Icons.groups_rounded, isEs ? 'Clientes' : 'Clients',
          section: Sections.services),
      _NavDef(Icons.description_rounded, isEs ? 'Facturas' : 'Invoices',
          expandable: true, section: Sections.invoices),
      _NavDef(Icons.receipt_rounded, isEs ? 'Recibos' : 'Receipts',
          expandable: true, section: Sections.invoices),
      _NavDef(Icons.request_quote_rounded, isEs ? 'Presupuestos' : 'Quotes',
          expandable: true, section: Sections.budgets),
      _NavDef(Icons.payments_rounded, isEs ? 'Gastos' : 'Expenses',
          expandable: true, section: Sections.expenses),
      _NavDef(Icons.account_balance_rounded, isEs ? 'Banco' : 'Bank',
          section: Sections.enableBanking),
      _NavDef(Icons.calendar_today_rounded, isEs ? 'Calendario' : 'Calendar',
          section: Sections.calendar),
      _NavDef(Icons.bar_chart_rounded, isEs ? 'Informes' : 'Reports'),
      _NavDef(Icons.folder_rounded, isEs ? 'Documentos' : 'Documents'),
    ];

    return Container(
      width: 212,
      decoration: BoxDecoration(
        color: _Tone.of(context).surface,
        border: Border(right: BorderSide(color: _Tone.of(context).border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _Tone.of(context).navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hexagon_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Hexora',
                    style: TextStyle(
                        color: _Tone.of(context).navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: _Tone.of(context).muted, size: 18),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final it in items)
                  _NavRow(
                      def: it,
                      onTap: it.section == null
                          ? null
                          : () => onOpenSection(it.section!)),
              ],
            ),
          ),
          Divider(height: 1, color: _Tone.of(context).border),
          _NavRow(
              def: _NavDef(
                  Icons.settings_rounded, isEs ? 'Configuración' : 'Settings')),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavDef {
  _NavDef(this.icon, this.label,
      {this.active = false, this.expandable = false, this.section});
  final IconData icon;
  final String label;
  final bool active;
  final bool expandable;
  final String? section;
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.def, this.onTap});
  final _NavDef def;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = def.active ? _Palette.blue : _Tone.of(context).ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color:
              def.active ? _Tone.of(context).sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(def.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(def.label,
                    style: TextStyle(
                        color: color,
                        fontWeight:
                            def.active ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14)),
              ),
              if (def.expandable)
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: _Tone.of(context).muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Top bar =====================
class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.isEs, required this.weather, required this.wide});
  final bool isEs;
  final Future<WeatherBundle> weather;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final group = context.read<GroupDomain>().currentGroup;
    final user = context.read<AuthService>().currentUser;
    final businessName = (group?.name.trim().isNotEmpty ?? false)
        ? group!.name.trim()
        : (isEs ? 'Tu negocio' : 'Your business');

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: _Tone.of(context).surface,
        border: Border(bottom: BorderSide(color: _Tone.of(context).border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!wide) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: _Tone.of(context).navy,
                  borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.hexagon_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Tone.of(context).border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                      radius: 11,
                      backgroundColor: _Tone.of(context).sidebarActive,
                      child: const Icon(Icons.business_rounded,
                          size: 13, color: _Palette.blue)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(businessName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _Tone.of(context).ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: _Tone.of(context).muted),
                ],
              ),
            ),
          ),
          const Spacer(),
          _WeatherChip(weather: weather, isEs: isEs),
          const SizedBox(width: 10),
          const _TopIcon(Icons.notifications_none_rounded, badge: true),
          const SizedBox(width: 6),
          const _TopIcon(Icons.help_outline_rounded),
          const SizedBox(width: 10),
          Tooltip(
            message: isEs ? 'Tu perfil está activo' : 'Your profile is active',
            child: PulsingRingAvatar(
              radius: 14,
              image: AvatarUtils.profileImageProvider(
                user?.photoUrl,
                assetFallback: 'assets/images/default_profile.png',
              ),
              isOnline: true,
              onlineColor: _Palette.blue,
              offlineBorderColor: _Tone.of(context).border,
              backgroundColor: _Tone.of(context).sidebarActive,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon(this.icon, {this.badge = false});
  final IconData icon;
  final bool badge;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _Tone.of(context).scaffold,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: _Tone.of(context).ink),
        ),
        if (badge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: _Palette.blue, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.weather, required this.isEs});
  final Future<WeatherBundle> weather;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherBundle>(
      future: weather,
      builder: (context, snap) {
        final today = snap.data?.today;
        final temp = today?.tempMax;
        final city = today?.cityName ??
            (isEs ? 'Configura tu ubicación' : 'Set your location');
        final desc = today?.summary.summary ??
            (isEs ? 'Perfil → Ubicación' : 'Profile → Location');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _Tone.of(context).scaffold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_rounded, size: 20, color: _Palette.amber),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    temp != null ? '${temp.round()}°C  $desc' : desc,
                    style: TextStyle(
                        color: _Tone.of(context).ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5),
                  ),
                  Text('$city, ${isEs ? 'España' : 'Spain'}',
                      style: TextStyle(
                          color: _Tone.of(context).muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================== Content =====================
class _Content extends StatelessWidget {
  const _Content(
      {required this.isEs,
      required this.data,
      required this.loading,
      required this.selectedCharts,
      required this.onChartSelectionChanged,
      this.onOpenSection,
      this.onAskHexora,
      this.onOpenAssistant,
      this.onOpenBillingProfile});
  final bool isEs;
  final _DashData? data;
  final bool loading;
  final ValueChanged<String>? onOpenSection;
  final ValueChanged<String>? onAskHexora;
  final VoidCallback? onOpenAssistant;
  final VoidCallback? onOpenBillingProfile;
  final Map<String, Map<String, dynamic>> selectedCharts;
  final void Function(String id, Map<String, dynamic>? chart)
      onChartSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final group = context.read<GroupDomain>().currentGroup;
    // Banking automation is an entitlement for automated workflows, not a
    // visibility rule for bank data that already belongs to the business.
    // When the dashboard assistant is available, let the scoped statements
    // request decide whether there is anything to render.
    final showBankingCharts = onAskHexora != null;
    String name = 'Michael';
    if (user != null) {
      if (user.name.trim().isNotEmpty) {
        name = user.name.trim();
      } else if (user.userName.trim().isNotEmpty) {
        name = user.userName.trim();
      }
    }

    return LayoutBuilder(builder: (context, c) {
      final twoCol = c.maxWidth >= 760;
      // Major section gap (spec: 12–16 px).
      const gap = 14.0;
      return ListView(
        padding: EdgeInsets.all(twoCol ? 16 : 12),
        children: [
          _GreetingHero(isEs: isEs, name: name),
          if (group != null) ...[
            const SizedBox(height: 12),
            // Watches the selected business so saves and business switches
            // are reflected immediately; keyed by id so no stale state from
            // another business is kept.
            Consumer<GroupDomain>(
              builder: (context, groups, _) {
                final current = groups.currentGroup ?? group;
                return BusinessProfileCard(
                  key: ValueKey('business-profile-${current.id}'),
                  group: current,
                  currentUserId: user?.id,
                  isEs: isEs,
                  onOpenSettings: onOpenSection == null
                      ? null
                      : () => onOpenSection!(Sections.settings),
                  onOpenBillingProfile: onOpenBillingProfile,
                );
              },
            ),
          ],
          if (onAskHexora != null) ...[
            const SizedBox(height: 12),
            _AskHexoraBar(
              isEs: isEs,
              onSubmit: onAskHexora!,
              onOpenAssistant: onOpenAssistant,
              selectedChartCount: selectedCharts.length,
            ),
          ],
          const SizedBox(height: gap),
          _StatRow(
              isEs: isEs,
              data: data,
              loading: loading,
              onOpenSection: onOpenSection),
          const SizedBox(height: gap),
          _QuickActions(isEs: isEs, onOpenSection: onOpenSection),
          const SizedBox(height: gap),
          if (showBankingCharts && group != null) ...[
            HomeBankingCharts(
              key: ValueKey('home-banking-charts-${group.id}'),
              groupId: group.id,
              onOpenBanking: () => onOpenSection?.call(Sections.enableBanking),
              selectedChartIds: selectedCharts.keys.toSet(),
              onSelectionChanged: onChartSelectionChanged,
            ),
            const SizedBox(height: gap),
          ],
          if (twoCol)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _RecentActivity(
                          isEs: isEs,
                          data: data,
                          onOpenSection: onOpenSection)),
                  const SizedBox(width: gap),
                  Expanded(
                      child: _UpcomingTasks(
                          isEs: isEs,
                          data: data,
                          onOpenSection: onOpenSection)),
                ],
              ),
            )
          else ...[
            _RecentActivity(
                isEs: isEs, data: data, onOpenSection: onOpenSection),
            const SizedBox(height: gap),
            _UpcomingTasks(
                isEs: isEs, data: data, onOpenSection: onOpenSection),
          ],
          const SizedBox(height: gap),
          if (twoCol)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RecentDocs(isEs: isEs, data: data)),
                  const SizedBox(width: gap),
                  Expanded(child: _ThisWeek(isEs: isEs, data: data)),
                ],
              ),
            )
          else ...[
            _RecentDocs(isEs: isEs, data: data),
            const SizedBox(height: gap),
            _ThisWeek(isEs: isEs, data: data),
          ],
          const SizedBox(height: 16),
        ],
      );
    });
  }
}

class _AskHexoraBar extends StatefulWidget {
  const _AskHexoraBar({
    required this.isEs,
    required this.onSubmit,
    required this.selectedChartCount,
    this.onOpenAssistant,
  });

  final bool isEs;
  final ValueChanged<String> onSubmit;
  final int selectedChartCount;
  final VoidCallback? onOpenAssistant;

  @override
  State<_AskHexoraBar> createState() => _AskHexoraBarState();
}

class _AskHexoraBarState extends State<_AskHexoraBar> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _onKeyEvent);
  bool _submitting = false;

  bool get _canSubmit => !_submitting && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Enter submits; Shift+Enter falls through to the field and inserts a new
  /// line. Handled on the field's own focus node so it runs before the text
  /// input system turns Enter into a newline.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    // Let an active IME composition (e.g. accents) confirm first.
    if (_controller.value.composing.isValid &&
        !_controller.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    _submit();
    return KeyEventResult.handled;
  }

  void _submit([String? suggestedPrompt]) {
    if (_submitting) return;
    final prompt = (suggestedPrompt ?? _controller.text).trim();
    if (prompt.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    setState(() => _submitting = true);
    _controller.clear();
    widget.onSubmit(prompt);
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _submitting = false);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = _Tone.of(context);
    final focused = _focusNode.hasFocus;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final functionalSurface = isDark ? tone.inputBg : const Color(0xFFF1F5FB);
    final functionalBorder = isDark ? tone.border : const Color(0xFFDCE5F2);
    final suggestions = <({String label, String prompt, IconData icon})>[
      (
        label: widget.isEs ? 'Facturas pendientes' : 'Pending invoices',
        prompt: widget.isEs
            ? 'Muéstrame las facturas pendientes'
            : 'Show me pending invoices',
        icon: LucideIcons.receiptText,
      ),
      (
        label:
            widget.isEs ? 'Movimientos sin vincular' : 'Unlinked transactions',
        prompt: widget.isEs
            ? 'Muéstrame los movimientos sin vincular'
            : 'Show me unlinked transactions',
        icon: LucideIcons.unlink,
      ),
      (
        label: widget.isEs ? 'Crear una visita' : 'Create a visit',
        prompt: widget.isEs
            ? 'Ayúdame a crear una visita'
            : 'Help me create a visit',
        icon: LucideIcons.calendarPlus,
      ),
      (
        label: widget.isEs ? 'Resumen financiero' : 'Financial summary',
        prompt: widget.isEs
            ? 'Muéstrame un resumen financiero'
            : 'Show me a financial summary',
        icon: LucideIcons.chartNoAxesCombined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          LayoutBuilder(builder: (context, c) {
            final showActionLabel = c.maxWidth >= 460;
            return Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(LucideIcons.sparkles, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEs ? 'Pregunta a Hexora' : 'Ask Hexora',
                        style: TextStyle(
                          color: tone.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.isEs
                            ? 'Consulta información o recibe ayuda con tus tareas.'
                            : 'Get information or help with your tasks.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tone.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.onOpenAssistant != null) ...[
                  const SizedBox(width: 8),
                  if (showActionLabel)
                    OutlinedButton.icon(
                      onPressed: widget.onOpenAssistant,
                      icon: const Icon(LucideIcons.arrowUpRight, size: 15),
                      label: Text(
                          widget.isEs ? 'Abrir asistente' : 'Open assistant'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.standard,
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: widget.onOpenAssistant,
                      tooltip:
                          widget.isEs ? 'Abrir asistente' : 'Open assistant',
                      icon: const Icon(LucideIcons.arrowUpRight, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ],
            );
          }),
          const SizedBox(height: 14),
          if (widget.selectedChartCount > 0) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Icon(LucideIcons.chartNoAxesCombined,
                    size: 15, color: cs.primary),
                Text(
                  widget.isEs
                      ? '${widget.selectedChartCount} gráficos seleccionados para el chat'
                      : '${widget.selectedChartCount} charts selected for chat',
                  style: TextStyle(color: tone.ink, fontSize: 12.5),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => _submit(widget.isEs
                          ? 'Explica los gráficos seleccionados y los cambios más importantes.'
                          : 'Explain the selected charts and the most important changes.'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                      widget.isEs ? 'Explicar gráficos' : 'Explain charts'),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          LayoutBuilder(builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 850;
            const columnGap = 22.0;
            final composerWidth = twoColumns
                ? (constraints.maxWidth - columnGap) * .60
                : constraints.maxWidth;
            final suggestionsWidth = twoColumns
                ? (constraints.maxWidth - columnGap) * .40
                : constraints.maxWidth;
            final showKeyboardHint = MediaQuery.sizeOf(context).width >= 700;
            return Wrap(
              spacing: columnGap,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: composerWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (twoColumns) ...[
                        const SizedBox(height: 15),
                        const SizedBox(height: 7),
                      ],
                      AnimatedContainer(
                        duration:
                            _motion(context, const Duration(milliseconds: 150)),
                        curve: Curves.easeOut,
                        constraints: BoxConstraints(
                          minHeight: twoColumns ? 88 : 80,
                          maxHeight: 140,
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                        decoration: BoxDecoration(
                          color: functionalSurface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: focused ? cs.primary : functionalBorder,
                          ),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: .08),
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                right: 48,
                                bottom: showKeyboardHint ? 20 : 0,
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                enabled: !_submitting,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                  color: tone.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: widget.isEs
                                      ? 'Pregunta algo o pide ayuda con una tarea...'
                                      : 'Ask something or get help with a task...',
                                  hintStyle: TextStyle(
                                      color: tone.muted, fontSize: 14),
                                ),
                              ),
                            ),
                            if (showKeyboardHint)
                              Positioned(
                                left: 0,
                                bottom: 2,
                                child: Text(
                                  widget.isEs
                                      ? 'Enter para enviar · Mayús + Enter para una nueva línea'
                                      : 'Enter to send · Shift + Enter for a new line',
                                  style: TextStyle(
                                    color: tone.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filled(
                                tooltip: widget.isEs
                                    ? 'Enviar (Enter) · Nueva línea (Mayús+Enter)'
                                    : 'Send (Enter) · New line (Shift+Enter)',
                                onPressed: _canSubmit ? _submit : null,
                                icon: _submitting
                                    ? SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.onPrimary,
                                        ),
                                      )
                                    : const Icon(LucideIcons.arrowUp, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  disabledBackgroundColor: _submitting
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: .08),
                                  disabledForegroundColor: _submitting
                                      ? cs.onPrimary
                                      : cs.onSurface.withValues(alpha: .38),
                                  minimumSize: const Size.square(36),
                                  fixedSize: const Size.square(36),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: suggestionsWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isEs ? 'Prueba a preguntar' : 'Try asking',
                        style: TextStyle(
                            color: tone.navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 7),
                      LayoutBuilder(builder: (context, c) {
                        final columns = c.maxWidth >= 380 ? 2 : 1;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in suggestions)
                              SizedBox(
                                width:
                                    (c.maxWidth - (columns - 1) * 8) / columns,
                                child: Tooltip(
                                  message: s.prompt,
                                  child: _SuggestionChip(
                                    icon: s.icon,
                                    label: s.label,
                                    backgroundColor: functionalSurface,
                                    borderColor: functionalBorder,
                                    onTap: _submitting
                                        ? null
                                        : () => _submit(s.prompt),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: _HoverSurface(
        onTap: onTap,
        radius: 9,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        semanticLabel: label,
        idleColor: backgroundColor,
        idleBorderColor: borderColor,
        hoverForeground: cs.primary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.arrowUpRight, size: 13),
          ],
        ),
      ),
    );
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.isEs, required this.name});
  final bool isEs;
  final String name;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(context);
    final hour = DateTime.now().hour;
    final greeting = isEs
        ? (hour < 12
            ? 'Buenos días'
            : hour < 20
                ? 'Buenas tardes'
                : 'Buenas noches')
        : (hour < 12
            ? 'Good morning'
            : hour < 20
                ? 'Good afternoon'
                : 'Good evening');

    final date = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.calendar, size: 14, color: _Palette.blue),
          const SizedBox(width: 7),
          Text(
            _formatLongDate(DateTime.now(), isEs),
            style: TextStyle(
              color: tone.ink,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      final stackDate = c.maxWidth < 600;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tone.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: stackDate ? 19 : 21,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEs
                        ? 'Aquí tienes un resumen de la actividad de tu negocio.'
                        : "Here's a summary of your business activity.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tone.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (stackDate) ...[const SizedBox(height: 5), date],
                ],
              ),
            ),
            if (!stackDate) ...[const SizedBox(width: 12), date],
          ],
        ),
      );
    });
  }
}

/// Motion duration that collapses to zero when the platform asks for reduced
/// motion.
Duration _motion(BuildContext context, Duration d) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : d;

/// Shared clickable surface for the home: white card, subtle border, light
/// hover tint + border change, visible keyboard focus ring, pointer cursor.
class _HoverSurface extends StatefulWidget {
  const _HoverSurface({
    required this.child,
    this.onTap,
    this.radius = 12,
    this.padding = const EdgeInsets.all(12),
    this.semanticLabel,
    this.idleColor,
    this.idleBorderColor,
    this.hoverForeground,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Color? idleColor;
  final Color? idleBorderColor;
  final Color? hoverForeground;

  @override
  State<_HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<_HoverSurface> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(context);
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final hovered = enabled && _hover;
    final radius = BorderRadius.circular(widget.radius);

    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: _motion(context, const Duration(milliseconds: 150)),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: hovered ? tone.hover : (widget.idleColor ?? tone.surface),
          borderRadius: radius,
          border: Border.all(
            color: _focus
                ? cs.primary
                : hovered
                    ? tone.borderHover
                    : (widget.idleBorderColor ?? tone.border),
          ),
          boxShadow: _focus
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: .18),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onHover: (v) => setState(() => _hover = v),
            onFocusChange: (v) => setState(() => _focus = v),
            child: Padding(
              padding: widget.padding,
              child: IconTheme.merge(
                data: IconThemeData(
                  color: hovered ? widget.hoverForeground : tone.ink,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: hovered ? widget.hoverForeground : tone.ink,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.isEs,
      required this.data,
      required this.loading,
      this.onOpenSection});
  final bool isEs;
  final _DashData? data;
  final bool loading;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
          label: isEs ? 'Facturas' : 'Invoices',
          value: data?.facturas,
          icon: LucideIcons.fileText,
          color: _Palette.blue,
          onTap: () => onOpenSection?.call(Sections.invoices),
          loading: loading),
      _StatCard(
          label: isEs ? 'Pagadas' : 'Paid',
          value: data?.pagadas,
          icon: LucideIcons.circleCheck,
          color: _Palette.green,
          onTap: () => onOpenSection?.call(Sections.invoices),
          loading: loading),
      _StatCard(
          label: isEs ? 'Pendientes' : 'Pending',
          value: data?.pendientes,
          icon: LucideIcons.clock,
          color: _Palette.amber,
          onTap: () => onOpenSection?.call(Sections.invoices),
          loading: loading),
      _StatCard(
          label: isEs ? 'Clientes' : 'Clients',
          value: data?.clientes,
          icon: LucideIcons.users,
          color: _Palette.purple,
          onTap: () => onOpenSection?.call(Sections.services),
          loading: loading),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 720 ? 4 : 2;
      const gap = 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final card in cards) SizedBox(width: w, child: card)],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.loading,
      this.onTap});
  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(context);
    return _HoverSurface(
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      semanticLabel: '$label ${value ?? ''}',
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: tone.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
                SizedBox(
                  height: 27,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('${value ?? 0}',
                            style: TextStyle(
                                color: tone.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                height: 1.1)),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(LucideIcons.chevronRight, size: 16, color: tone.muted),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isEs, this.onOpenSection});
  final bool isEs;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final actions = <_QA>[
      _QA(LucideIcons.filePlus, isEs ? 'Nueva factura' : 'New invoice',
          _Palette.blue, Sections.invoices),
      _QA(LucideIcons.receipt, isEs ? 'Nuevo recibo' : 'New receipt',
          _Palette.purple, Sections.invoices),
      _QA(LucideIcons.clipboardList, isEs ? 'Nuevo presupuesto' : 'New quote',
          _Palette.green, Sections.budgets),
      _QA(LucideIcons.wallet, isEs ? 'Registrar gasto' : 'Log expense',
          _Palette.amber, Sections.expenses),
      _QA(LucideIcons.userPlus, isEs ? 'Crear cliente' : 'New client',
          _Palette.blue, Sections.services),
      _QA(LucideIcons.calendarPlus, isEs ? 'Nueva tarea' : 'New task',
          _Palette.purple, Sections.calendar),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(isEs ? 'Accesos rápidos' : 'Quick actions'),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, c) {
          // One row of six on wide desktops, three columns on desktop/tablet,
          // two on phones.
          final cols = c.maxWidth >= 1200
              ? 6
              : c.maxWidth >= 560
                  ? 3
                  : 2;
          const gap = 10.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final a in actions)
                SizedBox(
                    width: w,
                    child: _QuickActionTile(
                        qa: a,
                        onTap: onOpenSection == null
                            ? null
                            : () => onOpenSection!(a.section))),
            ],
          );
        }),
      ],
    );
  }
}

class _QA {
  _QA(this.icon, this.label, this.color, this.section);
  final IconData icon;
  final String label;
  final Color color;
  final String section;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.qa, required this.onTap});
  final _QA qa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(context);
    return _HoverSurface(
      onTap: onTap,
      radius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      semanticLabel: qa.label,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: qa.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(qa.icon, color: qa.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(qa.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: tone.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ===================== Panels =====================
class _Panel extends StatelessWidget {
  const _Panel(
      {required this.title,
      required this.action,
      required this.child,
      this.onAction});
  final String title;
  final String action;
  final Widget child;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(title)),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(action,
                          style: const TextStyle(
                              color: _Palette.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                      const Icon(LucideIcons.chevronRight,
                          size: 14, color: _Palette.blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity(
      {required this.isEs, required this.data, this.onOpenSection});
  final bool isEs;
  final _DashData? data;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final items = data?.activity ?? const <_ActivityItem>[];
    return _Panel(
      title: isEs ? 'Actividad reciente' : 'Recent activity',
      action: isEs ? 'Ver todo' : 'See all',
      onAction: onOpenSection == null
          ? null
          : () => onOpenSection!(Sections.invoices),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: items[i].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(items[i].icon, color: items[i].color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          style: TextStyle(
                              color: _Tone.of(context).ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                      if (items[i].subtitle.isNotEmpty)
                        Text(items[i].subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _Tone.of(context).muted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_relTime(items[i].when, isEs),
                    style: TextStyle(
                        color: _Tone.of(context).muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _UpcomingTasks extends StatelessWidget {
  const _UpcomingTasks(
      {required this.isEs, required this.data, this.onOpenSection});
  final bool isEs;
  final _DashData? data;
  final ValueChanged<String>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final items = data?.tasks ?? const <_TaskItem>[];
    return _Panel(
      title: isEs ? 'Próximas tareas' : 'Upcoming tasks',
      action: isEs ? 'Ver calendario' : 'See calendar',
      onAction: onOpenSection == null
          ? null
          : () => onOpenSection!(Sections.calendar),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                    width: 4,
                    height: 34,
                    decoration: BoxDecoration(
                        color: items[i].color,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Icon(Icons.check_box_outline_blank_rounded,
                    size: 20, color: _Tone.of(context).muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(items[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _Tone.of(context).ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: _Tone.of(context).muted),
                    const SizedBox(width: 5),
                    Text(_shortDate(items[i].date, isEs),
                        style: TextStyle(
                            color: _Tone.of(context).muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RecentDocs extends StatelessWidget {
  const _RecentDocs({required this.isEs, required this.data});
  final bool isEs;
  final _DashData? data;

  @override
  Widget build(BuildContext context) {
    final items = data?.docs ?? const <_DocItem>[];
    return _Panel(
      title: isEs ? 'Documentos recientes' : 'Recent documents',
      action: isEs ? 'Ver todos' : 'See all',
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5484D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('PDF',
                      style: TextStyle(
                          color: Color(0xFFE5484D),
                          fontWeight: FontWeight.w800,
                          fontSize: 9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _Tone.of(context).ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                      Text(items[i].subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _Tone.of(context).muted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_relTime(items[i].when, isEs),
                    style: TextStyle(
                        color: _Tone.of(context).muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                Icon(Icons.more_horiz_rounded,
                    size: 18, color: _Tone.of(context).muted),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ThisWeek extends StatelessWidget {
  const _ThisWeek({required this.isEs, required this.data});
  final bool isEs;
  final _DashData? data;

  @override
  Widget build(BuildContext context) {
    final items = data?.tasks ?? const <_TaskItem>[];
    return _Panel(
      title: isEs ? 'Esta semana' : 'This week',
      action: _monthLabel(DateTime.now(), isEs),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(_weekdayDay(items[i].date, isEs),
                      style: TextStyle(
                          color: _Tone.of(context).navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: items[i].color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(items[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _Tone.of(context).ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: _Tone.of(context).navy,
          fontWeight: FontWeight.w600,
          fontSize: 15.5,
          letterSpacing: -.1));
}

// ===================== Date / time helpers =====================
const _esWeekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo'
];
const _esWeekdaysShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _enWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];
const _enWeekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _esMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre'
];
const _enMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

String _formatLongDate(DateTime d, bool isEs) {
  final wd = (isEs ? _esWeekdays : _enWeekdays)[d.weekday - 1];
  final m = (isEs ? _esMonths : _enMonths)[d.month - 1];
  return isEs
      ? '$wd, ${d.day} de $m de ${d.year}'
      : '$wd, $m ${d.day}, ${d.year}';
}

String _shortDate(DateTime d, bool isEs) {
  final wd = (isEs ? _esWeekdaysShort : _enWeekdaysShort)[d.weekday - 1];
  final m = (isEs ? _esMonths : _enMonths)[d.month - 1].substring(0, 3);
  return '$wd, ${d.day} $m';
}

String _weekdayDay(DateTime d, bool isEs) {
  final wd = (isEs ? _esWeekdaysShort : _enWeekdaysShort)[d.weekday - 1];
  return '$wd ${d.day}';
}

String _monthLabel(DateTime d, bool isEs) {
  final m = (isEs ? _esMonths : _enMonths)[d.month - 1];
  final cap = m[0].toUpperCase() + m.substring(1);
  return '$cap ${d.year}';
}

String _relTime(DateTime? d, bool isEs) {
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  final hhmm =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return isEs ? 'Hoy, $hhmm' : 'Today, $hhmm';
  if (diff == 1) return isEs ? 'Ayer, $hhmm' : 'Yesterday, $hhmm';
  final m = (isEs ? _esMonths : _enMonths)[d.month - 1].substring(0, 3);
  return '${d.day} $m';
}
