import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/weather/weather_service.dart';
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
  const DashboardPreviewScreen({super.key, this.embedded = false});

  /// When true the screen renders only the dashboard content (no Scaffold,
  /// sidebar, top bar or back ribbon) so it can sit inside the workspace shell,
  /// which already provides its own module rail and top bar.
  final bool embedded;

  @override
  State<DashboardPreviewScreen> createState() => _DashboardPreviewScreenState();
}

// ===== Fixed palette (faithful to the light mockup; theme-independent) =====
class _Palette {
  static const scaffold = Color(0xFFF4F6FB);
  static const surface = Colors.white;
  static const navy = Color(0xFF1B2A4A);
  static const ink = Color(0xFF1C2435);
  static const muted = Color(0xFF8A93A6);
  static const border = Color(0xFFE6E9F2);
  static const blue = Color(0xFF2F6BFF);
  static const green = Color(0xFF17B26A);
  static const amber = Color(0xFFF5A524);
  static const purple = Color(0xFF7C5CFC);
  static const sidebarActive = Color(0xFFEAF1FF);
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
  const _ActivityItem(this.title, this.subtitle, this.when, this.icon,
      this.color);
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

  bool get _isEs =>
      Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.embedded || _weather != null) return;
    final user = context.read<AuthService>().currentUser;
    final location = (user?.location?.trim().isNotEmpty ?? false)
        ? user!.location!.trim()
        : 'Denia';
    _weather = _weatherService.fetchWeatherBundle(location: location, days: 1);
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

        final recent = [...invoices]
          ..sort((a, b) => (b.issueDate ?? DateTime(0))
              .compareTo(a.issueDate ?? DateTime(0)));
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
        final sorted = [...list]
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
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
      _ActivityItem(es ? 'Factura creada' : 'Invoice created',
          '#410-26 · Residencial Zurich', now, Icons.description_rounded,
          _Palette.blue),
      _ActivityItem(es ? 'Pago registrado' : 'Payment recorded',
          '#408-26 · Playasol II', now, Icons.check_circle_rounded,
          _Palette.green),
      _ActivityItem(es ? 'Presupuesto enviado' : 'Quote sent',
          '#P-120 · Brisas', now.subtract(const Duration(days: 1)),
          Icons.receipt_long_rounded, _Palette.purple),
      _ActivityItem(es ? 'Nuevo cliente' : 'New client',
          'Camos Molla Promociones', now.subtract(const Duration(days: 1)),
          Icons.person_add_alt_1_rounded, _Palette.amber),
    ];
  }

  List<_TaskItem> _mockTasks() {
    final es = _isEs;
    final d = DateTime.now();
    DateTime at(int add) => DateTime(d.year, d.month, d.day).add(Duration(days: add));
    return [
      _TaskItem(es ? 'Mantenimiento piscina – Brisas' : 'Pool maintenance – Brisas',
          at(1), _Palette.blue),
      _TaskItem(es ? 'Revisión de riego – La Sella' : 'Irrigation check – La Sella',
          at(1), _Palette.green),
      _TaskItem(es ? 'Enviar presupuesto – Cabo del Sol' : 'Send quote – Cabo del Sol',
          at(2), _Palette.amber),
      _TaskItem(es ? 'Seguimiento de factura #407-26' : 'Follow up invoice #407-26',
          at(3), _Palette.purple),
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

    if (widget.embedded) {
      return Container(
        color: _Palette.scaffold,
        child: FutureBuilder<_DashData>(
          future: _future,
          builder: (context, snap) {
            final data = snap.data;
            final loading = snap.connectionState != ConnectionState.done;
            return _Content(isEs: es, data: data, loading: loading);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewRibbon(isEs: es, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 900;
                  return FutureBuilder<_DashData>(
                    future: _future,
                    builder: (context, snap) {
                      final data = snap.data;
                      final loading = snap.connectionState !=
                          ConnectionState.done;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Sidebar(isEs: es),
                            Expanded(
                              child: Column(
                                children: [
                                  _TopBar(
                                      isEs: es, weather: _weather!, wide: true),
                                  Expanded(
                                    child: _Content(
                                        isEs: es,
                                        data: data,
                                        loading: loading),
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
                                isEs: es, data: data, loading: loading),
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
      color: _Palette.navy,
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
  const _Sidebar({required this.isEs});
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final items = <_NavDef>[
      _NavDef(Icons.home_rounded, isEs ? 'Inicio' : 'Home', active: true),
      _NavDef(Icons.groups_rounded, isEs ? 'Clientes' : 'Clients'),
      _NavDef(Icons.description_rounded, isEs ? 'Facturas' : 'Invoices',
          expandable: true),
      _NavDef(Icons.receipt_rounded, isEs ? 'Recibos' : 'Receipts',
          expandable: true),
      _NavDef(Icons.request_quote_rounded,
          isEs ? 'Presupuestos' : 'Quotes', expandable: true),
      _NavDef(Icons.payments_rounded, isEs ? 'Gastos' : 'Expenses',
          expandable: true),
      _NavDef(Icons.account_balance_rounded, isEs ? 'Banco' : 'Bank'),
      _NavDef(Icons.calendar_today_rounded, isEs ? 'Calendario' : 'Calendar'),
      _NavDef(Icons.bar_chart_rounded, isEs ? 'Informes' : 'Reports'),
      _NavDef(Icons.folder_rounded, isEs ? 'Documentos' : 'Documents'),
    ];

    return Container(
      width: 212,
      decoration: const BoxDecoration(
        color: _Palette.surface,
        border: Border(right: BorderSide(color: _Palette.border)),
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
                    color: _Palette.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hexagon_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Hexora',
                    style: TextStyle(
                        color: _Palette.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _Palette.muted, size: 18),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final it in items) _NavRow(def: it),
              ],
            ),
          ),
          const Divider(height: 1, color: _Palette.border),
          _NavRow(
              def: _NavDef(Icons.settings_rounded,
                  isEs ? 'Configuración' : 'Settings')),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavDef {
  _NavDef(this.icon, this.label, {this.active = false, this.expandable = false});
  final IconData icon;
  final String label;
  final bool active;
  final bool expandable;
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.def});
  final _NavDef def;

  @override
  Widget build(BuildContext context) {
    final color = def.active ? _Palette.blue : _Palette.ink;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: def.active ? _Palette.sidebarActive : Colors.transparent,
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
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: _Palette.muted),
          ],
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
      decoration: const BoxDecoration(
        color: _Palette.surface,
        border: Border(bottom: BorderSide(color: _Palette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!wide) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: _Palette.navy,
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
                border: Border.all(color: _Palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                      radius: 11,
                      backgroundColor: _Palette.sidebarActive,
                      child: Icon(Icons.business_rounded,
                          size: 13, color: _Palette.blue)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(businessName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _Palette.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: _Palette.muted),
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
          CircleAvatar(
            radius: 16,
            backgroundColor: _Palette.sidebarActive,
            backgroundImage: (user?.photoUrl?.trim().isNotEmpty ?? false)
                ? NetworkImage(user!.photoUrl!.trim())
                : null,
            child: (user?.photoUrl?.trim().isNotEmpty ?? false)
                ? null
                : const Icon(Icons.person_rounded,
                    size: 16, color: _Palette.blue),
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
            color: _Palette.scaffold,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: _Palette.ink),
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
        final city = today?.cityName ?? (isEs ? 'Dénia' : 'Denia');
        final desc = today?.summary.summary ?? (isEs ? 'Nublado' : 'Cloudy');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _Palette.scaffold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_rounded,
                  size: 20, color: _Palette.amber),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    temp != null ? '${temp.round()}°C  $desc' : desc,
                    style: const TextStyle(
                        color: _Palette.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5),
                  ),
                  Text('$city, ${isEs ? 'España' : 'Spain'}',
                      style: const TextStyle(
                          color: _Palette.muted,
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
      {required this.isEs, required this.data, required this.loading});
  final bool isEs;
  final _DashData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
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
      return ListView(
        padding: EdgeInsets.all(twoCol ? 24 : 16),
        children: [
          _GreetingHero(isEs: isEs, name: name),
          const SizedBox(height: 18),
          _StatRow(isEs: isEs, data: data, loading: loading),
          const SizedBox(height: 22),
          _QuickActions(isEs: isEs),
          const SizedBox(height: 22),
          if (twoCol)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _RecentActivity(isEs: isEs, data: data)),
                  const SizedBox(width: 18),
                  Expanded(child: _UpcomingTasks(isEs: isEs, data: data)),
                ],
              ),
            )
          else ...[
            _RecentActivity(isEs: isEs, data: data),
            const SizedBox(height: 18),
            _UpcomingTasks(isEs: isEs, data: data),
          ],
          const SizedBox(height: 18),
          if (twoCol)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RecentDocs(isEs: isEs, data: data)),
                  const SizedBox(width: 18),
                  Expanded(child: _ThisWeek(isEs: isEs, data: data)),
                ],
              ),
            )
          else ...[
            _RecentDocs(isEs: isEs, data: data),
            const SizedBox(height: 18),
            _ThisWeek(isEs: isEs, data: data),
          ],
          const SizedBox(height: 24),
        ],
      );
    });
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.isEs, required this.name});
  final bool isEs;
  final String name;

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF4FF), Color(0xFFF7F9FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: _Palette.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.waving_hand_rounded,
                color: _Palette.blue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $name',
                    style: const TextStyle(
                        color: _Palette.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  isEs
                      ? 'Aquí tienes un resumen de la actividad de tu negocio.'
                      : "Here's a summary of your business activity.",
                  style: const TextStyle(
                      color: _Palette.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: _Palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Palette.border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 15, color: _Palette.blue),
                const SizedBox(width: 8),
                Text(_formatLongDate(DateTime.now(), isEs),
                    style: const TextStyle(
                        color: _Palette.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.isEs, required this.data, required this.loading});
  final bool isEs;
  final _DashData? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
          label: isEs ? 'Facturas' : 'Invoices',
          value: data?.facturas,
          icon: Icons.description_rounded,
          color: _Palette.blue,
          loading: loading),
      _StatCard(
          label: isEs ? 'Pagadas' : 'Paid',
          value: data?.pagadas,
          icon: Icons.check_circle_rounded,
          color: _Palette.green,
          loading: loading),
      _StatCard(
          label: isEs ? 'Pendientes' : 'Pending',
          value: data?.pendientes,
          icon: Icons.access_time_rounded,
          color: _Palette.amber,
          loading: loading),
      _StatCard(
          label: isEs ? 'Clientes' : 'Clients',
          value: data?.clientes,
          icon: Icons.groups_rounded,
          color: _Palette.purple,
          loading: loading),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 720 ? 4 : 2;
      const gap = 14.0;
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
      required this.loading});
  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _Palette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
                const SizedBox(height: 2),
                loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Text('${value ?? 0}',
                        style: const TextStyle(
                            color: _Palette.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 24)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: _Palette.muted),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isEs});
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final actions = <_QA>[
      _QA(Icons.note_add_rounded, isEs ? 'Nueva factura' : 'New invoice',
          _Palette.blue),
      _QA(Icons.receipt_rounded, isEs ? 'Nuevo recibo' : 'New receipt',
          _Palette.purple),
      _QA(Icons.post_add_rounded, isEs ? 'Nuevo presupuesto' : 'New quote',
          _Palette.green),
      _QA(Icons.savings_rounded, isEs ? 'Registrar gasto' : 'Log expense',
          _Palette.amber),
      _QA(Icons.person_add_alt_1_rounded, isEs ? 'Crear cliente' : 'New client',
          _Palette.blue),
      _QA(Icons.event_rounded, isEs ? 'Nueva tarea' : 'New task',
          _Palette.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(isEs ? 'Accesos rápidos' : 'Quick actions'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 720
              ? 6
              : c.maxWidth >= 480
                  ? 3
                  : 2;
          const gap = 12.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final a in actions)
                SizedBox(width: w, child: _QuickActionTile(qa: a, isEs: isEs)),
            ],
          );
        }),
      ],
    );
  }
}

