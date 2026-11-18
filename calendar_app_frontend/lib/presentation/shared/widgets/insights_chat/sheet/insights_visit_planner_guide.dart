import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class InsightsVisitPlannerGuide extends StatelessWidget {
  const InsightsVisitPlannerGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final sections = isEs
        ? const [
            _GuideSection(
              icon: Icons.event_available_outlined,
              title: 'Crear una visita',
              description:
                  'Pide una visita para un cliente e indica el día, la hora, el servicio y la duración. El chat usa los clientes, servicios y ubicaciones guardados en este negocio. Si falta un dato, te preguntará.',
              example:
                  'Crea una visita para Jardines Sol el martes a las 9:00 para podar los setos. Duración: 90 minutos.',
            ),
            _GuideSection(
              icon: Icons.calendar_view_week_outlined,
              title: 'Planificar una semana',
              description:
                  'Solicita visitas para varios días. Puedes indicar los clientes o pedir sugerencias; el chat puede proponer hasta 20 visitas y pedirte que confirmes los clientes sugeridos.',
              example:
                  'Planifica visitas de lunes a viernes la próxima semana para los clientes de Dénia. Una visita por la mañana.',
            ),
            _GuideSection(
              icon: Icons.route_outlined,
              title: 'Organizar una ruta cercana',
              description:
                  'Pide varias visitas en comunidades cercanas. El chat usa las ubicaciones guardadas para agrupar paradas y, si hay coordenadas, muestra un margen de traslado estimado.',
              example:
                  'Organiza 3 visitas cercanas en Las Marinas para el jueves por la mañana.',
            ),
            _GuideSection(
              icon: Icons.groups_outlined,
              title: 'Asignar un equipo',
              description:
                  'Nombra a las personas del negocio que deben asistir. Si no puede identificar un nombre o hay varias coincidencias, te pedirá que lo aclares.',
              example:
                  'Asigna a Jhoan, Amir y Samir a todas las visitas de esa ruta.',
            ),
            _GuideSection(
              icon: Icons.add_a_photo_outlined,
              title: 'Solicitar fotos del trabajo',
              description:
                  'Puedes pedir fotos para completar el trabajo, indicar una cantidad mínima o solicitar fotos del antes y el después. La regla se muestra en la vista previa.',
              example:
                  'Pide 3 fotos al terminar cada visita.',
            ),
            _GuideSection(
              icon: Icons.access_time_outlined,
              title: 'Respetar el horario del negocio',
              description:
                  'Si el negocio tiene un horario configurado, el chat programa las visitas dentro de ese horario y señala las propuestas que queden fuera.',
              example:
                  'Programa las visitas el miércoles entre las 9:00 y las 14:00.',
            ),
            _GuideSection(
              icon: Icons.warning_amber_outlined,
              title: 'Resolver conflictos o cambiar el plan',
              description:
                  'Si detecta un solapamiento o poco tiempo estimado para desplazarse, pide un cambio. Puedes responder con otra hora, otro día o un equipo distinto y revisar la propuesta actualizada.',
              example:
                  'Mueve la segunda visita a las 11:30 y deja el mismo equipo.',
            ),
            _GuideSection(
              icon: Icons.repeat_rounded,
              title: 'Crear visitas recurrentes',
              description:
                  'Indica cada cuánto debe repetirse una visita y, si corresponde, cuándo debe terminar. Revisa la recurrencia en la vista previa antes de confirmar.',
              example:
                  'Crea una visita cada dos semanas, los lunes, hasta finales de septiembre.',
            ),
            _GuideSection(
              icon: Icons.view_kanban_outlined,
              title: 'Crear notas rápidas',
              description:
                  'Crea tareas sin reservar una hora en el calendario. Puedes indicar detalles, cliente, responsables y una fecha límite. Revisa la tarjeta antes de confirmarla y después muévela entre Por hacer, En progreso y Hecho.',
              example:
                  'Crea una nota para revisar el riego de Las Marinas y asígnala a Amir para el viernes.',
            ),
          ]
        : const [
            _GuideSection(
              icon: Icons.event_available_outlined,
              title: 'Create one visit',
              description:
                  'Ask for a visit for a client and include the date, time, service, and duration. The chat uses clients, services, and locations saved in this business. It will ask if it needs more details.',
              example:
                  'Create a visit for Sunny Gardens on Tuesday at 9:00 to prune the hedges. Duration: 90 minutes.',
            ),
            _GuideSection(
              icon: Icons.calendar_view_week_outlined,
              title: 'Plan a week',
              description:
                  'Request visits across several days. Name the clients or ask for suggestions. The chat can propose up to 20 visits and may ask you to confirm suggested clients.',
              example:
                  'Plan visits for next Monday to Friday for clients in Denia, one visit each morning.',
            ),
            _GuideSection(
              icon: Icons.route_outlined,
              title: 'Arrange a nearby route',
              description:
                  'Ask for several visits in nearby communities. The chat uses saved locations to group stops and can show an estimated travel gap when coordinates are available.',
              example:
                  'Plan 3 nearby visits in Las Marinas for Thursday morning.',
            ),
            _GuideSection(
              icon: Icons.groups_outlined,
              title: 'Assign a team',
              description:
                  'Name the business users who should attend. If a name is unclear or matches multiple users, the chat will ask you to clarify.',
              example:
                  'Assign Jhoan, Amir, and Samir to every visit on that route.',
            ),
            _GuideSection(
              icon: Icons.add_a_photo_outlined,
              title: 'Require work photos',
              description:
                  'Ask for photos before a job can be completed, specify a minimum number, or request before-and-after photos. The requirement appears in the preview.',
              example:
                  'Require 3 photos when each visit is finished.',
            ),
            _GuideSection(
              icon: Icons.access_time_outlined,
              title: 'Use business hours',
              description:
                  'If the business has hours configured, the chat schedules visits within them and flags proposals that fall outside those hours.',
              example:
                  'Schedule the visits on Wednesday between 9:00 and 14:00.',
            ),
            _GuideSection(
              icon: Icons.warning_amber_outlined,
              title: 'Resolve conflicts or change the plan',
              description:
                  'If it finds an overlap or too little estimated travel time, ask it to adjust the plan. Give it another time, day, or team, then review the updated proposal.',
              example:
                  'Move the second visit to 11:30 and keep the same team.',
            ),
            _GuideSection(
              icon: Icons.repeat_rounded,
              title: 'Create recurring visits',
              description:
                  'Say how often a visit should repeat and, if needed, when it should end. Review the recurrence in the preview before confirming.',
              example:
                  'Create a visit every two weeks on Mondays until the end of September.',
            ),
            _GuideSection(
              icon: Icons.view_kanban_outlined,
              title: 'Create quick notes',
              description:
                  'Create work tasks without reserving calendar time. Include details, a client, assignees, and an optional due date. Review the card before confirming it, then move it through To Do, In Progress, and Done.',
              example:
                  'Create a note to check the irrigation at Las Marinas, assign Amir, and make it due Friday.',
            ),
          ];

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 14, 4),
      contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      title: Row(
        children: [
          Icon(Icons.event_note_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEs ? 'Cómo usar el asistente de trabajo' : 'Work assistant guide',
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text(
                isEs
                    ? 'Describe el trabajo con tus propias palabras. El chat preparará una vista previa antes de crear visitas o notas rápidas.'
                    : 'Describe the work in your own words. The chat prepares a preview before creating visits or quick notes.',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            for (final section in sections)
              _VisitGuideCard(section: section, isEs: isEs),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.tertiary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEs ? 'Ten en cuenta' : 'Keep in mind',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEs
                        ? '• Máximo 20 visitas o notas por solicitud.\n• Confirma cada elemento antes de crearlo.\n• Los traslados son estimaciones basadas en coordenadas guardadas, no rutas de tráfico en tiempo real.\n• Se revisan eventos del calendario, pero no turnos ni ausencias.'
                        : '• Up to 20 visits or notes per request.\n• Confirm each item before it is created.\n• Travel times are estimates from saved coordinates, not live traffic routes.\n• Calendar events are checked; shifts and leave are not.',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isEs ? 'Entendido' : 'Got it'),
        ),
      ],
    );
  }
}

class _GuideSection {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.example,
  });

  final IconData icon;
  final String title;
  final String description;
  final String example;
}

class _VisitGuideCard extends StatelessWidget {
  const _VisitGuideCard({required this.section, required this.isEs});

  final _GuideSection section;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(section.icon, size: 19, color: cs.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  section.title,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 5),
            child: Text(
              section.description,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12.3,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: TextSpan(
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontSize: 12,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '${isEs ? 'Ejemplo: ' : 'Example: '}',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: section.example),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
