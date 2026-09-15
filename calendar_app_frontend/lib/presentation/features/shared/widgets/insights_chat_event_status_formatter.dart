String insightsEventStatusLabel(String status, bool isEs) {
  switch (status) {
    case 'ready_to_create':
      return isEs ? 'Listo para crear' : 'Ready to create';
    case 'needs_clarification':
      return isEs ? 'Necesita aclaracion' : 'Needs clarification';
    case 'created':
      return isEs ? 'Creado' : 'Created';
    case 'error':
      return isEs ? 'Error' : 'Error';
    case 'not_event':
      return isEs ? 'No es evento' : 'Not an event';
    default:
      return status.isEmpty ? (isEs ? 'Evento' : 'Event') : status;
  }
}
