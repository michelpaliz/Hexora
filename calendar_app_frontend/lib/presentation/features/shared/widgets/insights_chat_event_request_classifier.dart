bool looksLikeInsightsEventCreationRequest(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  final hasEventWord = RegExp(
    r'\b(event|meeting|appointment|reminder|maintenance|schedule|calendar|evento|reunion|reunión|cita|recordatorio|mantenimiento|agenda|calendario)\b',
  ).hasMatch(normalized);
  final hasCreateVerb = RegExp(
    r'\b(create|schedule|add|book|plan|set up|remind|program|crear|crea|agendar|agenda|anade|añade|programa|recordar|reservar)\b',
  ).hasMatch(normalized);
  final hasTimeHint = RegExp(
    r'\b(every|each|daily|weekly|monthly|yearly|weekday|weekdays|monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|next|until|at\s+\d|first|last|cada|diario|semanal|mensual|anual|laborable|lunes|martes|miercoles|miércoles|jueves|viernes|sabado|sábado|domingo|mañana|proximo|próximo|hasta|a las)\b',
  ).hasMatch(normalized);
  final hasDateLike = RegExp(r'\b\d{1,2}([/:.-]\d{1,2})?([/:.-]\d{2,4})?\b')
      .hasMatch(normalized);
  return hasEventWord || (hasCreateVerb && (hasTimeHint || hasDateLike));
}
