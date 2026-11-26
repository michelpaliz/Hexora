import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:provider/provider.dart';

class PremiumPlansScreen extends StatelessWidget {
  const PremiumPlansScreen({super.key, this.group});

  final Group? group;

  @override
  Widget build(BuildContext context) {
    final selectedGroup = group ?? context.watch<GroupDomain?>()?.currentGroup;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEs ? 'Planes y Premium' : 'Plans and Premium'),
      ),
      body: selectedGroup == null
          ? _MissingBusiness(isEs: isEs)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          selectedGroup.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEs
                              ? 'Los planes y funciones se aplican únicamente a esta empresa.'
                              : 'Plans and features apply only to this business.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        _FreePlanCard(group: selectedGroup, isEs: isEs),
                        const SizedBox(height: 20),
                        _PremiumCard(group: selectedGroup, isEs: isEs),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MissingBusiness extends StatelessWidget {
  const _MissingBusiness({required this.isEs});

  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, size: 44),
            const SizedBox(height: 14),
            Text(
              isEs
                  ? 'Selecciona una empresa para consultar sus planes.'
                  : 'Select a business to view its plans.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({required this.group, required this.isEs});

  final Group group;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final freeUntil = DateTime(
      group.createdTime.year + 1,
      group.createdTime.month,
      group.createdTime.day,
    );
    final formattedDate = MaterialLocalizations.of(context).formatMediumDate(
      freeUntil,
    );
    final freePeriodActive = !DateTime.now().isAfter(freeUntil);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.primary.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business_center_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEs ? 'Plan Hexora' : 'Hexora plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        isEs ? 'Plan actual' : 'Current plan',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    freePeriodActive
                        ? Icons.check_circle_outline
                        : Icons.event_busy_outlined,
                    size: 17,
                  ),
                  label: Text(
                    freePeriodActive
                        ? (isEs ? 'Activo' : 'Active')
                        : (isEs ? 'Finalizado' : 'Ended'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isEs
                  ? 'Gratis durante el primer año de la empresa'
                  : 'Free for the business\'s first year',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              freePeriodActive
                  ? (isEs
                      ? 'Periodo gratuito hasta el $formattedDate.'
                      : 'Free period through $formattedDate.')
                  : (isEs
                      ? 'El periodo gratuito finalizó el $formattedDate.'
                      : 'The free period ended on $formattedDate.'),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _IncludedItem(
              text: isEs
                  ? 'Gestión de empresa, clientes y proveedores'
                  : 'Business, client, and provider management',
            ),
            _IncludedItem(
              text: isEs
                  ? 'Facturas, gastos y presupuestos'
                  : 'Invoices, expenses, and budgets',
            ),
            _IncludedItem(
              text: isEs ? 'Calendario y equipo' : 'Calendar and team tools',
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.group, required this.isEs});

  final Group group;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hexora Premium',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text(isEs ? 'De pago' : 'Paid')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isEs
                  ? 'Las funciones Premium no forman parte del primer año gratuito. Solicita información para conocer el precio y activar las que necesites.'
                  : 'Premium features are not included in the free first year. Request details to receive pricing and activate the features you need.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _FeatureRow(
              group: group,
              feature: PremiumFeatureRequest.email,
              active: hasPremiumFeature(group, PremiumFeature.email),
              title: isEs ? 'Correo empresarial' : 'Business email',
              description: isEs
                  ? 'Envío y gestión de correo desde Hexora.'
                  : 'Send and manage email from Hexora.',
              isEs: isEs,
            ),
            _FeatureRow(
              group: group,
              feature: PremiumFeatureRequest.banking,
              active: hasPremiumFeature(group, PremiumFeature.banking),
              title: isEs ? 'Banca y automatización' : 'Banking and automation',
              description: isEs
                  ? 'Movimientos bancarios e importaciones automáticas.'
                  : 'Bank transactions and automatic imports.',
              isEs: isEs,
            ),
            _FeatureRow(
              group: group,
              feature: PremiumFeatureRequest.aiChat,
              active: hasPremiumFeature(group, PremiumFeature.aiChat),
              title: isEs ? 'Asistente con IA' : 'AI assistant',
              description: isEs
                  ? 'Consultas y ayuda contextual para tu empresa.'
                  : 'Business questions and contextual assistance.',
              isEs: isEs,
            ),
            _FeatureRow(
              group: group,
              feature: PremiumFeatureRequest.teamChat,
              active: hasPremiumFeature(group, PremiumFeature.teamChat),
              title: isEs ? 'Chat de equipo' : 'Team chat',
              description: isEs
                  ? 'Conversaciones internas para los miembros de la empresa.'
                  : 'Internal conversations for business members.',
              isEs: isEs,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.group,
    required this.feature,
    required this.active,
    required this.title,
    required this.description,
    required this.isEs,
    this.showDivider = true,
  });

  final Group group;
  final PremiumFeatureRequest feature;
  final bool active;
  final String title;
  final String description;
  final bool isEs;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                active ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                color: active ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (active)
                Text(
                  isEs ? 'Activo' : 'Active',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PremiumFeatureRequestScreen(
                        feature: feature,
                        group: group,
                      ),
                    ),
                  ),
                  child: Text(
                    isEs ? 'Solicitar precio' : 'Request pricing',
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _IncludedItem extends StatelessWidget {
  const _IncludedItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 19, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