class _QA {
  _QA(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.qa, required this.isEs});
  final _QA qa;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(isEs
                ? 'Vista previa — acción no disponible'
                : 'Preview — action unavailable'),
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Palette.border),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: qa.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(qa.icon, color: qa.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(qa.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _Palette.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Panels =====================
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.action, required this.child});
  final String title;
  final String action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(title)),
              Text(action,
                  style: const TextStyle(
                      color: _Palette.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: _Palette.blue),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.isEs, required this.data});
  final bool isEs;
  final _DashData? data;

  @override
  Widget build(BuildContext context) {
    final items = data?.activity ?? const <_ActivityItem>[];
    return _Panel(
      title: isEs ? 'Actividad reciente' : 'Recent activity',
      action: isEs ? 'Ver todo' : 'See all',
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: items[i].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(items[i].icon,
                      color: items[i].color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          style: const TextStyle(
                              color: _Palette.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                      if (items[i].subtitle.isNotEmpty)
                        Text(items[i].subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _Palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_relTime(items[i].when, isEs),
                    style: const TextStyle(
                        color: _Palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _UpcomingTasks extends StatelessWidget {
  const _UpcomingTasks({required this.isEs, required this.data});
  final bool isEs;
  final _DashData? data;

  @override
  Widget build(BuildContext context) {
    final items = data?.tasks ?? const <_TaskItem>[];
    return _Panel(
      title: isEs ? 'Próximas tareas' : 'Upcoming tasks',
      action: isEs ? 'Ver calendario' : 'See calendar',
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
                const Icon(Icons.check_box_outline_blank_rounded,
                    size: 20, color: _Palette.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(items[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _Palette.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: _Palette.muted),
                    const SizedBox(width: 5),
                    Text(_shortDate(items[i].date, isEs),
                        style: const TextStyle(
                            color: _Palette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
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
                  width: 38,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDEDED),
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
                          style: const TextStyle(
                              color: _Palette.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                      Text(items[i].subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _Palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_relTime(items[i].when, isEs),
                    style: const TextStyle(
                        color: _Palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                const Icon(Icons.more_horiz_rounded,
                    size: 18, color: _Palette.muted),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
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
                      style: const TextStyle(
                          color: _Palette.navy,
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
                      style: const TextStyle(
                          color: _Palette.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
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
      style: const TextStyle(
          color: _Palette.navy, fontWeight: FontWeight.w800, fontSize: 16));
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
  return isEs ? '$wd, ${d.day} de $m de ${d.year}' : '$wd, $m ${d.day}, ${d.year}';
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
