// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get groups => 'Grupos';

  @override
  String get calendar => 'Calendario';

  @override
  String get settings => 'Configuración';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get groupData => 'Datos del grupo';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get language => 'es';

  @override
  String get changeView => 'Cambiar vista';

  @override
  String welcomeGroupView(Object username) {
    return 'Bienvenido $username, aquí puedes ver la lista de grupos de los que formas parte.';
  }

  @override
  String get zeroNotifications => 'No hay notificaciones disponibles';

  @override
  String get goToCalendar => 'Ir al calendario';

  @override
  String groupName(int maxChar) {
    return 'Nombre del grupo (máximo $maxChar caracteres)';
  }

  @override
  String groupDescription(int maxChar) {
    return 'Descripción del grupo (máximo $maxChar caracteres)';
  }

  @override
  String get addPplGroup => 'Añadir personas a tu grupo';

  @override
  String get addUser => 'Añadir usuario';

  @override
  String get addEvent => 'Añadir evento';

  @override
  String get administrator => 'Administrador';

  @override
  String get coAdministrator => 'Co-Administrador';

  @override
  String get member => 'Miembro';

  @override
  String get saveGroup => 'Guardar grupo';

  @override
  String get addImageGroup => 'Añadir imagen para el grupo';

  @override
  String get removeEvent =>
      '¿Estás seguro de que quieres eliminar este evento?';

  @override
  String get removeGroup => '¿Estás seguro de que quieres eliminar este grupo?';

  @override
  String get removeCalendar =>
      '¿Estás seguro de que quieres eliminar este calendario?';

  @override
  String get groupCreated => '¡Grupo creado con éxito!';

  @override
  String get failedToCreateGroup => 'Error al crear el grupo';

  @override
  String get eventCreated => 'El evento ha sido creado';

  @override
  String get eventEdited => 'El evento ha sido editado';

  @override
  String get eventAddedGroup => 'El evento ha sido añadido al grupo';

  @override
  String get event => 'Evento';

  @override
  String get chooseEventColor => 'Elige el color del evento:';

  @override
  String get errorEventNote => '¡La nota del evento no puede estar vacía!';

  @override
  String get name => 'Nombre';

  @override
  String get userName => 'Nombre de usuario';

  @override
  String get currentPassword => 'Introduce tu contraseña actual';

  @override
  String get newPassword => 'Actualiza tu contraseña actual';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get password => 'Contraseña';

  @override
  String get register => 'Registrarse';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get backToLogin => 'Volver al inicio de sesión';

  @override
  String get downloadMobileApp => 'Descargar la app móvil';

  @override
  String get userNameHint =>
      'Introduce tu nombre de usuario (p.ej., john_doe123)';

  @override
  String get nameHint => 'Introduce tu nombre';

  @override
  String get emailHint => 'Introduce tu correo electrónico';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get confirmPasswordHint => 'Introduce tu contraseña de nuevo';

  @override
  String get logoutMessage => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get passwordNotMatch =>
      'La nueva contraseña y la confirmación no coinciden.';

  @override
  String get userNameTaken => 'El nombre de usuario ya está en uso';

  @override
  String get weakPassword => 'Contraseña débil';

  @override
  String get emailTaken => 'El correo electrónico ya está en uso';

  @override
  String get invalidEmail =>
      'Esta dirección de correo electrónico no es válida';

  @override
  String get invalidUrl => 'Esta URL no es válida';

  @override
  String get registrationError => 'Error de registro';

  @override
  String get registerCheckEmail =>
      'Cuenta creada. Revisa tu correo para verificar.';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get wrongCredentials => 'Credenciales incorrectas';

  @override
  String get loginInvalidCredentials =>
      'Credenciales inválidas. Inténtalo de nuevo.';

  @override
  String get authError => 'Error de autenticación';

  @override
  String get verifyEmailTitle => 'Verifica tu correo electrónico';

  @override
  String get verifyEmailInfo => 'Te enviamos un enlace de Verificación.';

  @override
  String get verifyingEmail => 'Verificando tu correo...';

  @override
  String get verifyEmailTryAgain => 'Intentar de nuevo';

  @override
  String get resendVerificationButton => 'Reenviar Verificación';

  @override
  String get resendVerificationSending => 'Enviando...';

  @override
  String get resendVerificationInvalidEmail =>
      'Ingresa un correo válido para reenviar.';

  @override
  String resendVerificationSent(String email) {
    return 'Correo de Verificaciónviado a $email';
  }

  @override
  String resendVerificationFailed(String error) {
    return 'No se pudo reenviar la Verificación: $error';
  }

  @override
  String get verifySuccessTitle => 'Correo verificado';

  @override
  String get verifySuccessMessage =>
      'Tu correo ha sido confirmado. Ya puedes iniciar sesión y usar la aplicación.';

  @override
  String get downloadAppTitle => 'Obtén Hexora en tu teléfono';

  @override
  String get downloadAppSubtitle =>
      'Instala la app para Android o iOS y mantente al día donde estés.';

  @override
  String get downloadAppAndroid => 'Consíguela en Google Play';

  @override
  String get downloadAppIos => 'Descárgala en App Store';

  @override
  String get downloadAppOpenError =>
      'No se pudo abrir el enlace de la tienda. Intenta de nuevo.';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get notRegistered =>
      '¿No estás registrado? No te preocupes, regístrate aquí.';

  @override
  String get alreadyRegistered => '¿Ya estás registrado? Inicia sesión aquí.';

  @override
  String title(Object maxChar) {
    return 'Título (máximo $maxChar caracteres)';
  }

  @override
  String description(int maxChar) {
    return 'Descripción (máximo $maxChar caracteres)';
  }

  @override
  String note(int maxChar) {
    return 'Nota (máximo $maxChar caracteres)';
  }

  @override
  String get location => 'Ubicación';

  @override
  String get repetitionEvent => 'Fecha de inicio duplicada';

  @override
  String get repetitionEventInfo =>
      'Ya existe un evento con la misma hora y día de inicio.';

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get yearly => 'Anual';

  @override
  String get repetitionDetails => 'Detalles de repetición';

  @override
  String dailyRepetitionInf(int concurrenceDay) {
    return 'Este evento se repetirá cada $concurrenceDay día';
  }

  @override
  String get every => 'Cada:';

  @override
  String get dailys => 'diario(s)';

  @override
  String get weeklys => 'semanal(es)';

  @override
  String get monthlies => 'mensual(es)';

  @override
  String get yearlys => 'año(s)';

  @override
  String get untilDate => 'Hasta la fecha:';

  @override
  String untilDateSelected(String untilDate) {
    return 'Hasta la fecha: $untilDate';
  }

  @override
  String get notSelected => 'No seleccionado';

  @override
  String get utilDateNotSelected => 'Hasta la fecha: No seleccionado';

  @override
  String get specifyRepeatInterval =>
      'Por favor, especifica el intervalo de repetición';

  @override
  String get selectOneDayAtLeast =>
      'Por favor, selecciona al menos un día de la semana.';

  @override
  String get datesMustBeSame =>
      'Las fechas de inicio y fin deben ser el mismo día para que el evento se repita.';

  @override
  String get startDate => 'Fecha de inicio:';

  @override
  String get endDate => 'Fecha de fin:';

  @override
  String get noDaysSelected => 'No hay días seleccionados';

  @override
  String get selectRepetition => 'Seleccionar repetición';

  @override
  String get selectDay => 'Seleccionar día:';

  @override
  String dayRepetitionInf(int concurrenceWeeks) {
    return 'Este evento se repetirá cada $concurrenceWeeks día.';
  }

  @override
  String weeklyRepetitionInf(
      int concurrenceWeeks,
      String customDaysOfWeeksString,
      String lastDay,
      Object customDaysOfWeekString) {
    return 'Este evento se repetirá cada $concurrenceWeeks semana(s) el $customDaysOfWeekString, y $lastDay';
  }

  @override
  String weeklyRepetitionInf1(int repeatInterval, String selectedDayNames) {
    return 'Este evento se repetirá cada $repeatInterval semana(s) en \$$selectedDayNames';
  }

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mié';

  @override
  String get thu => 'Jue';

  @override
  String get fri => 'Vie';

  @override
  String get sat => 'Sáb';

  @override
  String get sun => 'Dom';

  @override
  String errorSelectedDays(String selectedDays) {
    return 'El día del evento $selectedDays debe coincidir con uno de los días seleccionados.';
  }

  @override
  String textFieldGroupName(int TITLE_MAX_LENGHT) {
    return 'Introduce el nombre del grupo (Límite: $TITLE_MAX_LENGHT caracteres)';
  }

  @override
  String textFieldDescription(int DESCRIPTION_MAX_LENGHT) {
    return 'Introduce la descripción del grupo (Límite: $DESCRIPTION_MAX_LENGHT caracteres)';
  }

  @override
  String monthlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay) {
    return 'Este evento se repetirá el día $selectDay de cada $repeatInterval mes(es)';
  }

  @override
  String yearlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay) {
    return 'Este evento se repetirá el día $selectDay de cada $repeatInterval año(s)';
  }

  @override
  String get editGroup => 'Editar';

  @override
  String get remove => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirmation => 'Confirmación';

  @override
  String get removeConfirmation => 'Confirmar eliminación';

  @override
  String get permissionDenied => 'Permiso denegado';

  @override
  String get permissionDeniedInf =>
      'No eres administrador para eliminar este elemento.';

  @override
  String get leaveGroup => 'Salir del grupo';

  @override
  String permissionDeniedRole(Object role) {
    return 'Actualmente eres $role de este grupo.';
  }

  @override
  String get putGroupImage => 'Poner una imagen para el grupo';

  @override
  String get close => 'Cerrar';

  @override
  String get addNewUser => 'Añadir un nuevo usuario a tu grupo';

  @override
  String get cannotRemoveYourself => 'No puedes eliminarte del grupo';

  @override
  String get requiredTextFields =>
      'El nombre y la descripción del grupo son obligatorios.';

  @override
  String get groupNameRequired => 'El nombre del grupo no puede estar vacío';

  @override
  String get groupEdited => '¡Grupo editado con éxito!';

  @override
  String get failedToEditGroup =>
      'Error al editar el grupo. Por favor, inténtalo de nuevo';

  @override
  String get searchPerson => 'Buscar por nombre de usuario';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirmRemovalMessage =>
      '¿Estás seguro de que quieres eliminar este grupo?';

  @override
  String get confirmRemoval => 'Confirmar eliminación';

  @override
  String get groupDeletedSuccessfully => '¡Grupo eliminado con éxito!';

  @override
  String get showInactiveClients => 'Mostrar clientes inactivos';

  @override
  String get hideInactiveClients => 'Ocultar clientes inactivos';

  @override
  String removeClientConfirm(Object name) {
    return '¿Eliminar el cliente \"$name\"?';
  }

  @override
  String removeServiceConfirm(Object name) {
    return '¿Eliminar el servicio \"$name\"?';
  }

  @override
  String clientRemovedSnack(Object name) {
    return 'Cliente eliminado: $name';
  }

  @override
  String serviceRemovedSnack(Object name) {
    return 'Servicio eliminado: $name';
  }

  @override
  String clientDeactivatedSnack(Object name) {
    return 'Cliente pasado a inactivo: $name';
  }

  @override
  String serviceDeactivatedSnack(Object name) {
    return 'Servicio pasado a inactivo: $name';
  }

  @override
  String removeFailedWithReason(Object reason) {
    return 'No se pudo eliminar: $reason';
  }

  @override
  String get noGroupsAvailable => 'NO SE ENCONTRARON GRUPOS';

  @override
  String get noGroupsFound => 'No se encontraron grupos';

  @override
  String get noGroupsDescription => 'Crea o únete a un grupo para comenzar';

  @override
  String get searchGroups => 'Buscar grupos';

  @override
  String get weatherSummarySunny => 'Soleado';

  @override
  String get weatherSummaryPartlyCloudy => 'Parcialmente nublado';

  @override
  String get weatherSummaryCloudyWithRain => 'Nublado con lluvia';

  @override
  String get weatherSummaryLightRain => 'Lluvia ligera';

  @override
  String get weatherSummaryHeavyRain => 'Lluvia fuerte';

  @override
  String get weatherSummaryStormy => 'Tormentoso';

  @override
  String get weatherSummaryCloudy => 'Nublado';

  @override
  String get weatherSummaryDefault => 'Clima agradable';

  @override
  String weatherGreeting(Object emoji, Object name, Object summary) {
    return 'Hola $name, hoy pinta $summary $emoji';
  }

  @override
  String weatherTempLine(Object max, Object min) {
    return 'Máx $max° / Mín $min°';
  }

  @override
  String get weatherFunTooHot => 'Mantente hidratado, hará mucho calor.';

  @override
  String get weatherFunTooCold => 'Abrígate bien, hará mucho frío.';

  @override
  String get weatherFunGradeA =>
      'Día de calificación A. ¡Planea algo divertido al aire libre!';

  @override
  String get weatherFunGradeB => 'El clima está bastante bien en general.';

  @override
  String get weatherFunGradeC => 'Ten un paraguas a mano por si acaso.';

  @override
  String get weatherFunGradeD =>
      'Quizás planees actividades en interiores hoy.';

  @override
  String get weatherFunDefault => 'Aprovecha el día sin importar el clima.';

  @override
  String get weatherForecastLoading => 'Cargando pronóstico del tiempo...';

  @override
  String get weatherForecastEmpty => 'No hay datos de pronóstico disponibles.';

  @override
  String get weatherForecastRainShort => 'lluvia';

  @override
  String get monday => 'lunes';

  @override
  String get tuesday => 'martes';

  @override
  String get wednesday => 'miércoles';

  @override
  String get thursday => 'jueves';

  @override
  String get friday => 'viernes';

  @override
  String get saturday => 'sábado';

  @override
  String get sunday => 'domingo';

  @override
  String get save => 'Guardar Edición';

  @override
  String get groupNameText => 'Nombre del grupo';

  @override
  String get groupOwner => 'Propietario del grupo';

  @override
  String get enableRepetitiveEvents => 'Habilitar eventos repetitivos';

  @override
  String get passwordChangedSuccessfully => 'Contraseña cambiada con éxito';

  @override
  String get currentPasswordIncorrect =>
      'La contraseña actual es incorrecta. Por favor, inténtalo de nuevo.';

  @override
  String get newPasswordConfirmationError =>
      'La nueva contraseña y la confirmación no coinciden.';

  @override
  String get changedPasswordError =>
      'Error al cambiar la contraseña. Por favor, inténtalo de nuevo';

  @override
  String get passwordContainsUnwantedChar =>
      'La contraseña contiene caracteres no deseados.';

  @override
  String get changeUsername => 'Cambiar tu nombre de usuario';

  @override
  String get successChangingUsername =>
      '¡Nombre de usuario actualizado con éxito!';

  @override
  String get usernameAlreadyTaken =>
      'El nombre de usuario ya está en uso. Elige otro.';

  @override
  String get errorUnwantedCharactersUsername =>
      'Caracteres inválidos en el nombre de usuario. Usa solo caracteres alfanuméricos y guiones bajos.';

  @override
  String get errorChangingUsername =>
      'Error al cambiar el nombre de usuario. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get errorChangingPassword =>
      'Error al cambiar la contraseña. Por favor, inténtalo de nuevo.';

  @override
  String get errorUsernameLength =>
      'El nombre de usuario debe tener entre 6 y 10 caracteres';

  @override
  String formatDate(Object date) {
    return '$date';
  }

  @override
  String get forgotPassword => 'Recupera tu contraseña aquí.';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get userNameRequired => 'El nombre de usuario es obligatorio';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get passwordLength =>
      'La contraseña debe tener un máximo de 6 caracteres';

  @override
  String get groupNotCreated => 'Error al crear el grupo, inténtalo de nuevo';

  @override
  String get questionDeleteGroup =>
      '¿Estás seguro de que quieres eliminar este grupo?';

  @override
  String get errorEventCreation =>
      'Se produjo un error al crear el evento, inténtalo más tarde';

  @override
  String get eventEditFailed =>
      'Se produjo un error al editar el evento, inténtalo más tarde';

  @override
  String get noEventsFoundForDate =>
      'No se encontraron eventos para esta fecha, inténtalo más tarde.';

  @override
  String get confirmDelete =>
      '¿Estás seguro de que quieres eliminar este evento?';

  @override
  String get confirmDeleteDescription => 'Eliminar evento.';

  @override
  String get groupNameLabel => 'Nombre del grupo';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get refresh => 'Actualizando pantalla...';

  @override
  String get accepted => 'Aceptado';

  @override
  String get pending => 'Pendiente';

  @override
  String get notAccepted => 'No aceptado';

  @override
  String get newUsers => 'Nuevos';

  @override
  String get expired => 'Expirado';

  @override
  String get userNotSignedIn => 'El usuario no esta logeado.';

  @override
  String get createdOn => 'Creado en';

  @override
  String get userCount => 'Contador';

  @override
  String get timeJustNow => 'Justo ahora';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'hace $minutes minutos';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'hace $hours horas';
  }

  @override
  String timeDaysAgo(Object days) {
    return 'hace $days días';
  }

  @override
  String get timeLast30Days => 'Últimos 30 días';

  @override
  String get groupRecent => 'Reciente';

  @override
  String get groupLast7Days => 'Últimos 7 días';

  @override
  String get groupLast30Days => 'Últimos 30 días';

  @override
  String get groupOlder => 'Antiguos';

  @override
  String get notificationGroupCreationTitle => '¡Felicidades!';

  @override
  String notificationGroupCreationMessage(Object groupName) {
    return 'Has creado el grupo: $groupName';
  }

  @override
  String get notificationJoinedGroupTitle => 'Bienvenido al grupo';

  @override
  String notificationJoinedGroupMessage(Object groupName) {
    return 'Te has unido al grupo: $groupName';
  }

  @override
  String get notificationInvitationTitle => 'Invitación al grupo';

  @override
  String notificationInvitationMessage(Object groupName) {
    return 'Has sido invitado a unirte al grupo: $groupName';
  }

  @override
  String get notificationInvitationDeniedTitle => 'Invitación rechazada';

  @override
  String notificationInvitationDeniedMessage(
      Object groupName, Object userName) {
    return '$userName rechazó la invitación para unirse a $groupName';
  }

  @override
  String get notificationUserAcceptedTitle => 'Usuario se ha unido';

  @override
  String notificationUserAcceptedMessage(Object groupName, Object userName) {
    return '$userName ha aceptado la invitación para unirse a $groupName';
  }

  @override
  String get notificationGroupEditedTitle => 'Grupo actualizado';

  @override
  String notificationGroupEditedMessage(Object groupName) {
    return 'Has actualizado el grupo: $groupName';
  }

  @override
  String get notificationGroupDeletedTitle => 'Grupo eliminado';

  @override
  String notificationGroupDeletedMessage(Object groupName) {
    return 'Has eliminado el grupo: $groupName';
  }

  @override
  String get notificationUserRemovedTitle => 'Usuario eliminado';

  @override
  String notificationUserRemovedMessage(Object adminName, Object groupName) {
    return 'Has sido eliminado del grupo $groupName por $adminName';
  }

  @override
  String get notificationAdminUserRemovedTitle => 'Usuario eliminado';

  @override
  String notificationAdminUserRemovedMessage(
      Object groupName, Object userName) {
    return '$userName fue eliminado del grupo $groupName';
  }

  @override
  String get notificationUserLeftTitle => 'Usuario salió del grupo';

  @override
  String notificationUserLeftMessage(Object groupName, Object userName) {
    return '$userName ha salido del grupo: $groupName';
  }

  @override
  String get notificationGroupUpdateTitle => 'Grupo actualizado';

  @override
  String notificationGroupUpdateMessage(Object editorName, Object groupName) {
    return '$editorName actualizó el grupo: $groupName';
  }

  @override
  String get notificationGroupDeletedAllTitle => 'Grupo eliminado';

  @override
  String notificationGroupDeletedAllMessage(Object groupName) {
    return 'El grupo \"$groupName\" ha sido eliminado por el propietario.';
  }

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get editEvent => 'Editar Evento';

  @override
  String eventDayNotIncludedWarning(String day) {
    return 'Advertencia: El evento comienza el $day, pero este día no está seleccionado en el patrón de repetición.';
  }

  @override
  String get removeRecurrence => 'Eliminar repetición';

  @override
  String get removeRecurrenceConfirm =>
      '¿Deseas eliminar la repetición de este evento?';

  @override
  String get reminderLabel => 'Recordatorio';

  @override
  String get reminderHelper => 'Elige cuándo deseas ser recordado';

  @override
  String get reminderOptionAtTime => 'A la hora del evento';

  @override
  String get reminderOption5min => '5 minutos antes';

  @override
  String get reminderOption10min => '10 minutos antes';

  @override
  String get reminderOption30min => '30 minutos antes';

  @override
  String get reminderOption1hour => '1 hora antes';

  @override
  String get reminderOption2hours => '2 horas antes';

  @override
  String get reminderOption1day => '1 día antes';

  @override
  String get reminderOption2days => '2 días antes';

  @override
  String get reminderOption3days => '3 días antes';

  @override
  String get saveChangesMessage => 'Guardando cambios...';

  @override
  String get createEventMessage => 'Creando evento...';

  @override
  String get dialogSelectUsersTitle => 'Selecciona usuarios para este evento';

  @override
  String get dialogClose => 'Cerrar';

  @override
  String get dialogShowUsers => 'Seleccionar usuarios';

  @override
  String get repeatEventLabel => 'Repetir evento:';

  @override
  String get repeatYes => 'Sí';

  @override
  String get repeatNo => 'No';

  @override
  String get notificationEventReminderTitle => 'Recordatorio de evento';

  @override
  String notificationEventReminderMessage(Object eventTitle) {
    return 'Recordatorio: \"$eventTitle\" comienza pronto.';
  }

  @override
  String get userDropdownSelect => 'Seleccionar usuarios';

  @override
  String get noUsersSelected => 'Ningún usuario seleccionado.';

  @override
  String get noUserRolesAvailable =>
      'Ningun rol seleccionado para los usuarios';

  @override
  String get userExpandableCardTitle => 'Seleccionar usuarios';

  @override
  String get eventDetailsTitle => 'Detalles del evento';

  @override
  String get eventTitleHint => 'Título';

  @override
  String get eventStartDateHint => 'Fecha de inicio';

  @override
  String get eventEndDateHint => 'Fecha de fin';

  @override
  String get eventLocationHint => 'Ubicación';

  @override
  String get eventDescriptionHint => 'Descripción';

  @override
  String get eventNoteHint => 'Nota';

  @override
  String get eventRecurrenceHint => 'Regla de repetición';

  @override
  String get notificationEventCreatedTitle => 'Evento creado';

  @override
  String notificationEventCreatedMessage(String eventTitle) {
    return 'Se ha creado un evento \"$eventTitle\".';
  }

  @override
  String get notificationEventUpdatedTitle => 'Evento actualizado';

  @override
  String notificationEventUpdatedMessage(String eventTitle) {
    return 'El evento \"$eventTitle\" ha sido actualizado.';
  }

  @override
  String get notificationEventDeletedTitle => 'Evento eliminado';

  @override
  String notificationEventDeletedMessage(String eventTitle) {
    return 'El evento \"$eventTitle\" ha sido eliminado.';
  }

  @override
  String get notificationRecurrenceAddedTitle => 'Evento recurrente';

  @override
  String notificationRecurrenceAddedMessage(String title) {
    return 'El evento \"$title\" ahora se repite.';
  }

  @override
  String get notificationEventMarkedDoneTitle => 'Evento completado';

  @override
  String notificationEventMarkedDoneMessage(
      String eventTitle, String userName) {
    return 'El evento \"$eventTitle\" fue marcado como completado por $userName.';
  }

  @override
  String get notificationEventReopenedTitle => 'Evento reabierto';

  @override
  String notificationEventReopenedMessage(String eventTitle, String userName) {
    return 'El evento \"$eventTitle\" fue reabierto por $userName.';
  }

  @override
  String get notificationEventStartedTitle => 'Evento Iniciado';

  @override
  String notificationEventStartedMessage(String eventTitle) {
    return 'El evento \"$eventTitle\" acaba de comenzar.';
  }

  @override
  String notificationEventReminderBodyWithTime(
      String eventTitle, String eventTime) {
    return 'Recordatorio: \"$eventTitle\" comienza a las $eventTime.';
  }

  @override
  String get notificationEventReminderManual => 'Notificación de prueba manual';

  @override
  String get categoryGroup => 'Grupo';

  @override
  String get categoryUser => 'Usuario';

  @override
  String get categorySystem => 'Sistema';

  @override
  String get categoryOther => 'Otro';

  @override
  String get passwordRecoveryTitle => 'Recuperación de contraseña';

  @override
  String get passwordRecoveryInstruction =>
      'Introduce tu correo electrónico o nombre de usuario para iniciar la recuperación de contraseña:';

  @override
  String get emailOrUsername => 'Correo electrónico o nombre de usuario';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get passwordRecoveryEmptyField =>
      'Por favor, introduce tu correo electrónico o nombre de usuario.';

  @override
  String get passwordRecoverySuccess =>
      'Se ha recibido una solicitud para restablecer la contraseña. Contacta con soporte o revisa la configuración de tu cuenta.';

  @override
  String get endDateMustBeAfterStartDate =>
      'La fecha de finalización debe ser posterior a la fecha de inicio';

  @override
  String get pleaseSelectAtLeastOneUser =>
      'Por favor, selecciona al menos un usuario';

  @override
  String get groupMembers => 'Miembros del grupo';

  @override
  String get noInvitedUsersToDisplay =>
      'No hay usuarios invitados para mostrar.';

  @override
  String userRemovedSuccessfully(String userName) {
    return 'Usuario $userName eliminado correctamente.';
  }

  @override
  String failedToRemoveUser(String userName) {
    return 'No se pudo eliminar al usuario $userName.';
  }

  @override
  String get groupDescriptionLabel => 'Descripción del grupo';

  @override
  String get agenda => 'Agenda';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get noItems => 'Nada próximo';

  @override
  String get home => 'Inicio';

  @override
  String get profile => 'Perfil';

  @override
  String get displayName => 'Nombre para mostrar';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get email => 'Correo electrónico';

  @override
  String get saving => 'Guardando...';

  @override
  String get photoUpdated => 'Foto actualizada';

  @override
  String get failedToSavePhoto => 'No se pudo guardar la foto';

  @override
  String get failedToUploadImage => 'No se pudo subir la imagen';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get failedToSaveProfile => 'No se pudo guardar el perfil';

  @override
  String get notAuthenticatedOrUserMissing =>
      'No autenticado o falta el usuario';

  @override
  String get noUserLoaded => 'No se ha cargado ningún usuario';

  @override
  String get motivationSectionTitle => 'Frase del día';

  @override
  String get groupSectionTitle => 'Grupos';

  @override
  String get clearAllTooltip => 'Borrar todas las notificaciones';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get clearAllConfirmTitle => '¿Borrar todo?';

  @override
  String get clearAllConfirmMessage =>
      '¿Quieres eliminar todas las notificaciones? Esta acción no se puede deshacer.';

  @override
  String get clearedAllSuccess => 'Se borraron todas las notificaciones';

  @override
  String get all => 'Todos';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get termsAndPrivacy =>
      'Al registrarte, aceptas nuestros Términos y la Política de Privacidad';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get welcomeTitle => '¡Bienvenido!';

  @override
  String get welcomeSubtitle =>
      'Crea una cuenta para comenzar a usar nuestra aplicación.';

  @override
  String get passwordWeak => 'Débil';

  @override
  String get passwordMedium => 'Media';

  @override
  String get passwordStrong => 'Fuerte';

  @override
  String get terms => 'Términos';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get termsAndPrivacyPrefix => 'Al registrarte, aceptas nuestros ';

  @override
  String get andSeparator => ' y ';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get loginWelcomeTitle => '¡Bienvenido de nuevo!';

  @override
  String get loginWelcomeSubtitle =>
      'Introduce tus credenciales para continuar.';

  @override
  String get forgotPasswordSubtitle =>
      'Introduce tu correo y te enviaremos un enlace de restablecimiento.';

  @override
  String get sendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get resetLinkSent => '¡Enlace de restablecimiento enviado!';

  @override
  String get forgotPasswordNeutralSuccess =>
      'Si existe una cuenta, hemos enviado un enlace para restablecer la contraseña.';

  @override
  String get forgotPasswordNetworkError =>
      'No se pudo enviar el enlace. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get confirmPasswordRequired => 'Confirma tu nueva contraseña.';

  @override
  String get resetPasswordSubmit => 'Restablecer contraseña';

  @override
  String get resetPasswordInvalidLinkTitle =>
      'Enlace de restablecimiento inválido';

  @override
  String get resetPasswordInvalidLinkBody =>
      'Este enlace no es válido o no incluye token. Solicita un nuevo enlace.';

  @override
  String get resetPasswordRequestNewLink => 'Solicitar nuevo enlace';

  @override
  String get resetPasswordInvalidToken =>
      'Este token es inválido o ha expirado.';

  @override
  String get resetPasswordGenericError =>
      'No se pudo restablecer la contraseña. Inténtalo de nuevo.';

  @override
  String get resetPasswordSuccessTitle =>
      'Contraseña restablecida correctamente';

  @override
  String get resetPasswordSuccessBody =>
      'Tu contraseña se actualizó. Ya puedes iniciar sesión con la nueva contraseña.';

  @override
  String get noUpcomingHint => 'Prueba con otra categoría o amplía el rango.';

  @override
  String get agendaSelectGroupPrompt =>
      'Selecciona un grupo para cargar eventos';

  @override
  String get agendaChooseGroupButton => 'Elegir';

  @override
  String get hi => 'Hola';

  @override
  String get completed => 'Completados';

  @override
  String get showFourteenDays => '14 días';

  @override
  String get showThirtyDays => '30 días';

  @override
  String get meetings => 'Reuniones';

  @override
  String get tasks => 'Tareas';

  @override
  String get deadlines => 'Plazos';

  @override
  String get personal => 'Personal';

  @override
  String get statusDone => 'Hecho';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusInProgress => 'En progreso';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusOverdue => 'Atrasado';

  @override
  String get statusFinished => 'Finalizado';

  @override
  String completedSummary(Object done, Object total, Object percent) {
    return '$done de $total completados ($percent%)';
  }

  @override
  String get notifyMe => 'Notificarme';

  @override
  String get notifyMeOnSubtitle => 'Recibirás un recordatorio de este evento';

  @override
  String get notifyMeOffSubtitle => 'No se enviará ningún recordatorio';

  @override
  String get noInvitableUsers => 'No hay usuarios disponibles para invitar';

  @override
  String get dashboard => 'Panel de control';

  @override
  String get noClientsYet => 'Aún no hay clientes';

  @override
  String get addYourFirstClient => 'Añade tu primer cliente a este grupo.';

  @override
  String get addClient => 'Añadir cliente';

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get noServicesYet => 'Aún no hay servicios';

  @override
  String get createServicesSubtitle =>
      'Crea servicios que puedes asignar a las reservas.';

  @override
  String get addService => 'Añadir servicio';

  @override
  String get noDefaultDuration => 'Sin duración predeterminada';

  @override
  String get minutesAbbrev => 'min';

  @override
  String get editClient => 'Editar cliente';

  @override
  String get createClient => 'Crear cliente';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameIsRequired => 'El nombre es obligatorio';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get saveClient => 'Guardar cliente';

  @override
  String failedWithReason(String reason) {
    return 'Error: $reason';
  }

  @override
  String get editService => 'Editar servicio';

  @override
  String get createService => 'Crear servicio';

  @override
  String get serviceNameExample => 'Ej.: Mantenimiento de jardines';

  @override
  String get defaultMinutesLabel => 'Minutos predeterminados';

  @override
  String get defaultMinutesHint => 'p. ej., 45';

  @override
  String get colorLabel => 'Color';

  @override
  String get saveService => 'Guardar servicio';

  @override
  String get screenServicesClientsTitle => 'Servicios y clientes';

  @override
  String get tabClients => 'Clientes';

  @override
  String get tabServices => 'Servicios';

  @override
  String get clientsSectionTitle => 'Clientes de este grupo';

  @override
  String get servicesSectionTitle => 'Servicios de este grupo';

  @override
  String get activeClientsSection => 'Clientes activos';

  @override
  String get inactiveClientsSection => 'Clientes inactivos';

  @override
  String get activeServicesSection => 'Servicios activos';

  @override
  String get inactiveServicesSection => 'Servicios inactivos';

  @override
  String clientCreatedWithName(String name) {
    return 'Cliente creado: $name';
  }

  @override
  String serviceCreatedWithName(String name) {
    return 'Servicio creado: $name';
  }

  @override
  String clientUpdatedWithName(String name) {
    return 'Cliente actualizado: $name';
  }

  @override
  String serviceUpdatedWithName(String name) {
    return 'Servicio actualizado: $name';
  }

  @override
  String nClients(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# clientes',
      one: '# cliente',
    );
    return '$_temp0';
  }

  @override
  String nServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# servicios',
      one: '# servicio',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get sectionOverview => 'Resumen';

  @override
  String get sectionUpcoming => 'Próximos';

  @override
  String get sectionEvents => 'Eventos';

  @override
  String get pendingEventsSectionTitle => 'Eventos pendientes';

  @override
  String get pendingEventsSectionSubtitle =>
      'Marca las visitas como finalizadas cuando termines.';

  @override
  String get pendingEventsEmpty => 'Todo al día.';

  @override
  String get pendingEventsError => 'No pudimos cargar los eventos pendientes.';

  @override
  String get pendingEventsMarkDone => 'Marcar como hecho';

  @override
  String get completedEventsSectionTitle => 'Eventos completados';

  @override
  String get completedEventsSectionSubtitle =>
      'Visitas y tareas completadas recientemente.';

  @override
  String get completedEventsEmpty => 'Aún no hay eventos completados.';

  @override
  String get roleCardTapHint => 'Toca para ver todas las capacidades del rol.';

  @override
  String get createdByLabel => 'Creado por';

  @override
  String get sectionManage => 'Administrar';

  @override
  String get sectionStatus => 'Estado';

  @override
  String createdOnDay(String date) {
    return 'Creado el $date';
  }

  @override
  String get membersTitle => 'Miembros';

  @override
  String membersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# en total',
      one: '# en total',
    );
    return '$_temp0';
  }

  @override
  String get servicesClientsTitle => 'Servicios y clientes';

  @override
  String get servicesClientsSubtitle => 'Crea y administra servicios/clientes';

  @override
  String get noCalendarWarning =>
      'Este grupo aún no tiene un calendario vinculado.';

  @override
  String get sectionFilters => 'Filtros';

  @override
  String get noMembersTitle => 'Sin miembros';

  @override
  String get noMembersMatchFilters =>
      'Ningún miembro coincide con estos filtros.';

  @override
  String get tryAdjustingFilters => 'Prueba ajustando los filtros de arriba.';

  @override
  String get statusAccepted => 'Aceptado';

  @override
  String get statusNotAccepted => 'No aceptado';

  @override
  String errorLoadingUser(String error) {
    return 'Error al cargar el usuario: $error';
  }

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get message => 'Mensaje';

  @override
  String get changeRole => 'Cambiar rol';

  @override
  String get removeFromGroup => 'Eliminar del grupo';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleMember => 'Miembro';

  @override
  String get details => 'Detalles';

  @override
  String get edit => 'Editar';

  @override
  String get addToContacts => 'Agregar a contactos';

  @override
  String get share => 'Compartir';

  @override
  String get copiedToClipboard => '¡Copiado!';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get team => 'Equipo';

  @override
  String get teams => 'Equipos';

  @override
  String get calendars => 'Calendarios';

  @override
  String teamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# equipos',
      one: '# equipo',
    );
    return '$_temp0';
  }

  @override
  String calendarsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# calendarios',
      one: '# calendario',
    );
    return '$_temp0';
  }

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# notificaciones',
      one: '# notificación',
    );
    return '$_temp0';
  }

  @override
  String get clearAllConfirm =>
      '¿Estás seguro de que deseas eliminar todas las notificaciones?';

  @override
  String get clearedAllNotifications =>
      'Todas las notificaciones han sido eliminadas.';

  @override
  String get groupNotificationsSectionTitle => 'Notificaciones del grupo';

  @override
  String get updateRoleTitle => 'Actualizar rol';

  @override
  String get groupNotificationsSubtitle =>
      'Consulta invitaciones, recordatorios y alertas de este grupo.';

  @override
  String get groupNotificationsEmpty =>
      'Este grupo todavía no tiene notificaciones.';

  @override
  String get groupNotificationsError =>
      'No pudimos cargar las notificaciones de este grupo.';

  @override
  String groupNotificationsTitle(String groupName) {
    return 'Notificaciones de $groupName';
  }

  @override
  String get error => 'Error';

  @override
  String get typeNameOrEmail => 'Escribe un nombre o correo electrónico';

  @override
  String noMatchesForX(String query) {
    return 'No se encontraron resultados para \"$query\"';
  }

  @override
  String get inviteByEmail => 'Invitar por correo';

  @override
  String get noMatchesInvite =>
      'No se encontraron resultados. ¿Quieres invitar por correo?';

  @override
  String get addPeople => 'Agregar personas';

  @override
  String get add => 'Agregar';

  @override
  String get jobTitle => 'Puesto de trabajo';

  @override
  String get addPhoto => 'Añade una foto';

  @override
  String get client => 'Cliente';

  @override
  String get primaryService => 'Servicio principal';

  @override
  String get workVisit => 'Visita de trabajo';

  @override
  String get simpleEvent => 'Evento simple';

  @override
  String get loadingUpcoming => 'Cargando próximos…';

  @override
  String get noUpcomingEvents => 'No hay eventos próximos';

  @override
  String get nothingScheduledSoon =>
      'No hay eventos programados pronto para este grupo.';

  @override
  String get nextUp => 'Próximos';

  @override
  String get upcomingEventsSubtitle => 'Eventos próximos para este grupo';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get untitledEvent => '(sin título)';

  @override
  String get userId => 'ID de usuario';

  @override
  String teamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '1 equipo',
      zero: 'Sin equipos',
    );
    return '$_temp0';
  }

  @override
  String calendarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calendarios',
      one: '1 calendario',
      zero: 'Sin calendarios',
    );
    return '$_temp0';
  }

  @override
  String get nothingScheduledSoonForThisGroup =>
      'No hay nada programado pronto para este grupo.';

  @override
  String get upcomingEventsForThisGroup => 'Eventos próximos de este grupo';

  @override
  String get untitled => '(sin título)';

  @override
  String get allTypes => 'Todos';

  @override
  String get simpleEvents => 'Simple';

  @override
  String get workVisits => 'Trabajo';

  @override
  String get byCategory => 'por categoría';

  @override
  String get sectionInsights => 'Gráficas';

  @override
  String get insightsTitle => 'Gráficas e Informes';

  @override
  String get insightsSubtitle => 'Tiempo invertido por cliente o servicio';

  @override
  String get timeByClient => 'Tiempo por Cliente';

  @override
  String get timeByService => 'Tiempo por Servicio';

  @override
  String get noDataRange => 'No hay datos en este rango';

  @override
  String get dateRange7d => '7d';

  @override
  String get dateRange30d => '30d';

  @override
  String get dateRange3m => '3m';

  @override
  String get dateRange4m => '4m';

  @override
  String get dateRange6m => '6m';

  @override
  String get dateRange1y => '1a';

  @override
  String get dateRangeYTD => 'Año en curso';

  @override
  String get dateRangeCustom => 'Personalizado';

  @override
  String get filterDimensionClients => 'Clientes';

  @override
  String get filterDimensionServices => 'Servicios';

  @override
  String get filterTypeAll => 'Todos';

  @override
  String get filterTypeSimple => 'Simple';

  @override
  String get filterTypeWork => 'Trabajo';

  @override
  String get insightsHintUpcomingOnly =>
      'Mostrando solo datos futuros. Para rangos pasados, habilita la búsqueda por rango en el servidor.';

  @override
  String get logoutConfirmTitle => 'Cerrar sesión';

  @override
  String get logoutConfirmMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get accountSectionTitle => 'Cuenta';

  @override
  String get preferencesSectionTitle => 'Preferencias';

  @override
  String get appVersionLabel => 'Versión de la app';

  @override
  String get roleCoAdmin => 'Co-Administrador';

  @override
  String get leaveGroupQuestion => '¿Seguro que deseas salir de este grupo?';

  @override
  String get removeMembersFirst =>
      'Debes eliminar a todos los miembros antes de borrar el grupo.';

  @override
  String get refreshSuccess => 'Calendario actualizado';

  @override
  String get refreshFailed => 'Error al actualizar';

  @override
  String get shareButtonTooltip => 'Compartir';

  @override
  String get soonLabel => 'Próximamente';

  @override
  String get detailsSectionTitle => 'Detalles';

  @override
  String get workVisitSectionTitle => 'Visita de trabajo';

  @override
  String get rawFieldsSectionTitle => 'Campos sin procesar';

  @override
  String get eventWhenLabel => 'Cuándo';

  @override
  String get clientLabel => 'Cliente';

  @override
  String get servicePrimaryLabel => 'Servicio principal';

  @override
  String get workVisitBadge => 'Visita de trabajo';

  @override
  String get editButtonLabel => 'Editar evento';

  @override
  String get editAction => 'Editar';

  @override
  String get duplicateAction => 'Duplicar';

  @override
  String get analyticsSectionTitle => 'Estadísticas';

  @override
  String get graphsComingSoon => 'Gráficas próximamente';

  @override
  String get timeTrackingEnabled => 'Seguimiento de tiempo habilitado';

  @override
  String get timeTrackingDisabled => 'Seguimiento de tiempo deshabilitado';

  @override
  String get exportSuccess => 'Archivo Excel exportado correctamente';

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String get exportToExcelTooltip => 'Exportar a Excel';

  @override
  String get exportToExcelCta => 'Exportar Excel';

  @override
  String trackHoursFor(Object groupName) {
    return 'Registrar horas para $groupName';
  }

  @override
  String get timeTrackingHeaderHint =>
      'Activa el seguimiento y gestiona a los trabajadores. Exporta una hoja de horas en cualquier momento.';

  @override
  String get enableTrackingCta => 'Habilitar';

  @override
  String get disableTrackingCta => 'Deshabilitar';

  @override
  String get employeesHeader => 'Empleados';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get currencyAllOption => 'Todas';

  @override
  String get workerRequiredError => 'Se requiere al menos un trabajador';

  @override
  String get workersLabel => 'Trabajadores';

  @override
  String get selectWorkersPlaceholder => 'Selecciona trabajadores';

  @override
  String get pickWorkersCta => 'Elegir trabajadores';

  @override
  String get noWorkersAvailable => 'No hay trabajadores disponibles';

  @override
  String get currencyFilterLabel => 'Filtrar por moneda';

  @override
  String get currencyFilterAll => 'Mostrar todas las monedas';

  @override
  String get workerChipRemoveTooltip => 'Quitar trabajador';

  @override
  String get workerPickerTitle => 'Elegir trabajadores';

  @override
  String get workerPickerSave => 'Guardar selección';

  @override
  String get selectAll => 'Seleccionar todos';

  @override
  String get clearSelection => 'Limpiar selección';

  @override
  String get currencyWorkersSectionTitle => 'Trabajadores y moneda';

  @override
  String get currencyWorkersSectionDescription =>
      'Filtra por moneda y elige qué trabajadores incluir.';

  @override
  String get currencyHelperText =>
      'Usa una moneda para acotar la lista rápidamente.';

  @override
  String get workersHelperText => 'Toca para añadir o quitar trabajadores.';

  @override
  String get workersValidationHint =>
      'Elige al menos un trabajador antes de guardar.';

  @override
  String get notesLabel => 'Notas';

  @override
  String get notesOptionalHint => 'Añade contexto o déjalo vacío';

  @override
  String get savingLabel => 'Guardando…';

  @override
  String get invalidTimeRange =>
      'La hora de fin debe ser posterior a la hora de inicio.';

  @override
  String get toggleEmptyDays => 'Mostrar/ocultar días sin horas';

  @override
  String didNotWorkDay(Object name) {
    return '$name no trabajó este día';
  }

  @override
  String daysMissedAll(int count) {
    return '$count días sin horas';
  }

  @override
  String daysMissedNoSunday(int count) {
    return '$count días sin horas (lun-sáb)';
  }

  @override
  String avgHoursPerDayWorked(String hours) {
    return 'Promedio $hours h/día trabajadas';
  }

  @override
  String didNotWorkSunday(String name) {
    return '$name no registró horas (domingo)';
  }

  @override
  String daysWorked(int count) {
    return '$count días trabajados';
  }

  @override
  String sundaysWorked(int count) {
    return '$count domingos trabajados';
  }

  @override
  String avgHoursPerDayWorkedWithCount(String hours, int count) {
    return 'Promedio $hours h/día en $count días';
  }

  @override
  String get unknownWorker => 'Trabajador sin nombre';

  @override
  String get noTrackedYet => 'Aún no se ha registrado tiempo';

  @override
  String trackedTotal(Object tracked) {
    return 'Registrado: $tracked';
  }

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get noWorkersYetTitle => 'Aún no hay trabajadores';

  @override
  String get noWorkersYetSubtitle =>
      'Habilita el seguimiento para comenzar a contar las horas y añadir trabajadores.';

  @override
  String get timeTrackingTitle => 'Seguimiento de tiempo';

  @override
  String get sectionWorkersHours => 'Horas del personal';

  @override
  String get sectionBusinessHours => 'Horario laboral';

  @override
  String get businessHoursAdminSubtitle =>
      'Define la franja en la que los miembros pueden programar eventos.';

  @override
  String get businessHoursMemberSubtitle =>
      'Los eventos deben crearse dentro de este horario.';

  @override
  String get businessHoursUnset => 'Aún no configurado';

  @override
  String businessHoursRange(String start, String end, String timezone) {
    return '$start – $end · $timezone';
  }

  @override
  String get businessHoursEdit => 'Editar';

  @override
  String get businessHoursSave => 'Guardar horario';

  @override
  String get businessHoursReset => 'Limpiar horario';

  @override
  String get businessHoursTimezoneLabel => 'Zona horaria';

  @override
  String get businessHoursTimezoneHint => 'Ejemplo: Europe/Madrid';

  @override
  String get businessHoursPartialError =>
      'Define hora de inicio y fin para guardar.';

  @override
  String get businessHoursStartLabel => 'Hora de inicio';

  @override
  String get businessHoursEndLabel => 'Hora de fin';

  @override
  String get businessHoursUpdateSuccess => 'Horario laboral actualizado';

  @override
  String get businessHoursUpdateError =>
      'No se pudo actualizar el horario laboral';

  @override
  String get selectMonthPrompt =>
      'Porfavor, selecciona un mes para ver los registros.';

  @override
  String businessHoursValidationMessage(
      String start, String end, String timezone) {
    return 'Los eventos deben ocurrir entre $start y $end ($timezone).';
  }

  @override
  String get timeTrackingDisabledTitle =>
      'El seguimiento de tiempo está desactivado';

  @override
  String get timeTrackingDisabledSubtitle =>
      'Actívalo para comenzar a registrar las horas de tu equipo.';

  @override
  String get createWorkerTitle => 'Crear trabajador';

  @override
  String get linkExistingUserLabel => 'Vincular a un usuario existente';

  @override
  String get linkExistingUserHint =>
      'Si el trabajador ya tiene cuenta, vincúlala aquí.';

  @override
  String get userIdLabel => 'ID de usuario';

  @override
  String get userIdHint => 'Pega el ID del usuario existente';

  @override
  String get userIdRequired =>
      'El ID de usuario es obligatorio al vincular una cuenta.';

  @override
  String get displayNameLabel => 'Nombre';

  @override
  String get displayNameHint => 'Introduce el nombre del trabajador';

  @override
  String get displayNameRequired =>
      'El nombre es obligatorio para trabajadores externos.';

  @override
  String get roleLabel => 'Rol';

  @override
  String get roleHint => 'Ejemplo: Barista';

  @override
  String get hourlyRateLabel => 'Tarifa por hora';

  @override
  String get hourlyRateHint => 'Ejemplo: 15.00';

  @override
  String get saveWorkerCta => 'Guardar trabajador';

  @override
  String get workerCreated => '¡Trabajador creado con éxito!';

  @override
  String get createWorkerCta => 'Agregar trabajador';

  @override
  String get createTimeEntryTitle => 'Registrar horas';

  @override
  String get workerLabel => 'Trabajador';

  @override
  String get workerRequired => 'Seleccione un trabajador.';

  @override
  String get startLabel => 'Hora de inicio';

  @override
  String get endLabel => 'Hora de fin';

  @override
  String get notesHint => 'Notas opcionales sobre este trabajador';

  @override
  String get saveTimeEntryCta => 'Guardar registro';

  @override
  String get timeEntryCreated => '¡Horas registradas correctamente!';

  @override
  String get addTimeEntryCta => 'Registrar horas';

  @override
  String get timeTrackingActionsCta => 'Acciones';

  @override
  String get noTimeEntriesYetTitle => 'Aún no hay registros de tiempo';

  @override
  String get noTimeEntriesYetSubtitle =>
      'Agrega tus primeras horas registradas para este trabajador.';

  @override
  String get inProgress => 'En progreso';

  @override
  String get totalEntries => 'Entradas';

  @override
  String get totalHours => 'Horas';

  @override
  String get ongoing => 'En curso';

  @override
  String get errorLoadingData => 'Error cargando datos';

  @override
  String get totalEarnings => 'Total Ganado';

  @override
  String get editWorker => 'Editar trabajador';

  @override
  String get linkedUser => 'Usuario vinculado';

  @override
  String get externalWorker => 'Trabajador externo';

  @override
  String get viewWorker => 'Ver trabajador';

  @override
  String get workerUpdated => 'Trabajador actualizado';

  @override
  String get workerNameLabel => 'Nombre';

  @override
  String get statusLabel => 'Estado';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusInactive => 'Inactivo';

  @override
  String get invalidRate => 'Introduce una tarifa válida';

  @override
  String get editTimeEntry => 'Editar registro de tiempo';

  @override
  String get startTime => 'Hora de inicio';

  @override
  String get endTime => 'Hora de fin';

  @override
  String get breakMinutesLabel => 'Descanso (minutos)';

  @override
  String get timeEntryUpdated => 'Registro de tiempo actualizado correctamente';

  @override
  String get pickStartTime => 'Seleccionar hora de inicio';

  @override
  String get pickEndTime => 'Seleccionar hora de fin';

  @override
  String get noTimeEntries => 'Aún no hay registros de tiempo.';

  @override
  String totalHoursFormat(Object hours, Object minutes) {
    return 'Total: ${hours}h ${minutes}m';
  }

  @override
  String totalHoursAndPayFormat(Object hours, Object pay) {
    return 'Total: ${hours}h – $pay';
  }

  @override
  String get pickMonth => 'Selecciona el mes';

  @override
  String get selectMonthFirst => 'Seleccionar mes';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get deletedSuccessfully => 'Eliminado correctamente';

  @override
  String get areYouSureDelete =>
      '¿Seguro que quieres eliminar este parte de tiempo?';

  @override
  String get entries => 'partes';

  @override
  String get exportExcel => 'Exportar';

  @override
  String get exportReady => 'Exportación lista — elige dónde compartir/guardar';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get info => 'Info';

  @override
  String get overviewInfoTitle => 'Resumen mensual';

  @override
  String get overviewInfoBody =>
      'Cada tarjeta muestra el mes, horas totales y pago de este trabajador. Toca un mes para ver los partes detallados. Usa las flechas para cambiar de año. Desliza hacia abajo para actualizar.';

  @override
  String get hours => 'Horas';

  @override
  String get pay => 'Pago';

  @override
  String get tipTapMonthToOpen => 'Toca un mes para ver detalles';

  @override
  String get tipPullToRefresh => 'Desliza hacia abajo para actualizar';

  @override
  String get addWorker => 'Añadir trabajador';

  @override
  String get addWorkerSubtitle =>
      'Crea un perfil para empezar a registrar horas y pagos.';

  @override
  String get membersInfoAccepted => 'Usuarios que forman parte de este grupo.';

  @override
  String get membersInfoPending =>
      'Invitaciones enviadas y a la espera de aceptación.';

  @override
  String get membersInfoNotAccepted =>
      'Invitaciones rechazadas, revocadas o caducadas.';

  @override
  String get contact => 'Contacto';

  @override
  String get e_gJohnDoe => 'p.ej., Corte básico';

  @override
  String get e_gPhone => 'p.ej., +34 600-123-456';

  @override
  String get e_gEmail => 'p.ej., juan.perez@ejemplo.com';

  @override
  String get clientWillBeActive => 'El cliente estará activo';

  @override
  String get clientWillBeInactive => 'El cliente estará inactivo';

  @override
  String get noContactInfo => 'Sin datos de contacto';

  @override
  String get activeStatus => 'Activo';

  @override
  String get inactiveStatus => 'Inactivo';

  @override
  String get serviceWillBeActive => 'El servicio estará activo';

  @override
  String get serviceWillBeInactive => 'El servicio estará inactivo';

  @override
  String get chooseType => 'Elige tipo';

  @override
  String get simpleEventHint =>
      'Crea un evento rápido sin seleccionar cliente/servicio.';

  @override
  String get workVisitHint =>
      'Registra una visita seleccionando un cliente y uno o más servicios.';

  @override
  String get color => 'Color';

  @override
  String get date => 'Fecha';

  @override
  String get assignedUsers => 'Usuarios asignados';

  @override
  String get repetition => 'Repetición';

  @override
  String get category => 'Categoría';

  @override
  String get workVisitHintShort =>
      'Elige un cliente y servicios para esta visita.';

  @override
  String get simpleEventHintShort => 'Evento simple sin cliente ni servicio.';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get newSubcategory => 'Nueva subcategoría';

  @override
  String failedToCreate(String error) {
    return 'No se pudo crear: $error';
  }

  @override
  String get noCategoriesYet => 'Aún no hay categorías';

  @override
  String get addCategory => 'Agregar categoría';

  @override
  String get addSubcategory => 'Agregar subcategoría';

  @override
  String get subcategory => 'Subcategoría';

  @override
  String get newEvent => 'Nuevo evento ';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get noGroupAvailable => 'No hay grupo disponible';

  @override
  String get tabDay => 'Día';

  @override
  String get tabWeek => 'Semana';

  @override
  String get tabMonth => 'Mes';

  @override
  String get tabAgenda => 'Agenda';

  @override
  String get refreshButton => 'Actualizar';

  @override
  String get titleHint => 'Itroduce el titulo';

  @override
  String get descriptionHint => 'Introduce la descripcion';

  @override
  String get noteHint => 'Introduce la nota';

  @override
  String get services => 'Servicios Adicionales';

  @override
  String get noWorkVisitData =>
      'No hay datos de visita de trabajo disponibles.';

  @override
  String get roleAdministrator => 'Administrador';

  @override
  String get roleCoAdministrator => 'Co-administrador';

  @override
  String get roleGuest => 'Invitado';

  @override
  String get viewMembers => 'Ver miembros';

  @override
  String get monthJanuary => 'enero';

  @override
  String get monthFebruary => 'febrero';

  @override
  String get monthMarch => 'marzo';

  @override
  String get monthApril => 'abril';

  @override
  String get monthMay => 'mayo';

  @override
  String get monthJune => 'junio';

  @override
  String get monthJuly => 'julio';

  @override
  String get monthAugust => 'agosto';

  @override
  String get monthSeptember => 'septiembre';

  @override
  String get monthOctober => 'octubre';

  @override
  String get monthNovember => 'noviembre';

  @override
  String get monthDecember => 'diciembre';

  @override
  String monthYearFormat(Object month, Object year) {
    return '$month de $year';
  }

  @override
  String get groupDescriptionHint => 'Introduce el objetivo de este grupo';

  @override
  String get groupNameTooShort => 'Nombre del grupo muy corto';

  @override
  String get groupNameHint => 'Introduce el nombre del grupo';

  @override
  String get reviewUsersTitle => 'Miembros — Revisión y Roles';

  @override
  String get tabUpdateRoles => 'Actualizar roles';

  @override
  String get tabAddUsers => 'Agregar usuarios';

  @override
  String get done => 'Listo';

  @override
  String get selectedLabel => 'Seleccionados';

  @override
  String loadMore(Object count) {
    return 'Cargar más ($count)';
  }

  @override
  String addUsersCount(Object count) {
    return 'Agregar usuarios ($count)';
  }

  @override
  String get ok => 'Aceptar';

  @override
  String get searchMinChars => 'Escribe al menos 3 caracteres';

  @override
  String get errorSearchingUser => 'Error al buscar usuario';

  @override
  String get errorAddingUser => 'Error al agregar usuario';

  @override
  String get userAlreadyAdded => 'El usuario ya es miembro';

  @override
  String get userAlreadyPending => 'El usuario ya está en la selección';

  @override
  String selectedCommitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count usuarios',
      one: 'Se añadió 1 usuario',
      zero: 'No se añadieron usuarios',
    );
    return '$_temp0';
  }

  @override
  String get online => 'online';

  @override
  String get addUsersHelperText =>
      'Busca y prepara a los miembros que se añadirán. Puedes definir las funciones de cada usuario antes de enviar los cambios.';

  @override
  String get updateRolesHelperText =>
      'Revisa los miembros y ajusta los roles. Toca una tarjeta para cambiar el rol.';

  @override
  String get membersHelperText =>
      'Navega por los miembros por estado, revisa invitaciones y gestiona roles.';

  @override
  String get createGroup => 'Crear grupo';

  @override
  String get editImage => 'Editar';

  @override
  String get tapToChangePhoto => 'Toca para cambiar la foto del grupo';

  @override
  String get tapToAddPhoto => 'Toca para añadir foto del grupo';

  @override
  String get groupSaved => 'Grupo guardado';

  @override
  String get manageGroup => 'Gestiona el grupo';

  @override
  String get hey => 'Hola';

  @override
  String get youAreThe => 'eres el';

  @override
  String get ofThisGroup => 'de este grupo';

  @override
  String get youHaveSuperPowersHere => '¡Tienes súper poderes en este grupo!';

  @override
  String get roleOwnerBullet1 =>
      'Cambiar la configuración y las funciones del grupo';

  @override
  String get roleOwnerBullet2 => 'Gestionar la facturación y la suscripción';

  @override
  String get roleOwnerBullet3 =>
      'Agregar o eliminar co-administradores y miembros';

  @override
  String get roleOwnerBullet4 => 'Ver y editar todos los calendarios y eventos';

  @override
  String get roleOwnerBullet5 => 'Eliminar o transferir el grupo';

  @override
  String get roleCoAdminBullet1 => 'Crear, editar y eliminar eventos del grupo';

  @override
  String get roleCoAdminBullet2 => 'Gestionar servicios y clientes';

  @override
  String get roleCoAdminBullet3 =>
      'Invitar o eliminar miembros (excepto el propietario)';

  @override
  String get roleCoAdminBullet4 =>
      'Configurar notificaciones y horarios de trabajo';

  @override
  String get roleMemberBullet1 => 'Ver tus eventos asignados';

  @override
  String get roleMemberBullet2 => 'Marcar visitas o tareas como realizadas';

  @override
  String get roleMemberBullet3 => 'Agregar notas y comentarios';

  @override
  String get groupSettingsTitle => 'Ajustes del grupo';

  @override
  String get groupSettingsOwnerBannerOwner =>
      'Eres el propietario de este grupo. Puedes administrar todos los ajustes desde aquí.';

  @override
  String get groupSettingsOwnerBannerNotOwner =>
      'Solo el propietario del grupo puede actualizar estos ajustes.';

  @override
  String get groupSettingsOverviewTitle => 'Resumen';

  @override
  String get groupSettingsOverviewSubtitle =>
      'Información general de este grupo.';

  @override
  String get groupSettingsDescriptionLabel => 'Descripción';

  @override
  String get groupSettingsNoDescription => 'No se proporcionó descripción';

  @override
  String get groupSettingsOwnerIdLabel => 'ID del propietario';

  @override
  String get groupSettingsCreatedOnLabel => 'Creado el';

  @override
  String get groupSettingsMemberCountLabel => 'Número de miembros';

  @override
  String get groupSettingsUserRolesTitle => 'Roles de usuario';

  @override
  String get groupSettingsUserRolesSubtitle =>
      'Permisos para los usuarios de este grupo.';

  @override
  String get groupSettingsNoRoles => 'Aún no hay roles específicos asignados.';

  @override
  String get groupSettingsUserIdLabel => 'ID de usuario:';

  @override
  String get groupSettingsRoleLabel => 'Rol:';

  @override
  String get groupSettingsInvitationsTitle => 'Invitaciones';

  @override
  String get groupSettingsInvitationsSubtitle =>
      'Invita a nuevos miembros o gestiona invitaciones pendientes.';

  @override
  String get groupSettingsInvitationsInfo =>
      'Las invitaciones se gestionan por separado.';

  @override
  String get groupSettingsViewInvitations => 'Ver invitaciones';

  @override
  String get groupSettingsDangerZoneTitle => 'Zona de peligro';

  @override
  String get groupSettingsDangerZoneOwner =>
      'Eliminar este grupo es permanente y no se puede deshacer.';

  @override
  String get groupSettingsDangerZoneNonOwner =>
      'Solo el propietario del grupo puede eliminarlo.';

  @override
  String get groupInfo => 'Información del grupo';

  @override
  String get groupInfoSubtitle => 'Nombre, descripción y detalles básicos';

  @override
  String get notificationsSubtitle => 'Alertas, recordatorios y preferencias';

  @override
  String get billingDetails => 'Detalles de facturación';

  @override
  String get billingDetailsSubtitle =>
      'Datos para facturas (razón social, CIF, dirección y contacto).';

  @override
  String get billingLegalName => 'Razón social';

  @override
  String get billingTaxId => 'NIF/CIF';

  @override
  String get billingTaxIdHelper => 'Se usa en facturas y PDFs.';

  @override
  String get addressStreet => 'Calle';

  @override
  String get addressExtra => 'Complemento de dirección';

  @override
  String get addressCity => 'Ciudad';

  @override
  String get addressProvince => 'Provincia/Estado';

  @override
  String get addressPostalCode => 'Código postal';

  @override
  String get addressCountry => 'País';

  @override
  String get billingEmailLabel => 'Email de facturación';

  @override
  String get billingPhoneLabel => 'Teléfono de facturación';

  @override
  String get billingComplete => 'Facturación lista';

  @override
  String get billingMissing => 'Faltan datos de facturación';

  @override
  String billingProgressLabel(Object completed, Object total) {
    return '$completed/$total completados';
  }

  @override
  String get billingProfileTitle => 'Perfil de facturación';

  @override
  String get billingProfileEmpty =>
      'Añade los datos del emisor (razón social, CIF, dirección, IVA, IBAN) para emitir facturas.';

  @override
  String get billingWebsite => 'Sitio web';

  @override
  String get billingIban => 'IBAN';

  @override
  String get billingIbanHelper =>
      'Se muestra en facturas para transferencia bancaria.';

  @override
  String get billingTaxRate => 'IVA';

  @override
  String get billingTaxRateHelper => 'IVA por defecto (0–100).';

  @override
  String get billingCurrency => 'Moneda';

  @override
  String get billingCurrencyHelper => 'Moneda por defecto (p. ej. EUR).';

  @override
  String get billingLanguage => 'Idioma';

  @override
  String get billingLanguageHelper => 'Código de idioma (p. ej. es, en).';

  @override
  String get billingAddress => 'Dirección';

  @override
  String get billingProfileSaved => 'Perfil de facturación guardado';

  @override
  String get billingLogoUploadTitle => 'Subir logo de la empresa';

  @override
  String get billingLogoUploadBody =>
      'Selecciona un logo PNG o JPG (máx. 15 MB). Este logo aparecerá en facturas y pies de email.';

  @override
  String get billingLogoUploadSelectFile => 'Seleccionar archivo';

  @override
  String get billingLogoUploadCta => 'Subir';

  @override
  String get billingLogoUploadSuccess => 'Logo subido correctamente.';

  @override
  String get billingLogoUploadError =>
      'El logo debe ser PNG o JPG y no superar 15 MB.';

  @override
  String get createInvoiceCta => 'Crear factura';

  @override
  String get invoiceCreated => 'Factura creada';

  @override
  String get noInvoicesYet => 'Aún no hay facturas';

  @override
  String get noInvoicesYetSubtitle =>
      'Crea tu primera factura para organizar la facturación.';

  @override
  String get invoicesListTitle => 'Facturas';

  @override
  String get invoicesNavLabel => 'Facturas';

  @override
  String get invoicesNavSubtitle => 'Crear y gestionar facturas';

  @override
  String invoicesTitle(String groupName) {
    return 'Facturas · $groupName';
  }

  @override
  String get openInvoicesWorkspace => 'Abrir espacio de facturas';

  @override
  String get invoiceNumberLabel => 'Número de factura (NNN-AA)';

  @override
  String invoiceNumberHelper(String year) {
    return 'El sufijo de año está fijado a $year. Introduce los 3 dígitos.';
  }

  @override
  String get invoiceNumberInvalid =>
      'Usa tres dígitos (ej. 001). El año se fija al AA actual.';

  @override
  String get bulkDownloadInvoiceNumberRequired =>
      'Introduce al menos un numero de factura.';

  @override
  String get bulkDownloadInvoiceNumberInvalidFormat =>
      'Usa solo letras, numeros, guion, barra, guion bajo o punto.';

  @override
  String get bulkDownloadInvoiceNumberRangeInvalid =>
      'El numero de factura inicial debe ser menor o igual que el final.';

  @override
  String get invoiceClientLabel => 'Cliente';

  @override
  String get invoiceClientRequired => 'Elige un cliente';

  @override
  String get invoicePdfUrl => 'URL del PDF';

  @override
  String get invoiceRegisteredAt => 'Registrada el';

  @override
  String get invoiceRegisteredUnknown => 'Sin registrar';

  @override
  String get invoiceParties => 'Partes';

  @override
  String get invoiceClientSection => 'Datos de cliente';

  @override
  String get invoiceLinesTitle => 'Líneas de factura';

  @override
  String get invoiceBlocksTitle => 'Bloques de factura';

  @override
  String get invoiceBlocksModeBlocks => 'Bloques';

  @override
  String get invoiceBlocksModeLines => 'Líneas';

  @override
  String get invoiceLinesModeManual => 'Manual';

  @override
  String get invoiceLinesModePhoto => 'Foto';

  @override
  String get invoiceLinesModeJson => 'JSON';

  @override
  String get invoiceLinesPhotoTitle => 'Extraer lineas desde foto de factura';

  @override
  String get invoiceLinesPhotoSubtitle =>
      'Sube una captura o imagen de la factura y aplica las lineas detectadas al editor.';

  @override
  String get invoiceLinesPhotoApply => 'Aplicar a lineas';

  @override
  String get invoiceLinesPhotoClear => 'Limpiar';

  @override
  String get invoiceLinesPhotoExtracting => 'Extrayendo...';

  @override
  String invoiceLinesPhotoExtractedCount(Object count) {
    return '$count linea(s) extraida(s)';
  }

  @override
  String get invoiceLineEvidenceAttach => 'Adjuntar evidencia';

  @override
  String get invoiceLineEvidenceOpen => 'Abrir evidencia';

  @override
  String get invoiceLineEvidenceDelete => 'Eliminar evidencia';

  @override
  String get invoiceLineEvidenceNoId =>
      'Guarda el borrador primero para adjuntar evidencia.';

  @override
  String get invoiceLineEvidenceAttached =>
      'Evidencia adjuntada correctamente.';

  @override
  String get invoiceLineEvidenceRemoved => 'Evidencia eliminada.';

  @override
  String get invoiceLineEvidenceAttachFailed =>
      'No se pudo adjuntar la evidencia.';

  @override
  String get invoiceLineEvidenceOpenFailed => 'No se pudo abrir la evidencia.';

  @override
  String get invoiceLineEvidenceDeleteFailed =>
      'No se pudo eliminar la evidencia.';

  @override
  String get invoiceLinesJsonImportTitle => 'Importar lineas desde JSON';

  @override
  String get invoiceLinesJsonImportSubtitle =>
      'Pega un JSON estructurado con draftLines o sube un archivo .json para crear lineas al instante.';

  @override
  String get invoiceLinesJsonImportModePaste => 'Pegar JSON';

  @override
  String get invoiceLinesJsonImportModeFile => 'Subir archivo';

  @override
  String get invoiceLinesJsonImportInputHint =>
      'Pega el payload JSON con draftLines...';

  @override
  String get invoiceLinesJsonImportPickFile => 'Seleccionar archivo JSON';

  @override
  String get invoiceLinesJsonImportNoFile =>
      'No hay archivo JSON seleccionado.';

  @override
  String get invoiceLinesJsonImportOverwrite =>
      'Sobrescribir lineas existentes';

  @override
  String get invoiceLinesJsonImportDefaultTaxRate => 'IVA por defecto';

  @override
  String get invoiceLinesJsonImportApply => 'Importar lineas';

  @override
  String get invoiceLinesJsonImportGetPrompt => 'Obtener prompt LLM';

  @override
  String get invoiceLinesJsonImportPromptCopied =>
      'Prompt copiado al portapapeles.';

  @override
  String get invoiceLinesJsonImportInvalidPayload =>
      'JSON invalido. Debe incluir draftLines con elementos.';

  @override
  String get invoiceLinesJsonImportGenericError =>
      'No se pudieron importar las lineas JSON.';

  @override
  String invoiceLinesJsonImportSuccess(Object count) {
    return 'Se importaron $count linea(s).';
  }

  @override
  String get jsonAutoRepairAppliedSnack =>
      'JSON corregido automáticamente antes de importar.';

  @override
  String get invoiceAddBlock => 'Agregar bloque';

  @override
  String get invoiceBlocksInfoTooltip =>
      'Los bloques permiten mezclar partidas con encabezados, notas y listas. Solo los ítems facturables afectan los totales.';

  @override
  String get invoiceBlocksEmptyMessage =>
      'Crea tu factura por bloques (Fecha, Sección, Ítems...)';

  @override
  String get invoiceBlocksQuickItem => 'Ítem';

  @override
  String get invoiceBlocksQuickDate => 'Fecha';

  @override
  String get invoiceHeaderCompactCta => 'Compactar cabecera';

  @override
  String get invoiceHeaderExpandCta => 'Expandir cabecera';

  @override
  String get invoiceBlockAdvancedShowCta => 'Avanzado';

  @override
  String get invoiceBlockAdvancedHideCta => 'Ocultar avanzado';

  @override
  String get invoiceAddBlockMore => 'Más...';

  @override
  String get invoiceAddBlockRecommended => 'Recomendado';

  @override
  String get invoiceAddBlockFooterInsert =>
      'Se añadirá debajo del bloque actual';

  @override
  String get invoiceAddBlockFooterOutsideWrapper =>
      'Se añadirá fuera del bloque agrupado';

  @override
  String get invoiceWrapperAddInsideLabel => 'Añadir dentro';

  @override
  String get invoiceBlockDateAutoFormatCta => 'Usar formato automático';

  @override
  String get invoiceBlockTypeLabel => 'Tipo de bloque';

  @override
  String get invoiceBlockTypeItem => 'Ítem';

  @override
  String get invoiceBlockTypeDate => 'Fecha';

  @override
  String get invoiceBlockTypeSection => 'Sección';

  @override
  String get invoiceBlockTypeSubsection => 'Subsección';

  @override
  String get invoiceBlockTypeDivider => 'Divisor';

  @override
  String get invoiceBlockTypeNote => 'Nota';

  @override
  String get invoiceBlockTypeChecklist => 'Lista';

  @override
  String get invoiceBlockSkuLabel => 'SKU';

  @override
  String get invoiceBlockUnitLabel => 'Unidad';

  @override
  String get invoiceBlockLevelLabel => 'Nivel';

  @override
  String get invoiceBlockBillableLabel => 'Ítem facturable';

  @override
  String get invoiceBlockTitleLabelDate => 'Título de fecha';

  @override
  String get invoiceBlockTitleLabelSection => 'Título de sección';

  @override
  String get invoiceBlockTitleLabelSubsection => 'Título de subsección';

  @override
  String get invoiceBlockNoteLabel => 'Nota';

  @override
  String get invoiceBlockChecklistItemLabel => 'Elemento de lista';

  @override
  String get invoiceBlockAddChecklistItem => 'Agregar elemento';

  @override
  String get invoiceBlockMoveUp => 'Subir';

  @override
  String get invoiceBlockMoveDown => 'Bajar';

  @override
  String get invoiceValidationNonNegative => 'Debe ser 0 o mayor';

  @override
  String get invoiceValidationTaxRate => 'El IVA debe estar entre 0 y 100';

  @override
  String get invoiceLinesPlaceholderTitle => 'Líneas de factura pronto';

  @override
  String get invoiceLinesPlaceholderSubtitle =>
      'Aquí verás los conceptos con cantidad, precio, impuesto y totales.';

  @override
  String get unknownClient => 'Cliente desconocido';

  @override
  String get optionalLabel => 'Opcional';

  @override
  String get select => 'Seleccionar';

  @override
  String get change => 'Cambiar';

  @override
  String get stepLabel => 'Paso';

  @override
  String get ofLabel => 'de';

  @override
  String get fieldIsRequired => 'Este campo es obligatorio';

  @override
  String get taxRateShort => 'IVA';

  @override
  String get invoiceStatusLabel => 'Estado';

  @override
  String get statusDraft => 'Borrador';

  @override
  String get statusIssued => 'Emitida';

  @override
  String get statusPaid => 'Pagada';

  @override
  String get invoiceNotesLabel => 'Notas';

  @override
  String get invoiceAddLine => 'Agregar línea';

  @override
  String get invoiceLinesRequired => 'Añade al menos una línea';

  @override
  String get lineDescription => 'Descripción';

  @override
  String get lineQuantity => 'Cantidad';

  @override
  String get lineUnitPrice => 'Precio unitario';

  @override
  String get lineTaxRate => 'Impuesto';

  @override
  String get invoiceTotalLabel => 'Total';

  @override
  String get invoiceTotalsTitle => 'Totales';

  @override
  String get invoiceEditorTitle => 'Editor de facturas';

  @override
  String get invoiceCustomerTitle => 'Cliente';

  @override
  String get invoiceDatesTitle => 'Fechas';

  @override
  String get invoiceDateLabel => 'Fecha de factura';

  @override
  String get invoiceDueDateLabel => 'Fecha de vencimiento';

  @override
  String get invoiceFromLabel => 'Emisor';

  @override
  String get invoiceBillToLabel => 'Facturar a';

  @override
  String get invoiceSelectClientLabel => 'Seleccionar cliente';

  @override
  String get invoiceSubtotalLabel => 'Subtotal';

  @override
  String get invoiceTaxLabel => 'IVA';

  @override
  String get invoiceNoLinesYet => 'Sin líneas';

  @override
  String get invoicePdfGeneratedLabel => 'PDF generado';

  @override
  String get invoicePdfNotGeneratedLabel => 'PDF no generado';

  @override
  String get invoiceIssueCta => 'Emitir factura';

  @override
  String get invoiceSaveDraftCta => 'Guardar borrador';

  @override
  String get invoicePdfCta => 'PDF';

  @override
  String get invoicePdfDownloadCta => 'Descargar PDF';

  @override
  String get invoiceOpenCta => 'Abrir factura';

  @override
  String get invoiceBillingNameTitle => 'Cliente (destinatario)';

  @override
  String get invoiceBillingNameEditCta =>
      'Editar datos de facturación del cliente';

  @override
  String get invoiceBillingNameCurrentLabel => 'Nombre de facturación actual';

  @override
  String get invoiceBillingNameNewLabel => 'Nombre de facturación';

  @override
  String get invoiceBillingNameReasonLabel => 'Motivo (opcional)';

  @override
  String get invoiceBillingNameNewRequired =>
      'El nombre de facturación es obligatorio';

  @override
  String get invoiceBillingNameUpdateSuccess =>
      'Datos de facturación del cliente actualizados';

  @override
  String get invoiceChangeHistoryTitle => 'Cambios';

  @override
  String get invoiceChangeHistoryEmpty => 'Todavía no hay cambios.';

  @override
  String get reasonLabel => 'Motivo';

  @override
  String get updatedByLabel => 'Actualizado por';

  @override
  String get invoicePreviewCta => 'Vista previa (PDF)';

  @override
  String get invoiceSendCta => 'Enviar factura';

  @override
  String get invoiceStepsTitle => 'Pasos';

  @override
  String get invoiceStepCreateTitle => 'Paso 1 - Crear factura';

  @override
  String get invoiceStepCreateShort => 'Crear';

  @override
  String get invoiceStepPreviewTitle => 'Paso 2 - Vista previa';

  @override
  String get invoiceStepPreviewShort => 'Vista previa';

  @override
  String get invoiceStepIssueTitle => 'Paso 3 - Guardar borrador';

  @override
  String get invoiceStepIssueShort => 'Borrador';

  @override
  String get invoiceChecklistClient => 'Cliente seleccionado';

  @override
  String get invoiceChecklistDates => 'Fecha de factura seleccionada';

  @override
  String get invoiceChecklistLines => 'Líneas agregadas';

  @override
  String get invoiceWarningsTitle => 'Advertencias';

  @override
  String get invoiceWarningDueDateBefore =>
      'La fecha de vencimiento es anterior a la fecha de factura';

  @override
  String get invoiceWarningPendingDrafts =>
      'Tienes borradores pendientes. Resuélvelos antes de continuar.';

  @override
  String get invoicePreviewNeedsClient =>
      'Selecciona un cliente para continuar.';

  @override
  String get invoicePreviewNeedsDate =>
      'Selecciona la fecha de factura para continuar.';

  @override
  String get invoicePreviewInvalidDates =>
      'La fecha de vencimiento no puede ser anterior.';

  @override
  String get invoicePreviewNeedsLines =>
      'Agrega al menos una línea con precio para continuar.';

  @override
  String get invoicePreviewNeedsDraft =>
      'Guarda un borrador para generar la vista previa en PDF.';

  @override
  String get invoiceIssueNeedsPreview =>
      'Revisa la factura en vista previa antes de emitirla.';

  @override
  String get invoiceSummaryTitle => 'Resumen';

  @override
  String get invoiceNumberSummaryLabel => 'Número de factura';

  @override
  String get invoicePreviewPendingLabel => 'Vista previa pendiente';

  @override
  String get invoicePreviewReviewedStatus => 'Vista previa revisada';

  @override
  String get invoicePreviewReviewedLabel => 'Has revisado la factura';

  @override
  String get invoiceIssueConfirmTitle => 'Emitir factura';

  @override
  String get invoiceIssueConfirmMessage => 'Esta acción no se puede deshacer.';

  @override
  String get invoiceIssuingLabel => 'Emitiendo…';

  @override
  String get invoiceDetailsShowCta => 'Mostrar detalles';

  @override
  String get invoiceDetailsHideCta => 'Ocultar detalles';

  @override
  String get invoiceClientSearchHint => 'Buscar cliente';

  @override
  String get invoiceNotesShowCta => 'Mostrar';

  @override
  String get invoiceNotesHideCta => 'Ocultar';

  @override
  String get invoiceNotesOptionalLabel => 'Opcional';

  @override
  String get invoiceClientInvoicesThisMonthLabel => 'Facturas este mes';

  @override
  String get clientMissingInvoiceThisMonth => 'Factura pendiente este mes';

  @override
  String get clientInvoiceAllGood => 'Factura emitida este mes';

  @override
  String get clientAllHaveInvoiceTitle => 'Todos los clientes facturados';

  @override
  String get clientInvoiceStatusUnavailableTitle =>
      'Estado de factura no disponible';

  @override
  String get clientNoMatchFiltersTitle => 'Ningún cliente coincide';

  @override
  String get clientAllHaveInvoiceDesc =>
      'Ningún cliente tiene una factura pendiente este mes.';

  @override
  String get clientInvoiceStatusUnavailableDesc =>
      'Los datos de factura aún no están disponibles para estos clientes.';

  @override
  String get clientNoMatchFiltersDesc =>
      'Intenta ajustar la búsqueda o los filtros.';

  @override
  String get clientNoInvoiceIssuedThisMonth => 'Sin factura este mes';

  @override
  String clientLastInvoiceShort(String date) {
    return 'Última: $date';
  }

  @override
  String clientMissingCountThisMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendientes este mes',
      one: '1 pendiente este mes',
      zero: 'Ninguno pendiente',
    );
    return '$_temp0';
  }

  @override
  String clientInvoiceCountThisMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas este mes',
      one: '1 factura este mes',
      zero: 'Sin facturas este mes',
    );
    return '$_temp0';
  }

  @override
  String get invoiceDraftInfoTooltip => 'Info de borradores';

  @override
  String get invoiceDraftInfoTitle => 'Antes de crear un borrador';

  @override
  String get invoiceDraftInfoMessage =>
      'Antes de crear un borrador, asegúrate de no tener borradores pendientes.';

  @override
  String get invoicePendingDraftsLabel => 'Borradores pendientes';

  @override
  String get invoiceFillRequiredFieldsError =>
      'Rellena los campos obligatorios';

  @override
  String invoiceDraftSavedSnack(Object invoiceNumber) {
    return 'Borrador guardado: $invoiceNumber';
  }

  @override
  String get invoiceDraftSavedSnackNoNumber => 'Borrador guardado';

  @override
  String get invoiceDraftSavedSnackTitle => 'Borrador guardado';

  @override
  String get invoiceDraftSavedSnackMessage =>
      'Tu borrador de factura está seguro y listo para continuar después.';

  @override
  String get invoiceDraftUpdatedSnackTitle => 'Borrador actualizado';

  @override
  String get invoiceDraftUpdatedSnackMessage =>
      'Tus últimos cambios se guardaron en este borrador.';

  @override
  String get invoiceDraftSnackDismiss => 'Cerrar';

  @override
  String get invoiceDraftSaveFailedSnack =>
      'No se pudo guardar el borrador. Inténtalo de nuevo.';

  @override
  String get invoiceDraftRemoveTitle => '¿Eliminar borrador?';

  @override
  String get invoiceDraftRemoveMessage => 'Esto eliminará el borrador actual.';

  @override
  String get invoiceDraftRemovedSnack => 'Borrador eliminado';

  @override
  String get invoiceDraftRemoveFailedSnack =>
      'No se pudo eliminar el borrador. Inténtalo de nuevo.';

  @override
  String invoiceBatchIssueSuccessSnack(Object count) {
    return '$count facturas emitidas correctamente';
  }

  @override
  String invoiceBatchIssuePartialSnack(Object issued, Object failed) {
    return '$issued emitidas, $failed con error';
  }

  @override
  String get invoiceIssueDuplicateNumberSnack =>
      'Ese número de factura ya existe en este grupo. Actualiza la lista o edita el número del borrador antes de emitir.';

  @override
  String invoiceIssueDuplicateNumberValueSnack(Object number) {
    return 'El número de factura $number ya existe en este grupo. Actualiza la lista o edita el número del borrador antes de emitir.';
  }

  @override
  String get invoiceBatchIssueErrorsTitle => 'Errores';

  @override
  String invoiceDraftOpenFailed(Object reason) {
    return 'No se pudo abrir el borrador: $reason';
  }

  @override
  String invoiceIssueSuccessSnack(Object invoiceNumber) {
    return 'Factura emitida: $invoiceNumber';
  }

  @override
  String get invoiceIssueFailedSnack =>
      'No se pudo emitir la factura. Inténtalo de nuevo.';

  @override
  String get invoicePdfPreviewFailedSnack =>
      'No se pudo generar la vista previa del PDF. Inténtalo de nuevo.';

  @override
  String get invoiceSortByNumberLabel => 'Ordenar por numero';

  @override
  String get invoiceSortByNumberRecent => 'Mas recientes';

  @override
  String get invoiceSortByNumberAsc => 'Numero (ascendente)';

  @override
  String get invoiceSortByNumberDesc => 'Numero (descendente)';

  @override
  String get invoiceStatusDraft => 'Borrador';

  @override
  String get invoiceStatusSent => 'Enviada';

  @override
  String get invoiceStatusPaid => 'Pagada';

  @override
  String get invoiceStatusOverdue => 'Vencida';

  @override
  String get invoiceStatusCancelled => 'Cancelada';

  @override
  String get invoiceStatusUnknown => 'Desconocida';

  @override
  String get invoiceRecurringLabel => 'Recurrente';

  @override
  String get invoiceEmailSettingsChecking =>
      'Comprobando configuración de email...';

  @override
  String get invoiceEmailSettingsUnavailable =>
      'Configuración de email no disponible';

  @override
  String get invoiceEmailSettingsConfigured =>
      'El envío de emails está configurado ✅';

  @override
  String get invoiceEmailSettingsNeedsSetup =>
      'El envío de emails necesita configuración ⚠️';

  @override
  String get invoiceEmailConfigureCta => 'Configurar email';

  @override
  String get invoiceEmailCopyLinkCta => 'Copiar enlace de la factura';

  @override
  String get invoiceEmailNoSentYet => 'Aún no se ha enviado ningún email';

  @override
  String get invoiceEmailHistoryShowCta => 'Ver historial';

  @override
  String get invoiceEmailHistoryHideCta => 'Ocultar historial';

  @override
  String get invoiceEmailNoHistory => 'Todavía no hay historial de emails.';

  @override
  String get invoiceEmailResentSnack => 'Email de factura reenviado';

  @override
  String get invoiceEmailDetailsTitle => 'Detalles del email';

  @override
  String get invoiceEmailStatusNotSent => 'No enviada';

  @override
  String get invoiceEmailLogToLabel => 'Para';

  @override
  String get invoiceEmailLogCcLabel => 'CC';

  @override
  String get invoiceEmailViewDetailsCta => 'Ver detalles';

  @override
  String get invoiceEmailResendCta => 'Reenviar';

  @override
  String get invoiceEmailResendingLabel => 'Reenviando...';

  @override
  String invoiceEmailSubjectTemplate(Object invoiceNumber) {
    return 'Factura $invoiceNumber';
  }

  @override
  String invoiceEmailMessageTemplate(Object clientName, Object invoiceNumber) {
    return 'Hola $clientName,\n\nAdjuntamos tu factura $invoiceNumber.\n\nGracias,';
  }

  @override
  String get invoiceEmailSheetTitle => 'Enviar factura';

  @override
  String get invoiceEmailSheetSubtitle =>
      'Redacta y previsualiza el email de la factura.';

  @override
  String get invoiceEmailAttachPdfLabel => 'Adjuntar PDF';

  @override
  String get invoiceEmailSendLinkLabel => 'Enviar enlace';

  @override
  String get invoiceEmailTabEdit => 'Editar';

  @override
  String get invoiceEmailTabPreview => 'Vista previa';

  @override
  String get invoiceEmailToLabel => 'Para';

  @override
  String get invoiceEmailCcLabel => 'CC (opcional)';

  @override
  String get invoiceEmailSubjectLabel => 'Asunto';

  @override
  String get invoiceEmailMessageLabel => 'Mensaje';

  @override
  String get invoiceEmailNoPreview =>
      'Aún no hay vista previa. Pulsa actualizar para generar.';

  @override
  String get invoiceEmailPreviewRefreshCta => 'Actualizar vista previa';

  @override
  String get invoiceEmailSendCta => 'Enviar';

  @override
  String get invoiceEmailSendingLabel => 'Enviando...';

  @override
  String invoiceEmailSentAtLabel(Object timestamp) {
    return 'Enviada $timestamp';
  }

  @override
  String get invoiceLogoTitle => 'Logo de factura';

  @override
  String get invoiceLogoSubtitle => 'Se muestra en facturas y PDFs.';

  @override
  String get invoiceLogoUploadCta => 'Subir';

  @override
  String get invoiceLogoUrlLabel => 'URL del logo';

  @override
  String get invoiceLogoEmpty => 'Sin logo';

  @override
  String get invoiceLogoUpdated => 'Logo actualizado';

  @override
  String get groupInvoicesBusinessTitle => 'Empresa';

  @override
  String get groupInvoicesTotalsTitle => 'Totales de facturas';

  @override
  String get groupInvoicesExpandTooltip => 'Expandir';

  @override
  String get groupInvoicesCollapseTooltip => 'Contraer';

  @override
  String get groupInvoicesClientsFlowCta => 'Flujo de facturas por cliente';

  @override
  String get groupInvoicesDraftInvoicesTitle => 'Borradores';

  @override
  String get groupInvoicesSelectInvoiceHint =>
      'Selecciona una factura para ver los detalles';

  @override
  String groupInvoicesTabDrafts(Object count) {
    return 'Borradores ($count)';
  }

  @override
  String groupInvoicesTabInvoices(Object count) {
    return 'Facturas ($count)';
  }

  @override
  String groupInvoicesTotalsInline(Object draftsCount, Object issuedCount) {
    return 'Emitidas: $issuedCount • Borradores: $draftsCount';
  }

  @override
  String groupInvoicesTotalsIssuedButton(Object count) {
    return 'Emitidas: $count';
  }

  @override
  String groupInvoicesTotalsDraftsButton(Object count) {
    return 'Borradores: $count';
  }

  @override
  String get groupInvoicesRemoveDraftTitle => '¿Eliminar borrador?';

  @override
  String get groupInvoicesRemoveInvoiceTitle => '¿Eliminar factura?';

  @override
  String groupInvoicesRemoveInvoiceMessage(Object invoiceNumber) {
    return 'Esto eliminará la factura $invoiceNumber.';
  }

  @override
  String get groupInvoicesRemovedSnack => 'Factura eliminada';

  @override
  String get groupInvoicesInvoiceAlreadyRemovedSnack =>
      'Factura no encontrada (ya eliminada). Actualizando…';

  @override
  String groupInvoicesRemoveFailedSnack(Object reason) {
    return 'No se pudo eliminar la factura: $reason';
  }

  @override
  String get clientsTitle => 'Clientes';

  @override
  String get selectClientFirst =>
      'Selecciona un cliente para ver facturación e invoices';

  @override
  String get clientEntityTypeLabel => 'Tipo de entidad';

  @override
  String get clientEntityTypeHint => 'p. ej. comunidad, empresa, particular';

  @override
  String get clientPropertyKindLabel => 'Tipo de propiedad';

  @override
  String get clientPropertyKindHint => 'p. ej. edificio, apartamento, chalet';

  @override
  String get clientClassificationTitle => 'Clasificación clientes';

  @override
  String get clientClassificationManageCta => 'Administrar';

  @override
  String get clientClassificationManageTitle =>
      'Administrar opciones guardadas';

  @override
  String get clientAddOptionHint => 'Agregar opción (máx. 50)';

  @override
  String get clientClassificationManageHint =>
      'Estas opciones se guardan para el grupo y se pueden reutilizar al asignar tipos a los clientes.';

  @override
  String get clientClassificationSaveCta => 'Guardar';

  @override
  String get clientClassificationSavedSnack => 'Opciones guardadas';

  @override
  String get clientClassificationRebuildCta => 'Reconstruir';

  @override
  String get clientClassificationRebuiltSnack => 'Opciones reconstruidas';

  @override
  String get clientClassificationSectionTitle => 'Clasificación';

  @override
  String get clientClassificationAddTitle => 'Agregar clasificación';

  @override
  String get clientClassificationTypeLabel => 'Tipo';

  @override
  String get clientClassificationNameLabel => 'Nombre';

  @override
  String get clientClassificationSelectHint =>
      'Selecciona una clasificación para ver asignaciones';

  @override
  String clientClassificationAssignedCount(int count) {
    return 'Clientes asignados ($count)';
  }

  @override
  String get clientClassificationNoClients => 'Aún no hay clientes asignados.';

  @override
  String get clientClassificationExpandTooltip => 'Expandir';

  @override
  String get clientClassificationCollapseTooltip => 'Contraer';

  @override
  String get clientHideInactiveChip => 'Ocultar inactivos';

  @override
  String get clientInactiveHiddenChip => 'Inactivos ocultos';

  @override
  String get clientDetailsExpandTooltip => 'Mostrar detalles';

  @override
  String get clientDetailsCollapseTooltip => 'Ocultar detalles';

  @override
  String get clientSearchHint => 'Buscar clientes…';

  @override
  String get clientFiltersTitle => 'Filtros';

  @override
  String get clientFiltersClear => 'Limpiar';

  @override
  String get clientSelectedHiddenByFilters =>
      'El cliente seleccionado está oculto por los filtros';

  @override
  String get clientQuickAssignTitle => 'Asignación rápida';

  @override
  String get clientQuickAssignSubtitle =>
      'Toca para asignar. Toca de nuevo para borrar.';

  @override
  String get clientClassificationUpdatedSnack => 'Cliente actualizado';

  @override
  String get clientBillingMissingTitle => 'Faltan datos de facturación';

  @override
  String clientBillingMissingMessage(String fields) {
    return 'Completa: $fields';
  }

  @override
  String get billingDocumentType => 'Tipo de documento';

  @override
  String get documentTypeInvoice => 'Factura';

  @override
  String get documentTypeReceipt => 'Recibo';

  @override
  String get receiptsTitle => 'Recibos';

  @override
  String get createReceiptCta => 'Crear recibo';

  @override
  String groupReceiptsTabDrafts(Object count) {
    return 'Borradores ($count)';
  }

  @override
  String groupReceiptsTabReceipts(Object count) {
    return 'Recibos ($count)';
  }

  @override
  String get groupReceiptsSelectReceiptHint =>
      'Selecciona un recibo para ver detalles';

  @override
  String get groupReceiptsRemoveDraftTitle => '¿Eliminar borrador de recibo?';

  @override
  String groupReceiptsRemoveDraftMessage(Object receiptNumber) {
    return 'Esto eliminará el recibo $receiptNumber.';
  }

  @override
  String get groupReceiptsRemovedSnack => 'Recibo eliminado';

  @override
  String get groupReceiptsAlreadyRemovedSnack =>
      'Recibo no encontrado (ya eliminado). Actualizando…';

  @override
  String get groupReceiptsCannotRemoveIssuedSnack =>
      'No se puede eliminar un recibo emitido';

  @override
  String groupReceiptsRemoveFailedSnack(Object reason) {
    return 'No se pudo eliminar el recibo: $reason';
  }

  @override
  String get receiptDraftNumberPlaceholder => 'Recibo en borrador';

  @override
  String get receiptDateUnknown => 'Fecha desconocida';

  @override
  String get receiptIssueDateLabel => 'Fecha de emisión';

  @override
  String get receiptLinesTitle => 'Líneas de recibo';

  @override
  String get receiptSummaryTitle => 'Resumen';

  @override
  String get receiptNoLinesYet => 'Aún no hay líneas';

  @override
  String get receiptLineTotalLabel => 'Total';

  @override
  String get receiptSubtotalLabel => 'Subtotal';

  @override
  String get receiptTotalLabel => 'Total';

  @override
  String get receiptIssueCta => 'Emitir recibo';

  @override
  String get receiptLockedHint => 'Los recibos emitidos están bloqueados';

  @override
  String receiptEditorTitle(Object number) {
    return 'Recibo $number';
  }

  @override
  String get receiptEditorFormTitle => 'Recibo';

  @override
  String get receiptSelectClientLabel => 'Selecciona cliente';

  @override
  String get receiptClientRequired => 'Selecciona un cliente primero';

  @override
  String get receiptLinesRequired => 'Agrega al menos una línea';

  @override
  String get receiptNotesHint => 'Notas opcionales';

  @override
  String get receiptDraftSavedSnack => 'Borrador guardado';

  @override
  String get receiptDraftSavedSnackTitle => 'Borrador de recibo guardado';

  @override
  String get receiptDraftSavedSnackMessage =>
      'Tu borrador de recibo está seguro y listo para continuar después.';

  @override
  String get receiptSaveFailed => 'No se pudo guardar el recibo';

  @override
  String get receiptPreviewFailed =>
      'No se pudo previsualizar el PDF del recibo';

  @override
  String get receiptDownloadFailed => 'No se pudo descargar el PDF del recibo';

  @override
  String get receiptIssueConfirmTitle => '¿Emitir recibo?';

  @override
  String get receiptIssueConfirmMessage =>
      'Asignar número final y bloquear el recibo.';

  @override
  String receiptIssueSuccessSnack(Object receiptNumber) {
    return 'Recibo emitido: $receiptNumber';
  }

  @override
  String get receiptIssueFailed => 'No se pudo emitir el recibo';

  @override
  String get preview => 'Vista previa';

  @override
  String get download => 'Descargar';

  @override
  String get saveDraft => 'Guardar borrador';

  @override
  String get addLine => 'Agregar línea';

  @override
  String get statementsTabTitle => 'Importar extractos (Excel)';

  @override
  String get bankProvidersTabTitle => 'Proveedores bancarios';

  @override
  String get statementsImportTabTitle => 'Importar';

  @override
  String get statementsHistoryTabTitle => 'Historial';

  @override
  String get statementsStepUpload => 'Subir archivo';

  @override
  String get statementsStepReview => 'Revisar datos';

  @override
  String get statementsStepConfirm => 'Confirmar importación';

  @override
  String get statementsReviewDisabled =>
      'Sube un archivo para revisar entradas y deduplicación.';

  @override
  String get statementsConfirmHelp =>
      'Revisa el resumen y confirma para finalizar la importación.';

  @override
  String get statementsConfirmDisabled =>
      'Completa la subida para habilitar la confirmación.';

  @override
  String get statementsConfirmAction => 'Confirmar importación';

  @override
  String get statementsConfirmSuccess => 'Importación confirmada.';

  @override
  String get statementsStepDisabledHint =>
      'Completa el paso anterior para continuar.';

  @override
  String get autoStatementImportTitle => 'Habilitar datos automáticos';

  @override
  String get autoStatementImportHelper =>
      'Cuando está activado, importaremos automáticamente tu extracto diario de Caixa en tu cuenta.';

  @override
  String get autoStatementImportUpdateFailed =>
      'No se pudo actualizar la configuración de datos automáticos.';

  @override
  String get statementsDragDropTitle => 'Sube tu extracto';

  @override
  String get statementsDragDropHint =>
      'Arrastra tu archivo aquí o haz clic para seleccionar';

  @override
  String get statementsFormatsHint =>
      'Formatos soportados: .xls, .xlsx · Máx. 10 MB';

  @override
  String get statementsRemoveFile => 'Quitar';

  @override
  String get statementsSecurityNote =>
      '🔒 Tus datos se procesan de forma segura';

  @override
  String get statementsFileTooLarge => 'El archivo supera el límite de 10 MB';

  @override
  String get statementsResultsTitle => 'Resultado de la importación';

  @override
  String get statementsResultsHelp =>
      'Revisa la deduplicación y el emparejamiento de clientes antes de confirmar la importación.';

  @override
  String get statementsResultsEmpty =>
      'Sube un archivo para ver el resultado y la vista previa.';

  @override
  String get statementsDuplicateFileError =>
      'Este archivo ya fue importado (checksum duplicado).';

  @override
  String get statementsFilterYear => 'Año';

  @override
  String get statementsFilterFrom => 'Desde';

  @override
  String get statementsFilterTo => 'Hasta';

  @override
  String get statementsApplyFilters => 'Aplicar filtros';

  @override
  String get statementsClearFilters => 'Limpiar';

  @override
  String get statementsPageSize => 'Tamaño de página';

  @override
  String statementsPageInfo(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get statementsPrevPage => 'Anterior';

  @override
  String get statementsNextPage => 'Siguiente';

  @override
  String get statementsSummaryTitle => 'Resumen';

  @override
  String get statementsSummaryMonthly => 'Mensual';

  @override
  String get statementsSummaryYearly => 'Anual';

  @override
  String get statementsSummaryNet => 'Neto';

  @override
  String get statementsSummaryIncome => 'Ingresos';

  @override
  String get statementsSummaryExpense => 'Gastos';

  @override
  String get statementsSummaryEmpty =>
      'No hay datos de resumen para este rango.';

  @override
  String statementsSummaryLine(String total, String count) {
    return 'total $total • $count movimientos';
  }

  @override
  String get statementsActionViewEntries => 'Ver entradas';

  @override
  String get statementsReprocessTitle => '¿Reprocesar lote?';

  @override
  String get statementsReprocessMessage =>
      'Se volverá a ejecutar el parser usando el mapa de columnas guardado.';

  @override
  String get statementsReprocessAction => 'Reprocesar';

  @override
  String get statementsDeleteTitle => '¿Eliminar lote?';

  @override
  String get statementsDeleteMessage =>
      'Esto eliminará el lote y todas sus entradas de forma permanente.';

  @override
  String get statementsDeleteAction => 'Eliminar';

  @override
  String get statementsCancel => 'Cancelar';

  @override
  String statementsDuplicateSummary(String count) {
    return '$count movimientos duplicados omitidos — Ver detalles';
  }

  @override
  String get statementsViewDetails => 'Ver detalles';

  @override
  String get statementsStatusSuccess => 'Éxito';

  @override
  String get statementsStatusWarning => 'Advertencia';

  @override
  String get statementsShowTechDetails => 'Ver detalles técnicos';

  @override
  String get statementsHideTechDetails => 'Ocultar detalles técnicos';

  @override
  String get statementsTechBatchId => 'ID de lote';

  @override
  String get statementsTechChecksum => 'Checksum';

  @override
  String get statementsTechUploader => 'Subido por';

  @override
  String get statementsCopy => 'Copiar';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get statementsNoImportsHelp =>
      'Cuando importes un archivo, los lotes aparecerán aquí para revisión rápida.';

  @override
  String get statementsDownloadTemplate => 'Descargar plantilla Excel';

  @override
  String get statementsViewExample => 'Ver ejemplo';

  @override
  String get statementsUploadDescription =>
      'Sube extractos XLS/XLSX para analizar, deduplicar y vincular entradas a clientes. Los duplicados se omiten automáticamente y se informan por separado.';

  @override
  String get statementsChooseFile => 'Elegir XLS/XLSX';

  @override
  String get statementsNoFileSelected => 'Ningún archivo seleccionado';

  @override
  String statementsSelectedFile(String fileName) {
    return 'Seleccionado: $fileName';
  }

  @override
  String get statementsUploadParse => 'Subir y procesar';

  @override
  String get statementsUploadFailed => 'Error al subir';

  @override
  String get statementsUploadComplete => 'Carga completa';

  @override
  String get statementsFileReadError =>
      'No se pudieron leer los bytes del archivo';

  @override
  String statementsBatchLabel(String batchId) {
    return 'Lote: $batchId';
  }

  @override
  String statementsSheetLabel(String sheet) {
    return 'Hoja: $sheet';
  }

  @override
  String statementsInsertedLabel(String count) {
    return 'Insertados: $count';
  }

  @override
  String statementsSkippedLabel(String count) {
    return 'Omitidos: $count';
  }

  @override
  String statementsPreviewTitle(int count) {
    return 'Vista previa (primeras $count entradas)';
  }

  @override
  String get statementsNoDescription => '(sin descripción)';

  @override
  String statementsAmountLabel(String amount) {
    return 'importe: $amount';
  }

  @override
  String get statementsPastImports => 'Importaciones anteriores';

  @override
  String get refreshAction => 'Actualizar';

  @override
  String get statementsNoImports => 'Aún no hay importaciones.';

  @override
  String get statementsBatchFallback => 'Lote';

  @override
  String statementsBatchTitle(String batchId) {
    return 'Lote $batchId';
  }

  @override
  String statementsUploadedAt(String uploadedAt) {
    return 'subido: $uploadedAt';
  }

  @override
  String statementsFileLabel(String fileName) {
    return 'archivo: $fileName';
  }

  @override
  String statementsChecksumLabel(String checksum) {
    return 'checksum: $checksum';
  }

  @override
  String statementsUploaderLabel(String uploader) {
    return 'cargado por: $uploader';
  }

  @override
  String statementsEntryCount(String count) {
    return 'entradas: $count';
  }

  @override
  String get statementsBatchEntries => 'Entradas del lote';

  @override
  String statementsBatchChip(String batchId) {
    return 'lote: $batchId';
  }

  @override
  String get statementsSelectBatch =>
      'Selecciona un lote para ver las entradas.';

  @override
  String get statementsHeaderDate => 'Fecha';

  @override
  String get statementsHeaderDescription => 'Descripción';

  @override
  String get statementsHeaderDetails => 'Detalles';

  @override
  String get statementsHeaderAmount => 'Importe';

  @override
  String get statementsHeaderBalance => 'Saldo';

  @override
  String get statementsHeaderClient => 'Cliente';

  @override
  String get statementsHeaderActions => 'Acciones';

  @override
  String get statementsHeaderBatch => 'Lote';

  @override
  String get statementsActionSuggest => 'Sugerir';

  @override
  String get statementsActionLink => 'Vincular';

  @override
  String get statementsUnlinked => 'Sin vincular';

  @override
  String get statementsAllDataTitle => 'Todos los movimientos';

  @override
  String get statementsAllDataSubtitle =>
      'Revisa todos los movimientos, vincula clientes y mantén los datos limpios.';

  @override
  String get statementsAllDataEmpty =>
      'Aún no hay movimientos. Importa un Excel para revisarlos aquí.';

  @override
  String get statementsFiltersTitle => 'Filtros';

  @override
  String get statementsPaginationTitle => 'Paginación';

  @override
  String get statementsPresetsTitle => 'Rangos rápidos';

  @override
  String get statementsPickRange => 'Elegir rango';

  @override
  String get statementsPanelCollapse => 'Ocultar panel de guía';

  @override
  String get statementsPanelExpand => 'Mostrar panel de guía';

  @override
  String get statementsStepContextUploadTitle => 'Paso 1 · Subir archivo';

  @override
  String get statementsStepContextReviewTitle => 'Paso 2 · Revisar datos';

  @override
  String get statementsStepContextConfirmTitle =>
      'Paso 3 · Confirmar importación';

  @override
  String get statementsImportSummaryTitle => 'Resumen de importación';

  @override
  String get statementsConfirmChecklistTitle => 'Checklist final';

  @override
  String get statementsConfirmChecklistItem1 =>
      'Verifica duplicados y totales antes de confirmar.';

  @override
  String get statementsConfirmChecklistItem2 =>
      'Podrás vincular clientes después de importar.';

  @override
  String get statementsPresetThisMonth => 'Este mes';

  @override
  String get statementsPresetLast30Days => 'Últimos 30 días';

  @override
  String get statementsPresetThisYear => 'Este año';

  @override
  String get statementsFiltersActive => 'Filtros activos';

  @override
  String get statementsFiltersNone => 'Sin filtros activos';

  @override
  String get statementsColumnBatchTooltip => 'Id del lote';

  @override
  String get statementsColumnBatchCopy => 'Copiar id del lote';

  @override
  String get statementsActionsTooltipSuggest =>
      'Sugerir cliente según la descripción';

  @override
  String get statementsActionsTooltipLink => 'Vincular un cliente manualmente';

  @override
  String statementsSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get statementsBulkSuggest => 'Sugerir para seleccionados';

  @override
  String get statementsBulkLink => 'Vincular en lote';

  @override
  String get statementsClearSelection => 'Limpiar selección';

  @override
  String statementsBulkSuggestResult(int withSuggestions, int linked) {
    return '$withSuggestions sugerencias encontradas · $linked vinculadas';
  }

  @override
  String get statementsBulkLinkTitle => 'Vincular movimientos seleccionados';

  @override
  String get statementsTotalAmount => 'Importe total';

  @override
  String get statementsTotalCount => 'Total de movimientos';

  @override
  String get statementsLastBalance => 'Saldo más reciente';

  @override
  String statementsLastBalanceDate(String date) {
    return 'al $date';
  }

  @override
  String get statementsNavTitle => 'Banco';

  @override
  String get statementsNavCollapse => 'Contraer menú';

  @override
  String get statementsNavExpand => 'Expandir menú';

  @override
  String get statementsAnalyticsTitle => 'Analíticas de extractos';

  @override
  String get statementsAnalyticsBatch => 'Lote';

  @override
  String get statementsAnalyticsMonth => 'Mes';

  @override
  String get statementsAnalyticsMode => 'Modo';

  @override
  String get statementsAnalyticsCompareMode => 'Comparación';

  @override
  String get statementsAnalyticsCompareTitle => 'Comparación de periodos';

  @override
  String get statementsAnalyticsCompareHelp =>
      'Compara el mes calendario con la ventana de liquidación para cada mes del año seleccionado.';

  @override
  String get statementsAnalyticsComparePickYear =>
      'Selecciona un año para ver la comparación.';

  @override
  String get statementsAnalyticsCompareBoth => 'Ambos';

  @override
  String get statementsAnalyticsCompareCalendar => 'Calendario';

  @override
  String get statementsAnalyticsCompareSettlement => 'Liquidación';

  @override
  String get statementsAnalyticsCompareDelta => 'Diferencia';

  @override
  String get statementsAnalyticsModeCalendar => 'Mes calendario';

  @override
  String get statementsAnalyticsModeSettlement => 'Ventana de liquidación';

  @override
  String statementsAnalyticsModeLabel(Object mode) {
    return 'Modo: $mode';
  }

  @override
  String get statementsAnalyticsSettlementStart => 'Día de inicio';

  @override
  String get statementsAnalyticsSettlementEnd => 'Día de fin';

  @override
  String statementsAnalyticsPeriodLabel(Object from, Object to) {
    return 'Periodo: $from – $to';
  }

  @override
  String get statementsAnalyticsPeriodPending =>
      'Periodo: selecciona año y mes';

  @override
  String get statementsAnalyticsTop => 'Top';

  @override
  String statementsAnalyticsTopHelp(int count) {
    return 'Top $count';
  }

  @override
  String get statementsAnalyticsTrends => 'Tendencias';

  @override
  String get statementsAnalyticsTrendsHelp =>
      'Compara ingresos, gastos y neto en el rango seleccionado.';

  @override
  String get statementsAnalyticsYearAverageTitle => 'Promedio anual';

  @override
  String get statementsAnalyticsYearAveragesTitle =>
      'Promedio mensual de ingresos y gastos por año';

  @override
  String get statementsAnalyticsAverageIncome => 'Ingreso promedio';

  @override
  String get statementsAnalyticsAverageExpense => 'Gasto promedio';

  @override
  String get statementsAnalyticsTotalsTab => 'Totales';

  @override
  String get statementsAnalyticsAverageTab => 'Promedio por movimiento';

  @override
  String get statementsAnalyticsTopMerchants => 'Top comercios';

  @override
  String get statementsAnalyticsTopHelpSubtitle =>
      'Comercios con mayor importe total para los filtros seleccionados.';

  @override
  String get statementsAnalyticsNoData => 'Aún no hay datos analíticos.';

  @override
  String get statementsAnalyticsNoMerchants =>
      'No hay datos de comercios para este rango.';

  @override
  String get statementsAnalyticsNoBatches => 'Aún no hay lotes de extractos.';

  @override
  String get statementsAnalyticsAllBatches => 'Todos los lotes';

  @override
  String get statementsAnalyticsAllYears => 'Todos los años';

  @override
  String get statementsAnalyticsAllMonths => 'Todos los meses';

  @override
  String get statementsAnalyticsNoSelection =>
      'Selecciona un lote para ver analíticas.';

  @override
  String statementsAnalyticsMonthHint(int month) {
    return 'Mes $month seleccionado';
  }

  @override
  String get statementsAnalyticsExpand => 'Ver más';

  @override
  String get statementsAnalyticsCollapse => 'Ver menos';

  @override
  String get statementsFreshnessThreshold => 'Umbral (días)';

  @override
  String get statementsFreshnessLoading => 'Cargando frescura...';

  @override
  String get statementsFreshnessNoData => 'Aún no hay transacciones';

  @override
  String statementsFreshnessStale(Object date, Object days) {
    return 'Último movimiento: $date (hace $days días)';
  }

  @override
  String statementsFreshnessUpToDate(Object date) {
    return 'Al día (Último movimiento: $date)';
  }

  @override
  String get statementsFreshnessSendReminder => 'Enviar recordatorio';

  @override
  String get statementsFreshnessReminderSent => 'Recordatorio enviado';

  @override
  String get statementsFreshnessReminderFailed =>
      'No se pudo enviar el recordatorio';

  @override
  String get statementsFreshnessNotStale =>
      'Los datos no están desactualizados. No se envió ninguna notificación.';

  @override
  String get statementsReminderSettingsTitle =>
      'Configuración de recordatorios';

  @override
  String get statementsReminderSettingsLoading =>
      'Cargando configuración de recordatorios...';

  @override
  String get statementsReminderSettingsAuto => 'Recordatorios automáticos';

  @override
  String get statementsReminderSettingsThreshold => 'Umbral (días)';

  @override
  String get statementsReminderSettingsSaved =>
      'Configuración de recordatorios guardada';

  @override
  String get statementsReminderSettingsFailed =>
      'No se pudo guardar la configuración de recordatorios';

  @override
  String statementsReminderStatusOn(Object days) {
    return 'Recordatorios automáticos ACTIVOS ($days días)';
  }

  @override
  String get statementsReminderStatusOff =>
      'Recordatorios automáticos INACTIVOS';

  @override
  String get statementsReminderStatusUnknown =>
      'Recordatorios automáticos: N/D';

  @override
  String get statementsAllDataSummaryTitle => 'Resumen del rango actual';

  @override
  String get dashboardNavTitle => 'Navegación';

  @override
  String get dashboardNavCollapse => 'Contraer menú';

  @override
  String get dashboardNavExpand => 'Expandir menú';

  @override
  String get groupInvoicesNavCollapse => 'Contraer menú';

  @override
  String get groupInvoicesNavExpand => 'Expandir menú';

  @override
  String get statementsRowDetailsTitle => 'Detalle del movimiento';

  @override
  String statementsRowDetailsSubtitle(String batchId) {
    return 'Lote $batchId';
  }

  @override
  String get statementsRowDetailsRaw => 'Datos en bruto';

  @override
  String get statementsNoSuggestions =>
      'No se encontraron sugerencias de clientes';

  @override
  String get statementsNoInvoiceSuggestions =>
      'No se encontraron facturas coincidentes';

  @override
  String get statementsSuggestedClientsTitle => 'Clientes sugeridos';

  @override
  String get statementsSuggestedInvoicesTitle => 'Facturas sugeridas';

  @override
  String get statementsBestMatchBadge => 'Mejor opción';

  @override
  String get statementsInvoiceAlreadySelected =>
      'Ya seleccionada en otro movimiento';

  @override
  String get statementsInvoiceAlreadyLinkedBadge => 'Ya vinculada';

  @override
  String statementsInvoiceAlreadyLinkedMeta(Object date, Object count) {
    return 'Vinculada en $date · $count vínculo(s)';
  }

  @override
  String get statementsInvoiceAlreadyLinkedTitle => 'Factura ya vinculada';

  @override
  String get statementsInvoiceAlreadyLinkedBody =>
      'Esta factura ya está vinculada a otra transacción. ¿Quieres vincularla también aquí?';

  @override
  String get statementsInvoiceLinkAnyway => 'Vincular de todos modos';

  @override
  String get statementsInvoiceAlreadyLinkedToast =>
      'Esta factura ya estaba vinculada a otra transacción bancaria.';

  @override
  String get statementsInvalidInvoiceToast => 'Factura inválida.';

  @override
  String get statementsInvoiceNotFoundToast => 'Factura no encontrada.';

  @override
  String get statementsRepetitiveInvoiceBadge => 'Factura repetida';

  @override
  String statementsRepetitiveInvoiceTooltip(Object count) {
    return 'Esta factura está vinculada a $count movimientos bancarios.';
  }

  @override
  String statementsRepetitiveInvoiceLinkedToast(Object count) {
    return 'Factura vinculada, pero ya estaba usada en otros movimientos ($count).';
  }

  @override
  String get statementsSuggestionAlreadyLinkedSubtext =>
      'Vinculada en otras transacciones';

  @override
  String get statementsInvoiceSuggestTolerance => 'Tolerancia';

  @override
  String get statementsLinkClientTitle => 'Vincular cliente';

  @override
  String get statementsSearchClients => 'Buscar clientes';

  @override
  String get statementsNoClientsMatch =>
      'Ningún cliente coincide con tu búsqueda';

  @override
  String get statementsClearLink => 'Quitar vínculo';

  @override
  String get statementsUnnamedClient => '(sin nombre)';

  @override
  String get statementsImportExcelTab => 'Excel';

  @override
  String get expenseUploadTitle => 'Subir gasto';

  @override
  String get expenseUploadFileSectionTitle => 'Archivo';

  @override
  String get expenseUploadFileDropHint => 'Arrastra el archivo aquí';

  @override
  String get expenseUploadFileOrLabel => 'o';

  @override
  String get expenseUploadFileSelectPlaceholder => 'Selecciona un archivo';

  @override
  String get expenseUploadFileSelectCta => 'Elegir archivo';

  @override
  String get expenseUploadProviderSavedLabel => 'Proveedor guardado';

  @override
  String get expenseUploadProviderManualOption => 'Proveedor manual';

  @override
  String get expenseUploadProviderSearchPlaceholder => 'Buscar proveedor';

  @override
  String get expenseUploadDataSectionTitle => 'Datos';

  @override
  String get expenseUploadVendorLabel => 'Proveedor';

  @override
  String get expenseUploadIssueDateLabel => 'Fecha emisión';

  @override
  String get expenseUploadDateButtonLabel => 'Fecha';

  @override
  String get expenseUploadTotalLabel => 'Total';

  @override
  String get expenseUploadVendorTaxIdLabel => 'NIF proveedor';

  @override
  String get expenseUploadInvoiceNumberLabel => 'Número factura';

  @override
  String get expenseUploadDueDateLabel => 'Fecha vencimiento';

  @override
  String get expenseUploadTaxTotalLabel => 'IVA total';

  @override
  String get expenseUploadCurrencyLabel => 'Moneda';

  @override
  String get expenseUploadNotesLabel => 'Notas';

  @override
  String get expenseUploadSubmitCta => 'Subir gasto';

  @override
  String get expenseUploadFileHelp =>
      'Después de seleccionar el archivo, completa los datos en Organizar.';

  @override
  String get expenseUploadEmptyList => 'Sin gastos subidos en esta sesión.';

  @override
  String get expenseUploadNewProviderTitle => 'Nuevo proveedor';

  @override
  String get expenseUploadEditProviderTitle => 'Editar proveedor';

  @override
  String get expenseUploadProviderNameLabel => 'Nombre';

  @override
  String get expenseUploadProviderTaxIdLabel => 'NIF';

  @override
  String get expenseUploadProviderEmailLabel => 'Email';

  @override
  String get expenseUploadProviderPhoneLabel => 'Teléfono';

  @override
  String get expenseUploadProviderStreetLabel => 'Calle';

  @override
  String get expenseUploadProviderExtraLabel => 'Extra';

  @override
  String get expenseUploadProviderCityLabel => 'Ciudad';

  @override
  String get expenseUploadProviderProvinceLabel => 'Provincia';

  @override
  String get expenseUploadProviderPostalCodeLabel => 'Código postal';

  @override
  String get expenseUploadProviderCountryLabel => 'País';

  @override
  String get expenseUploadProviderSaveCta => 'Guardar';

  @override
  String get expenseUploadProviderUpdateCta => 'Actualizar';

  @override
  String get expenseUploadProviderClearCta => 'Limpiar';

  @override
  String get expenseUploadProvidersEmpty => 'Sin proveedores';

  @override
  String get expenseUploadProvidersSelectHint => 'Selecciona un proveedor';

  @override
  String get expenseUploadProvidersNoExpenses =>
      'Sin gastos para este proveedor.';

  @override
  String get expenseUploadSelectFileError => 'Selecciona un archivo';

  @override
  String get expenseUploadRequiredFieldsError =>
      'Proveedor y fecha son obligatorios';

  @override
  String get expenseUploadTotalOrLinesError =>
      'Total o líneas son obligatorios';

  @override
  String get expenseUploadLinesRequiredError => 'Las líneas son obligatorias';

  @override
  String get expenseUploadLinesInvalidError =>
      'Completa descripción, cantidad, precio unitario y IVA en todas las líneas';

  @override
  String get expenseUploadInvalidIssueDateError => 'Fecha de emisión inválida';

  @override
  String get expenseUploadSuccessSnack => 'Gasto subido';

  @override
  String get expenseUploadTabOrganize => 'Organizar';

  @override
  String get expenseUploadTabFile => 'Archivo';

  @override
  String get expenseUploadTabList => 'Lista';

  @override
  String get expenseUploadTabUpload => 'Subir';

  @override
  String get expenseUploadBatchFlow =>
      'Flujo batch: sube documentos y luego importa.';

  @override
  String get expenseUploadBatchUploadDocsCta => 'Subir documentos';

  @override
  String get expenseUploadBatchLimits =>
      'Hasta 200 archivos, máximo 10MB cada uno.';

  @override
  String expenseUploadBatchSelectedCount(int count) {
    return '$count documento(s) seleccionado(s).';
  }

  @override
  String get expenseUploadBatchVerificationTitle => 'Verificación';

  @override
  String get expenseUploadBatchWaiting => 'Esperando importación...';

  @override
  String get expenseUploadBatchImportTitle => 'Importar';

  @override
  String get expenseUploadBatchGroupRequired =>
      'Debes seleccionar un grupo antes de importar.';

  @override
  String get expenseUploadBatchImportCta => 'Importar gastos';

  @override
  String get expenseUploadTabByProvider => 'Por proveedor';

  @override
  String get expenseUploadTabProviders => 'Proveedores';

  @override
  String get expenseUploadProvidersListTitle => 'Proveedores';

  @override
  String get expenseUploadProvidersInvoicesTitle => 'Gastos del proveedor';

  @override
  String get expenseUploadLinesTitle => 'Líneas';

  @override
  String get expenseUploadLinesEmpty => 'Sin líneas todavía.';

  @override
  String get expenseUploadLinesAddCta => 'Añadir línea';

  @override
  String get expenseUploadLinesItemLabel => 'Línea';

  @override
  String get expenseUploadLinesDescriptionLabel => 'Descripción';

  @override
  String get expenseUploadLinesQuantityLabel => 'Cantidad';

  @override
  String get expenseUploadLinesUnitPriceLabel => 'Precio unitario';

  @override
  String get expenseUploadLinesTaxRateLabel => 'IVA %';

  @override
  String get expenseUploadLinesSubtotalLabel => 'Base';

  @override
  String get expenseUploadLinesTaxLabel => 'IVA';

  @override
  String get expenseUploadLinesTotalLabel => 'Total';

  @override
  String get expenseUploadTotalAutoHelper =>
      'Calculado automáticamente desde las líneas';

  @override
  String get expenseUploadVatBreakdownTitle => 'Desglose IVA';

  @override
  String get expenseUploadVatRateLabel => 'Tipo';

  @override
  String get expenseUploadVatBaseLabel => 'Base';

  @override
  String get expenseUploadVatTaxLabel => 'IVA';

  @override
  String get vatSummaryMenuLabel => 'Resumen IVA';

  @override
  String get vatSummaryTitle => 'Resumen IVA';

  @override
  String get vatSummaryPrevYear => 'Año anterior';

  @override
  String get vatSummaryNextYear => 'Año siguiente';

  @override
  String get vatSummaryQuarterQ1 => 'T1';

  @override
  String get vatSummaryQuarterQ2 => 'T2';

  @override
  String get vatSummaryQuarterQ3 => 'T3';

  @override
  String get vatSummaryQuarterQ4 => 'T4';

  @override
  String vatSummaryQuarterRangeLabel(String quarter, String range) {
    return 'Trimestre $quarter: $range';
  }

  @override
  String vatSummaryQuarterRangeQ1(Object year) {
    return '1 ene – 31 mar $year';
  }

  @override
  String vatSummaryQuarterRangeQ2(Object year) {
    return '1 abr – 30 jun $year';
  }

  @override
  String vatSummaryQuarterRangeQ3(Object year) {
    return '1 jul – 30 sep $year';
  }

  @override
  String vatSummaryQuarterRangeQ4(Object year) {
    return '1 oct – 31 dic $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ1(Object year) {
    return 'Límite: 20 abr $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ2(Object year) {
    return 'Límite: 20 jul $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ3(Object year) {
    return 'Límite: 20 oct $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ4(Object year) {
    return 'Límite: 30 ene $year';
  }

  @override
  String get vatSummaryNoData => 'Sin resumen IVA disponible.';

  @override
  String get vatSummarySalesTitle => 'Ventas';

  @override
  String get vatSummaryPurchasesTitle => 'Compras';

  @override
  String get vatSummaryNetTitle => 'IVA neto';

  @override
  String get vatSummaryNoRates => 'Sin tipos para este trimestre.';

  @override
  String get vatSummaryRateLabel => 'Tipo';

  @override
  String get vatSummaryBaseLabel => 'Base';

  @override
  String get vatSummaryTaxLabel => 'IVA';

  @override
  String get vatSummaryTotalsLabel => 'Totales';

  @override
  String get vatSummaryProvidersTitle => 'Proveedores';

  @override
  String get vatSummaryProvidersEmpty => 'Sin proveedores para este trimestre.';

  @override
  String get recurringInvoicesTitle => 'Facturas recurrentes';

  @override
  String get recurringInvoicesSubtitle => 'Crea y automatiza la facturación.';

  @override
  String get recurringInvoicesRefreshCta => 'Actualizar';

  @override
  String get recurringInvoicesCreateCta => 'Crear recurrencia';

  @override
  String get recurringInvoicesStatusFilterLabel => 'Estado';

  @override
  String get recurringInvoicesStatusAll => 'Todos';

  @override
  String get recurringInvoicesStatusActive => 'Activas';

  @override
  String get recurringInvoicesStatusPaused => 'Pausadas';

  @override
  String get recurringInvoicesStatusCancelled => 'Canceladas';

  @override
  String get recurringInvoicesStatusCompleted => 'Completadas';

  @override
  String get recurringInvoicesClientFilterLabel => 'Cliente';

  @override
  String get recurringInvoicesDueSoon => 'Vencen pronto';

  @override
  String get recurringInvoicesEmpty => 'No hay recurrencias todavía.';

  @override
  String get recurringInvoicesNextRunLabel => 'Próxima';

  @override
  String get recurringInvoicesPreviewCta => 'Ver próximas facturas';

  @override
  String get recurringInvoicesPauseCta => 'Pausar';

  @override
  String get recurringInvoicesResumeCta => 'Reanudar';

  @override
  String get recurringInvoicesCancelCta => 'Cancelar recurrencia';

  @override
  String get recurringInvoicesRunNowCta => 'Ejecutar ahora';

  @override
  String get recurringInvoicesNoRunsSnack =>
      'No había facturas pendientes para generar.';

  @override
  String recurringInvoicesRunCreatedSnack(Object count) {
    return 'Facturas generadas: $count';
  }

  @override
  String get recurringInvoicesCreateSuccess => 'Recurrencia creada';

  @override
  String get recurringInvoicesCreateFailed =>
      'No se pudo crear la recurrencia. Inténtalo de nuevo.';

  @override
  String get recurringInvoicesChangesNote =>
      'Los cambios solo afectarán a facturas futuras ya que las generadas son un snapshot.';

  @override
  String get recurringInvoicesRuleTab => 'Regla';

  @override
  String get recurringInvoicesTemplateTab => 'Plantilla';

  @override
  String get recurringInvoicesGeneratedTab => 'Generadas';

  @override
  String get recurringInvoicesSeriesInvoicesTitle => 'Facturas de esta serie';

  @override
  String get recurringInvoicesSeriesInvoicesCta => 'Ver facturas generadas';

  @override
  String get recurringInvoicesSeriesInvoicesHint =>
      'Cargar todas las facturas generadas por esta recurrencia.';

  @override
  String get recurringInvoicesSeriesInvoicesEmpty =>
      'Todavía no hay facturas generadas.';

  @override
  String get recurringInvoicesActivityTab => 'Actividad';

  @override
  String get recurringInvoicesSaveRuleCta => 'Guardar regla';

  @override
  String get recurringInvoicesSavingRule => 'Guardando...';

  @override
  String get recurringInvoicesSaveTemplateCta => 'Guardar plantilla';

  @override
  String get recurringInvoicesSavingTemplate => 'Guardando...';

  @override
  String get recurringInvoicesGeneratedHint =>
      'Las facturas generadas aparecerán en Borradores.';

  @override
  String get recurringInvoicesActivityHint =>
      'Actividad disponible próximamente.';

  @override
  String get recurringInvoicesCreateTitle => 'Crear recurrencia';

  @override
  String get recurringInvoicesStepClient => 'Cliente';

  @override
  String get recurringInvoicesStepTemplate => 'Plantilla';

  @override
  String get recurringInvoicesStepSchedule => 'Programación';

  @override
  String get recurringInvoicesStepPreview => 'Vista previa';

  @override
  String get recurringInvoicesNameLabel => 'Nombre';

  @override
  String get recurringInvoicesNameRequired => 'Nombre requerido';

  @override
  String get recurringInvoicesFrequencyLabel => 'Frecuencia';

  @override
  String get recurringInvoicesIntervalLabel => 'Intervalo';

  @override
  String get recurringInvoicesStartLabel => 'Inicio';

  @override
  String get recurringInvoicesTimeLabel => 'Hora';

  @override
  String recurringInvoicesLocalTimeHelper(Object timezone) {
    return 'Se programa según tu hora local ($timezone). Guardamos en UTC automáticamente.';
  }

  @override
  String recurringInvoicesLocalTimeSummary(
      Object local, Object timezone, Object utc) {
    return 'Hora seleccionada: $local ($timezone) · Se guardará: $utc UTC';
  }

  @override
  String get recurringInvoicesEndLabel => 'Finalización';

  @override
  String get recurringInvoicesEndNever => 'Nunca';

  @override
  String get recurringInvoicesEndDate => 'Hasta fecha';

  @override
  String get recurringInvoicesEndCount => 'Número de veces';

  @override
  String get recurringInvoicesEndDateSelect => 'Seleccionar fecha';

  @override
  String recurringInvoicesEndDateLabel(Object date) {
    return 'Hasta: $date';
  }

  @override
  String get recurringInvoicesCountLabel => 'Número de facturas';

  @override
  String get recurringInvoicesBillDayLabel => 'Día de facturación (1-31)';

  @override
  String get recurringInvoicesBillDayHelper =>
      'Si el mes no tiene ese día, se usará el último día del mes.';

  @override
  String get recurringInvoicesWeekDayLabel => 'Día de semana (0-6)';

  @override
  String get recurringInvoicesWeekDayHelper => '0=domingo, 6=sábado.';

  @override
  String get recurringInvoicesTimezoneLabel => 'Zona horaria';

  @override
  String get recurringInvoicesExceptionsLabel => 'Excepciones';

  @override
  String get recurringInvoicesAddExceptionCta => 'Añadir fecha';

  @override
  String get recurringInvoicesNoExceptions => 'Sin excepciones.';

  @override
  String get recurringInvoicesPreviewEmpty =>
      'No hay fechas calculadas todavía.';

  @override
  String get recurringInvoicesPreviewTitle => 'Próximas facturas';

  @override
  String get recurringInvoicesPreviewDialogEmpty => 'No hay fechas calculadas.';

  @override
  String get recurringInvoicesContinueCta => 'Continuar';

  @override
  String get recurringInvoicesBackCta => 'Atrás';

  @override
  String get recurringFrequencyDaily => 'Diaria';

  @override
  String get recurringFrequencyWeekly => 'Semanal';

  @override
  String get recurringFrequencyMonthly => 'Mensual';

  @override
  String get recurringFrequencyYearly => 'Anual';

  @override
  String recurringEveryDays(Object count) {
    return 'Cada $count días';
  }

  @override
  String recurringEveryWeeks(Object count) {
    return 'Cada $count semanas';
  }

  @override
  String recurringEveryMonths(Object count) {
    return 'Cada $count meses';
  }

  @override
  String recurringEveryYears(Object count) {
    return 'Cada $count años';
  }

  @override
  String recurringBillDaySummary(Object day) {
    return 'día $day';
  }

  @override
  String recurringStartFromLabel(Object date) {
    return 'desde $date';
  }

  @override
  String get recurringRuleEmpty => 'Sin programación';

  @override
  String get recurringInvoicesTimezoneSearchHint => 'Buscar zona horaria';

  @override
  String get recurringInvoicesTimezoneUseCta => 'Usar';

  @override
  String get mailDetailTitle => 'Mensaje';

  @override
  String get mailDetailFromLabel => 'De';

  @override
  String get mailDetailToLabel => 'Para';

  @override
  String get mailDetailDateLabel => 'Fecha';

  @override
  String get mailDetailBodyLabel => 'Mensaje';

  @override
  String get mailDetailAttachmentsLabel => 'Adjuntos';

  @override
  String get mailDetailUnknownSender => 'Remitente desconocido';

  @override
  String get mailDetailNoSubject => '(sin asunto)';

  @override
  String get mailDetailNotFound => 'Mensaje no encontrado.';

  @override
  String get mailDetailMarkRead => 'Marcar como leído';

  @override
  String get mailDetailMarkUnread => 'Marcar como no leído';

  @override
  String get mailDetailArchive => 'Archivar';

  @override
  String get mailDetailTrash => 'Papelera';

  @override
  String get mailDetailSpam => 'Spam';

  @override
  String get mailDetailMarkedRead => 'Marcado como leído.';

  @override
  String get mailDetailMarkedUnread => 'Marcado como no leído.';

  @override
  String get mailDetailArchived => 'Archivado.';

  @override
  String get mailDetailTrashed => 'Movido a la papelera.';

  @override
  String get mailDetailSpammed => 'Reportado como spam.';

  @override
  String mailDetailActionFailed(Object error) {
    return 'Acción fallida: $error';
  }

  @override
  String mailDetailDownloadFailed(Object error) {
    return 'Descarga fallida: $error';
  }

  @override
  String get mailDetailDownloadUnsupported =>
      'Las descargas solo están disponibles en la web por ahora.';

  @override
  String get mailDetailDownloadTooltip => 'Descargar';

  @override
  String get mailDetailAttachmentFallback => 'Adjunto';

  @override
  String get mailInboxTitle => 'Bandeja de entrada';

  @override
  String get mailSearchHint => 'Buscar correo';

  @override
  String get mailSearchClear => 'Borrar búsqueda';

  @override
  String get mailSearchMinChars =>
      'La búsqueda debe tener al menos 2 caracteres.';

  @override
  String get mailSearchUnreadOnly => 'Solo no leídos';

  @override
  String get mailSearchDateRange => 'Rango de fechas';

  @override
  String get mailSearchClearDates => 'Limpiar fechas';

  @override
  String get mailSearchNoResults => 'No se encontraron mensajes.';

  @override
  String get mailThreadsTitle => 'Hilos';

  @override
  String get mailThreadsEmpty => 'No se encontraron hilos.';

  @override
  String get mailThreadSearchNoResults => 'No se encontraron conversaciones.';

  @override
  String get mailThreadSearchNoResultsHint =>
      'Prueba con otro término, por ejemplo \"factura\", \"invoice\", \"presupuesto\" o el nombre del cliente.';

  @override
  String get mailThreadSearchTooltip =>
      'Busca conversaciones. Prueba con factura, invoice, presupuesto o quote.';

  @override
  String get mailThreadDetailTitle => 'Hilo';

  @override
  String get mailThreadParticipantsLabel => 'Participantes';

  @override
  String get mailThreadMessageCountLabel => 'Mensajes';

  @override
  String get mailThreadUnreadCountLabel => 'No leídos';

  @override
  String get mailThreadNoMessages => 'No hay mensajes en este hilo.';

  @override
  String get mailThreadNotFound => 'Hilo no encontrado.';

  @override
  String get mailThreadOpenMessage => 'Abrir mensaje';

  @override
  String get mailThreadOpenThread => 'Abrir hilo';

  @override
  String get mailConsoleTitle => 'Correo';

  @override
  String get mailConsoleFoldersTitle => 'Carpetas';

  @override
  String get mailFolderInbox => 'Bandeja de entrada';

  @override
  String get mailFolderSent => 'Enviados';

  @override
  String get mailFolderArchive => 'Archivados';

  @override
  String get mailFolderTrash => 'Papelera';

  @override
  String get mailFolderSpam => 'Spam';

  @override
  String get mailConsoleSearchPlaceholder => 'Buscar conversaciones...';

  @override
  String get mailConsoleSelectThread =>
      'Selecciona un hilo para ver los mensajes.';

  @override
  String get mailConsoleLoadError => 'No se pudo cargar el buzón. Reintenta.';

  @override
  String get mailConsoleReplyPlaceholder => 'Escribe una respuesta…';

  @override
  String get mailConsoleReplySend => 'Responder';

  @override
  String get mailConsoleReplySending => 'Enviando…';

  @override
  String get mailConsoleReplySent => 'Respuesta enviada.';

  @override
  String mailConversationReplyTo(Object name) {
    return 'Responder a $name…';
  }

  @override
  String mailConversationPreviousMessage(Object count) {
    return 'Mensaje anterior ($count)';
  }

  @override
  String get mailConversationSignature => 'Firma';

  @override
  String get mailConversationReply => 'Responder';

  @override
  String get mailConversationReplyAll => 'Responder a todos';

  @override
  String get mailConversationForward => 'Reenviar';

  @override
  String get mailLegalNoticeShow => 'Mostrar aviso legal';

  @override
  String get mailLegalNoticeHide => 'Ocultar aviso legal';

  @override
  String get mailConsoleClientPanelTitle => 'Cliente y facturas';

  @override
  String get mailConsoleClientNotFound =>
      'No se encontró un cliente para este hilo.';

  @override
  String get mailConsoleClientEmailMissing => 'Falta el correo del cliente.';

  @override
  String get mailConsoleOpenInvoicesTitle => 'Facturas abiertas';

  @override
  String get mailConsoleInvoicesEmpty => 'No hay facturas abiertas.';

  @override
  String get mailConsoleInvoiceActionsTitle => 'Acciones de factura';

  @override
  String get mailConsoleResendInvoice => 'Reenviar factura';

  @override
  String get mailConsoleSendPaymentLink => 'Enviar enlace de pago';

  @override
  String get mailConsoleMarkPaid => 'Marcar como pagada';

  @override
  String get mailConsoleInvoiceUnknown => 'Factura';

  @override
  String get mailConsoleInvoiceResent => 'Factura reenviada.';

  @override
  String get mailConsolePaymentLinkSent => 'Enlace de pago enviado.';

  @override
  String get mailConsoleMarkedPaid => 'Factura marcada como pagada.';

  @override
  String mailConsoleActionFailed(Object error) {
    return 'Acción fallida: $error';
  }

  @override
  String mailConsoleInvoiceSubject(Object number) {
    return 'Factura $number';
  }

  @override
  String mailConsoleInvoiceBody(Object number) {
    return 'Consulta la factura $number.';
  }

  @override
  String get mailComposeTitle => 'Redactar';

  @override
  String get mailComposeToLabel => 'Para';

  @override
  String get mailComposeToHint => 'Introduce correos de destinatarios';

  @override
  String get mailComposeToHelper => 'Añade al menos un destinatario';

  @override
  String get mailComposeCcLabel => 'Cc';

  @override
  String get mailComposeCcHint => 'Añade correos en copia';

  @override
  String get mailComposeAddCc => 'Añadir Cc';

  @override
  String get mailComposeBccLabel => 'Cco';

  @override
  String get mailComposeBccHint => 'Añade correos en copia oculta';

  @override
  String get mailComposeAddBcc => 'Añadir Cco';

  @override
  String get mailComposeSubjectLabel => 'Asunto';

  @override
  String get mailComposeSubjectHint => 'Asunto';

  @override
  String get mailComposeSubjectHelper =>
      'El asunto ayuda a identificar la conversación';

  @override
  String get mailComposeBodyLabel => 'Cuerpo';

  @override
  String get mailComposeFormat => 'Formato';

  @override
  String get mailComposeHtmlToggle => 'HTML';

  @override
  String get mailComposeHtmlHint => 'Pega contenido HTML';

  @override
  String get mailComposeTextHint => 'Escribe tu mensaje';

  @override
  String get mailComposeBodyHelper => 'Escribe un mensaje para enviar';

  @override
  String get mailComposeAttachmentsLabel => 'Adjuntos';

  @override
  String get mailComposeAttachmentsEmpty => 'Aún no hay adjuntos.';

  @override
  String get mailComposeAddAttachment => 'Añadir adjunto';

  @override
  String get mailComposeStorageKeyLabel => 'Clave de almacenamiento';

  @override
  String get mailComposeStorageKeyHint => 'ej. uploads/abc.pdf';

  @override
  String get mailComposeFilenameLabel => 'Nombre de archivo (opcional)';

  @override
  String get mailComposeFilenameHint => 'factura.pdf';

  @override
  String get mailComposeContentTypeLabel => 'Tipo de contenido (opcional)';

  @override
  String get mailComposeContentTypeHint => 'application/pdf';

  @override
  String get mailComposeSizeLabel => 'Tamaño (opcional)';

  @override
  String get mailComposeSizeHint => 'Bytes';

  @override
  String get mailComposeCancel => 'Cancelar';

  @override
  String get mailComposeStorageKeyRequired =>
      'La clave de almacenamiento es obligatoria.';

  @override
  String get mailComposeInvoiceOptions => 'Opciones de factura';

  @override
  String get mailComposeInvoiceOptionsHelper =>
      'Estas opciones se usan solo al enviar facturas';

  @override
  String get mailComposeApplyFooterLabel => 'Aplicar pie por defecto';

  @override
  String get mailComposeApplyFooterHelper =>
      'Añade el pie por defecto a este correo.';

  @override
  String get mailComposeInvoiceIdsLabel => 'IDs de factura';

  @override
  String get mailComposeInvoiceIdsHint => 'IDs separados por comas';

  @override
  String get mailComposeAttachInvoicePdf => 'Adjuntar PDF de factura';

  @override
  String get mailComposeIncludeInvoiceLinks => 'Incluir enlaces de factura';

  @override
  String get mailComposeUploadAttachment => 'Subir archivo';

  @override
  String get mailComposeUploading => 'Subiendo…';

  @override
  String get mailComposeFileReadError =>
      'No se pudo leer el archivo seleccionado.';

  @override
  String mailComposeUploadFailed(Object error) {
    return 'Error al subir: $error';
  }

  @override
  String get mailComposeSend => 'Enviar';

  @override
  String get mailComposeSending => 'Enviando…';

  @override
  String get mailComposeSentToast => 'Enviado';

  @override
  String get mailComposeToRequired => 'Agrega al menos un destinatario.';

  @override
  String get mailComposeSubjectRequired => 'El asunto es obligatorio.';

  @override
  String get mailComposeBodyRequired => 'El cuerpo del mensaje es obligatorio.';

  @override
  String mailComposeSendFailed(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String get mailFooterTitle => 'Crear pie de correo';

  @override
  String get mailFooterBody =>
      'Crea un pie que aparecerá en los correos salientes. El logo de la empresa se añadirá automáticamente.';

  @override
  String get mailFooterNameLabel => 'Nombre del pie';

  @override
  String get mailFooterNameHint => 'Pie por defecto';

  @override
  String get mailFooterTextLabel => 'Texto del pie (texto plano)';

  @override
  String get mailFooterTextHint => 'Escribe el texto del pie';

  @override
  String get mailFooterHtmlLabel => 'HTML del pie (avanzado)';

  @override
  String get mailFooterHtmlHint => '<div>...</div>';

  @override
  String get mailFooterDefaultLabel => 'Establecer como predeterminado';

  @override
  String get mailFooterHelperTextOnly =>
      'Si solo completas el texto plano, lo usaremos en correos de texto y HTML.';

  @override
  String get mailFooterHelperHtmlOverrides =>
      'Si proporcionas HTML, se usará en los correos HTML.';

  @override
  String get mailFooterSaveCta => 'Guardar pie';

  @override
  String get mailFooterCancel => 'Cancelar';

  @override
  String get mailFooterCreateCta => 'Crear pie';

  @override
  String get mailFooterNameRequired => 'El nombre del pie es obligatorio.';

  @override
  String get mailFooterSaved => 'Pie guardado.';

  @override
  String get mailFooterCurrentTitle => 'Pie actual';

  @override
  String get mailFooterSystemDefault =>
      'Se está usando el pie predeterminado del sistema.';

  @override
  String get mailFooterUnnamed => 'Pie sin nombre';

  @override
  String get mailFooterHtmlPreview => 'HTML proporcionado';

  @override
  String get mailFooterDefaultBadge => 'Predeterminado';

  @override
  String get mailFooterCreateTitle => 'Opciones del pie';

  @override
  String get mailFooterFormTitle => 'Crear pie';

  @override
  String get mailFooterUseSystemDefault => 'Usar el pie del sistema';

  @override
  String get mailFooterPreviewBody =>
      'Previsualiza cómo se verá tu pie en los correos enviados.';

  @override
  String get mailFooterPreviewCta => 'Previsualizar pie';

  @override
  String get mailFooterPreviewSystemCta => 'Previsualizar pie del sistema';

  @override
  String get mailFooterUseThis => 'Usar este pie';

  @override
  String get mailFooterEdit => 'Editar';

  @override
  String mailFooterSaveFailed(Object error) {
    return 'No se pudo guardar el pie: $error';
  }

  @override
  String get budgetsMenuSection => 'Presupuestos';

  @override
  String get budgetsMenuList => 'Listar presupuesto';

  @override
  String get budgetsMenuNew => 'Nuevo presupuesto';

  @override
  String get budgetStepClient => 'Cliente';

  @override
  String get budgetStepBudget => 'Presupuesto';

  @override
  String get budgetStepLines => 'Líneas';

  @override
  String get budgetStepConfirm => 'Confirmar';

  @override
  String get budgetStepPreview => 'Preview';

  @override
  String get budgetClientInfoPrompt =>
      'La información del cliente en presupuestos es flexible. Elige un cliente existente o escribe un nombre de cliente. Se requiere al menos uno. Esto aplica solo a Presupuestos: facturas y recibos siguen requiriendo un cliente guardado.';

  @override
  String get budgetClientSelectSavedLabel =>
      'Selecciona un cliente guardado (opcional para Presupuestos).';

  @override
  String get budgetClientNoneSaved => 'Sin cliente guardado';

  @override
  String get budgetClientNameLabel =>
      'Usa esto si el cliente todavía no está en tu base de datos.';

  @override
  String get budgetValidationClientRequired =>
      'Proporciona un cliente guardado o un nombre de cliente.';

  @override
  String get budgetValidationNumberFormat =>
      'Usa NNN-YY (por ejemplo, 001-26).';

  @override
  String get budgetValidationGroupRequired =>
      'Falta groupId para crear el presupuesto.';

  @override
  String get budgetValidationLineItemsRequired =>
      'Añade al menos una línea con concepto de trabajo antes de continuar.';

  @override
  String get budgetDraftSavedSnack => 'Cambios guardados en borrador.';

  @override
  String get budgetDraftCreatedSnack => 'Borrador guardado correctamente.';

  @override
  String get budgetDraftSavedSnackTitle => 'Borrador de presupuesto guardado';

  @override
  String get budgetDraftSavedSnackMessage =>
      'Tu borrador de presupuesto está seguro y listo para continuar después.';

  @override
  String get budgetDraftUpdatedSnackTitle =>
      'Borrador de presupuesto actualizado';

  @override
  String get budgetDraftUpdatedSnackMessage =>
      'Tus últimos cambios del presupuesto se guardaron.';

  @override
  String get budgetDraftNotEditableSnack =>
      'Este presupuesto ya no es borrador y no se puede editar.';

  @override
  String get budgetPreviewAcceptRequired =>
      'Acepta antes de abrir la previsualización.';

  @override
  String get budgetNumberLabel => 'Número de presupuesto';

  @override
  String get budgetNumberHint => '001-26';

  @override
  String get budgetNumberAutoOnIssue =>
      'El número del presupuesto lo asigna el servidor al emitir.';

  @override
  String get budgetNumberPendingIssue => 'Pendiente de emisión';

  @override
  String get budgetLineItemsSimulateLabel =>
      'Simular líneas agregadas (validación solo UI)';

  @override
  String get budgetInfoBanner =>
      'Los presupuestos se pueden crear con un nombre de cliente fijo. Si no se selecciona cliente, el PDF mostrará el nombre y dejará el resto de campos del cliente en blanco.';

  @override
  String budgetConfirmClientValue(Object value) {
    return 'Cliente: $value';
  }

  @override
  String budgetConfirmNumberValue(Object value) {
    return 'Número de presupuesto: $value';
  }

  @override
  String budgetConfirmDraftIdValue(Object value) {
    return 'ID de borrador: $value';
  }

  @override
  String budgetConfirmLinesValue(Object value) {
    return 'Líneas: $value';
  }

  @override
  String get budgetListIntro =>
      'Listado de presupuestos (UI). El listado del servidor se conectará más adelante.';

  @override
  String get budgetListPlaceholder =>
      'No hay presupuestos para mostrar todavía.';

  @override
  String get budgetBackCta => 'Atrás';

  @override
  String get budgetNextCta => 'Siguiente';

  @override
  String get budgetValidateCta => 'Validar';

  @override
  String get budgetValidatedSnack =>
      'Borrador de presupuesto validado (solo UI). Integración con servidor pendiente.';

  @override
  String budgetIssuedSnack(Object number) {
    return 'Presupuesto emitido con número $number.';
  }

  @override
  String get budgetIssueConflict =>
      'Conflicto de numeración al emitir. Vuelve a intentarlo.';

  @override
  String get budgetPreviewInlineTitle => 'Previsualización';

  @override
  String get budgetPreviewDialogTitle => 'Previsualización del presupuesto';

  @override
  String get budgetPreviewOpenCta => 'Abrir previsualización';

  @override
  String get budgetPreviewAcceptLabel =>
      'Confirmo estos datos y quiero generar el PDF de previsualización';

  @override
  String budgetPreviewAutoTitle(Object id) {
    return 'PDF de previsualización para presupuesto $id';
  }

  @override
  String get budgetPreviewEmpty =>
      'Añade líneas para previsualizar este presupuesto.';

  @override
  String get budgetShortLogicFlowTitle => 'Flujo lógico corto';

  @override
  String get budgetShortLogicFlow1 =>
      'Crear borrador sin presupuestoNumber; el backend lo guarda como draft.';

  @override
  String get budgetShortLogicFlow2 =>
      'Se requiere clientId o clientName, junto con groupId.';

  @override
  String get budgetShortLogicFlow3 =>
      'Emitir con POST /api/presupuestos/:id/issue para asignar NNN-YY.';

  @override
  String get budgetShortLogicFlow4 =>
      'Usar el presupuestoNumber devuelto para mostrar; la preview usa /api/presupuestos/:id/pdf/preview.';

  @override
  String get insightsChatFabTooltip => 'Chat de insights';

  @override
  String get insightsChatTitle => 'Insights';

  @override
  String get insightsChatWelcome =>
      'Preguntame sobre tus ultimos 30 dias de gastos y facturas emitidas.';

  @override
  String get insightsChatModeAuto => 'Auto';

  @override
  String get insightsChatModeStream => 'Stream';

  @override
  String get insightsChatClearTooltip => 'Limpiar chat';

  @override
  String get insightsChatClearTitle => '¿Limpiar chat?';

  @override
  String get insightsChatClearMessage =>
      'Esto eliminara todos los mensajes de este chat.';

  @override
  String get insightsChatClearAction => 'Limpiar';

  @override
  String get insightsChatDaysPrefix => 'Contexto';

  @override
  String get insightsChatDaysTooltip => 'Dias de ventana de contexto';

  @override
  String get insightsChatNoResponse =>
      'El servicio de insights no devolvio respuesta.';

  @override
  String get insightsChatAnswerReady => 'La respuesta de insights esta lista.';

  @override
  String get insightsChatInputHint =>
      'Pregunta por ingresos, gastos, margen, tendencias...';

  @override
  String get insightsChatSend => 'Enviar';

  @override
  String get insightsChatExportExcel => 'Exportar a Excel';

  @override
  String get insightsChatExportExcelTooltip =>
      'Exportar esta respuesta financiera a Excel';

  @override
  String insightsChatExportSuccess(String fileName) {
    return 'Excel generado: $fileName';
  }

  @override
  String get insightsChatExportError => 'No se pudo exportar a Excel';

  @override
  String get insightsChatExportUnsupported =>
      'La descarga de archivos no esta disponible en esta plataforma';

  @override
  String get systemConfigMenuLabel => 'Configuración del sistema';

  @override
  String get groupPhotoUpdated => 'Foto del grupo actualizada';

  @override
  String get groupPhotoUpdateFailed => 'Error al actualizar la foto del grupo';

  @override
  String get premiumRequiredSingleGroupMessage =>
      'Tu plan actual permite solo 1 grupo. Mejora a Premium para crear o unirte a grupos adicionales.';

  @override
  String get premiumRequiredJoinGroupOnlyMessage =>
      'Ya estás en un grupo. Mejora a Premium para unirte a más grupos.';

  @override
  String get upgradeToPremium => 'Mejorar a Premium';

  @override
  String get contractsTitle => 'Contratos';

  @override
  String contractsForClient(Object client) {
    return 'Contratos de $client';
  }

  @override
  String get contractsEmptyTitle => 'Sin contratos todavia';

  @override
  String get contractsEmptySubtitle =>
      'Sube el primer contrato de este cliente.';

  @override
  String get contractsLoadFailedTitle => 'No se pudieron cargar los contratos';

  @override
  String get contractUploadTitle => 'Subir contrato';

  @override
  String get contractUploadSubtitle =>
      'Adjunta un PDF y guarda la metadata que necesites para este cliente.';

  @override
  String get contractEditTitle => 'Editar contrato';

  @override
  String get contractEditSubtitle =>
      'Actualiza la metadata del contrato sin volver a subir el PDF.';

  @override
  String get contractUploadAction => 'Subir contrato';

  @override
  String get contractUploadSuccess => 'Contrato subido correctamente.';

  @override
  String contractUploadFailed(Object reason) {
    return 'No se pudo subir el contrato: $reason';
  }

  @override
  String get contractUpdateSuccess => 'Contrato actualizado correctamente.';

  @override
  String contractUpdateFailed(Object reason) {
    return 'No se pudo actualizar el contrato: $reason';
  }

  @override
  String get contractDeleteTitle => 'Eliminar contrato?';

  @override
  String contractDeleteBody(Object name) {
    return 'Eliminar el contrato \"$name\"? Esta accion no se puede deshacer.';
  }

  @override
  String get contractDeleteSuccess => 'Contrato eliminado correctamente.';

  @override
  String contractDeleteFailed(Object reason) {
    return 'No se pudo eliminar el contrato: $reason';
  }

  @override
  String get contractMarkedCurrentSuccess => 'Contrato actual actualizado.';

  @override
  String get contractOpenFailedGeneric => 'No se pudo abrir el PDF.';

  @override
  String contractOpenFailed(Object reason) {
    return 'No se pudo abrir el PDF: $reason';
  }

  @override
  String contractDownloadFailed(Object reason) {
    return 'No se pudo descargar el PDF: $reason';
  }

  @override
  String get contractTitleLabel => 'Titulo';

  @override
  String get contractFileNameLabel => 'Nombre del archivo';

  @override
  String get contractVersionLabel => 'Version';

  @override
  String get contractStatusLabel => 'Estado';

  @override
  String get contractRenewalDateLabel => 'Fecha de renovacion';

  @override
  String get contractSignedDateLabel => 'Fecha de firma';

  @override
  String get contractNotesLabel => 'Notas';

  @override
  String get contractTagsLabel => 'Etiquetas';

  @override
  String get contractTagsHint => 'Separa las etiquetas con comas';

  @override
  String get contractCurrentBadge => 'Contrato actual';

  @override
  String get contractCurrentHint =>
      'Marca este documento como el contrato vigente del cliente.';

  @override
  String get contractPickPdf => 'Elegir PDF';

  @override
  String get contractNoFileSelected => 'Ningun PDF seleccionado';

  @override
  String get contractPdfOnlyHint => 'Solo se admiten archivos PDF.';

  @override
  String get contractDropHint => 'Arrastra un PDF aqui o pulsa para subirlo.';

  @override
  String get contractDropActiveHint => 'Suelta el PDF para subirlo.';

  @override
  String get contractFileReadError => 'No se pudo leer el PDF seleccionado.';

  @override
  String get contractFileRequired =>
      'Selecciona un archivo PDF antes de continuar.';

  @override
  String get contractViewPdfAction => 'Ver PDF';

  @override
  String get contractDownloadAction => 'Descargar';

  @override
  String get contractMarkCurrentAction => 'Marcar como actual';

  @override
  String get contractUploadedAtLabel => 'Subido';

  @override
  String get contractExpiredBadge => 'Caducado';

  @override
  String get contractExpiringSoonBadge => 'Proximo a vencer';

  @override
  String get contractClearDateAction => 'Limpiar fecha';

  @override
  String get clientContractTypeLabel => 'Tipo de contrato';

  @override
  String get clientContractTypeService => 'Servicio';

  @override
  String get clientContractTypeMaintenance => 'Mantenimiento';

  @override
  String get clientContractTypeRental => 'Alquiler';

  @override
  String get clientContractTypeNda => 'NDA';

  @override
  String get clientContractTypeCustom => 'Otro';

  @override
  String get clientContractStatusExpired => 'Expirado';

  @override
  String get clientContractStatusTerminated => 'Terminado';

  @override
  String get clientContractStatusArchived => 'Archivado';

  @override
  String get statementsNoExpenseSuggestions =>
      'No se encontraron gastos coincidentes';

  @override
  String get statementsSuggestedExpensesTitle => 'Gastos sugeridos';

  @override
  String get statementsExpenseAlreadyLinkedBadge => 'Ya vinculado';

  @override
  String get statementsExpenseLinkAction => 'Usar este gasto';

  @override
  String get statementsExpenseOpenManualLink => 'Abrir selector manual';

  @override
  String get statementsExpenseSuggestionsLoadFailedTitle =>
      'No se pudieron cargar los gastos sugeridos';

  @override
  String get statementsExpenseSuggestionsFallbackHint =>
      'Todavia puedes vincular un gasto manualmente.';

  @override
  String get statementsExpenseLinkFailed => 'No se pudo vincular el gasto.';

  @override
  String get statementsExpenseStatusRegistered => 'Registrado';

  @override
  String statementsExpenseAlreadyLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ya vinculado a # movimientos bancarios',
      one: 'Ya vinculado a # movimiento bancario',
    );
    return '$_temp0';
  }

  @override
  String get rolesTabLabel => 'Roles';

  @override
  String get rolesCurrentRoleLabel => 'Tu rol actual';

  @override
  String get rolesPermissionsUnit => 'permisos';

  @override
  String get rolesGuideTitle => 'Guía de roles';

  @override
  String get rolesYourRoleBadge => 'Tu rol';

  @override
  String get rolesLoadError => 'No se pudieron cargar los permisos';

  @override
  String get rolesRetryButton => 'Reintentar';

  @override
  String get roleFallbackDescOwner =>
      'Control total sobre el grupo. Puede transferir la propiedad.';

  @override
  String get roleFallbackDescAdmin =>
      'Puede gestionar miembros, roles, facturación y configuración.';

  @override
  String get roleFallbackDescCoAdmin =>
      'Puede invitar miembros y gestionar el calendario y eventos.';

  @override
  String get roleFallbackDescMember => 'Puede ver y participar en el grupo.';

  @override
  String get permLabelInvite => 'Invitar';

  @override
  String get permLabelKick => 'Eliminar miembros';

  @override
  String get permLabelEditGroup => 'Editar grupo';

  @override
  String get permLabelDeleteGroup => 'Eliminar grupo';

  @override
  String get permLabelManageRoles => 'Gestionar roles';

  @override
  String get permLabelViewBilling => 'Ver facturación';

  @override
  String get permLabelManageInvoices => 'Facturas';

  @override
  String get permLabelManageBudgets => 'Presupuestos';

  @override
  String get permLabelViewMembers => 'Ver miembros';

  @override
  String get permLabelManageMembers => 'Gestionar miembros';

  @override
  String get permLabelSendMessages => 'Mensajes';

  @override
  String get permLabelViewCalendar => 'Ver calendario';

  @override
  String get permLabelEditCalendar => 'Editar calendario';

  @override
  String get permLabelManageEvents => 'Eventos';

  @override
  String get permLabelViewReports => 'Informes';

  @override
  String get permLabelManageSettings => 'Ajustes';

  @override
  String get permLabelTransferOwnership => 'Transferir propiedad';

  @override
  String get permLabelGroup => 'Grupo';

  @override
  String get permLabelStatements => 'Extractos';

  @override
  String get permLabelCalendar => 'Calendario';

  @override
  String get permLabelEvents => 'Eventos';

  @override
  String get permLabelTimeTracking => 'Control horario';

  @override
  String get permLabelExpenses => 'Gastos';

  @override
  String get permLabelInvoices => 'Facturas';

  @override
  String get permLabelReports => 'Informes';

  @override
  String get permLabelSettings => 'Ajustes';

  @override
  String get permLabelMembers => 'Miembros';

  @override
  String get roleDescOwner =>
      'Control total del grupo, miembros, ajustes y herramientas compartidas.';

  @override
  String get roleDescAdmin =>
      'Rol de gestor avanzado heredado. Tratado como co-admin en la guía.';

  @override
  String get roleDescCoAdmin =>
      'Puede gestionar la mayoría de las operaciones grupales, pero no puede eliminar el grupo ni superar al propietario.';

  @override
  String get roleDescMember =>
      'Puede ver los datos compartidos del grupo y gestionar solo sus propias acciones permitidas.';

  @override
  String get expenseJsonTabFlowHint =>
      'Pega el JSON y adjunta la factura para importar.';

  @override
  String get expenseJsonTabPickJsonFile => 'Archivo JSON';

  @override
  String get expenseJsonTabPickInvoiceFile => 'Factura';

  @override
  String get expenseJsonTabGetAiPrompt => 'Obtener Prompt IA';

  @override
  String get expenseJsonTabGeneratingPrompt => 'Generando prompt IA...';

  @override
  String get expenseJsonTabPromptLabel => 'PROMPT IA';

  @override
  String get expenseJsonTabCopyPrompt => 'Copiar';

  @override
  String get expenseJsonTabPayloadLabel => 'JSON Payload';

  @override
  String get expenseJsonTabPayloadHint => 'Pega aquí el JSON de la factura...';

  @override
  String get expenseJsonTabAdvancedOptions => 'OPCIONES AVANZADAS';

  @override
  String get expenseJsonTabSectionExpenseType => 'Tipo de gasto';

  @override
  String get expenseJsonTabSectionDiscount => 'Descuento global';

  @override
  String get expenseJsonTabSectionTotal => 'Total documento';

  @override
  String get expenseJsonTabImportCta => 'Importar JSON';

  @override
  String get expenseJsonTabImportHint =>
      'Requiere JSON y archivo de factura adjunto.';

  @override
  String get expenseJsonLeftTitle => 'Importación JSON';

  @override
  String get expenseJsonLeftSubtitle =>
      'Carga el JSON, adjunta la factura y revisa el payload en el panel derecho.';

  @override
  String get expenseJsonLeftDropActive => 'Suelta el JSON o la factura';

  @override
  String get expenseJsonLeftDropHint => 'Arrastra aquí el JSON o la factura';

  @override
  String get expenseJsonLeftFileTypes => 'JSON / PDF / JPG / JPEG / PNG / WEBP';

  @override
  String get expenseJsonLeftPickJson => 'Seleccionar JSON';

  @override
  String get expenseJsonLeftPickInvoice => 'Adjuntar factura';

  @override
  String get expenseJsonLeftPromptTitle => 'Prompt AI';

  @override
  String get expenseJsonLeftPromptAvailable => 'Disponible';

  @override
  String get expenseJsonLeftPromptGenerate => 'Generar plantilla';

  @override
  String get expenseJsonLeftPromptTooltip => 'Obtener prompt AI';

  @override
  String get expenseJsonLeftCopyPromptTooltip => 'Copiar prompt';

  @override
  String get expenseJsonLeftSummaryTitle => 'Resumen';

  @override
  String get expenseJsonLeftJsonPending => 'JSON pendiente';

  @override
  String get expenseJsonLeftInvoicePending => 'Factura pendiente';

  @override
  String get expenseBatchLeftTitle => 'Importar documentos';

  @override
  String get expenseBatchLeftSubtitle =>
      'Selecciona los PDFs o imágenes a procesar. La lista completa y las incidencias se muestran en el panel derecho.';

  @override
  String get expenseBatchLeftDropActive =>
      'Suelta los documentos para cargarlos';

  @override
  String get expenseBatchLeftDropHint => 'Arrastra aquí tus documentos';

  @override
  String get expenseBatchLeftFileTypes => 'PDF / JPG / JPEG / PNG / WEBP';

  @override
  String get expenseBatchLeftPickCta => 'Seleccionar documentos';

  @override
  String get expenseBatchLeftProcessing => 'Procesando lote...';

  @override
  String expenseBatchLeftSelected(int count) {
    return '$count documentos seleccionados';
  }

  @override
  String expenseBatchLeftCapacity(int selected, int max) {
    return 'Capacidad: $selected / $max';
  }

  @override
  String expenseBatchLeftTotalSize(String size) {
    return 'Tamaño total: $size';
  }

  @override
  String expenseBatchLeftSlots(int slots) {
    return 'Espacios disponibles: $slots';
  }

  @override
  String get expenseBatchLeftClearCta => 'Limpiar selección';

  @override
  String get expenseBatchLeftCompleted => 'Lote completado';

  @override
  String get expenseBatchLeftImportCta => 'Importar gastos';

  @override
  String get expenseBatchLeftGroupRequired =>
      'Selecciona un grupo antes de importar.';

  @override
  String get expenseBatchProgressCompleted => 'Importación completada';

  @override
  String get expenseBatchProgressFailed => 'Importación fallida';

  @override
  String get expenseBatchProgressQueued => 'Importación en cola';

  @override
  String get expenseBatchProgressProcessing => 'Procesando lote de gastos';

  @override
  String get expenseBatchStatProcessed => 'Procesados';

  @override
  String get expenseBatchStatImported => 'Importados';

  @override
  String get expenseBatchStatIssues => 'Con incidencia';

  @override
  String get expenseBatchStatResult => 'Resultado';

  @override
  String get expenseBatchStatLoading => 'Cargando...';

  @override
  String expenseBatchHeaderSlotsFree(int count) {
    return '$count libres';
  }

  @override
  String get expenseBatchProgressBackgroundHint =>
      'Puedes salir de esta pantalla mientras se completa la importación.';

  @override
  String get expenseBatchListTitle => 'Archivos cargados';

  @override
  String expenseBatchListCount(int count) {
    return '$count archivo(s)';
  }

  @override
  String get expenseBatchListFilterAll => 'Todos';

  @override
  String get expenseBatchListFilterReady => 'Listos';

  @override
  String get expenseBatchListFilterIssues => 'Incidencias';

  @override
  String expenseBatchListRemoveWarnings(int count) {
    return 'Quitar $count';
  }

  @override
  String get expenseBatchListEmpty =>
      'No hay archivos para este filtro todavía.';

  @override
  String get expenseBatchListRemoveTooltip => 'Quitar de la selección';

  @override
  String expenseBatchDocListFiles(int count) {
    return '$count archivos';
  }

  @override
  String get expenseBatchDocListAlreadyUploaded => 'Ya subido';

  @override
  String expenseBatchDocListDuplicates(int count) {
    return '$count ya subidos';
  }

  @override
  String get expenseBatchDocListClearAll => 'Limpiar todo';

  @override
  String get expenseBatchDocListRemove => 'Quitar';

  @override
  String get expenseBatchErrorCopyList => 'Copiar lista';

  @override
  String get expenseTotalsUseSummaryLabel => 'Usar resumen del documento';

  @override
  String get expenseTotalsSummaryMode => 'Totales extraidos del resumen';

  @override
  String get expenseTotalsCalculateMode => 'Calcular desde lineas';

  @override
  String get expenseTotalsSummaryHelp =>
      'El IVA de este documento aparece en el resumen inferior del ticket/factura. No es necesario que cada linea muestre IVA por separado.';

  @override
  String get expenseTotalsLockToLinesHelp =>
      'Base, IVA y total se calculan desde las lineas y descuentos. Activa el resumen si el documento solo muestra el IVA en el pie.';

  @override
  String get expenseTotalsDirectReviewHelp =>
      'Puedes revisar los totales del documento directamente desde este bloque.';

  @override
  String get expenseTotalsTaxableBase => 'Base imponible';

  @override
  String get expenseTotalsTax => 'IVA total';

  @override
  String get expenseTotalsTotal => 'Total documento';

  @override
  String get suspectExpensesMenuLabel => 'Gastos sospechosos';

  @override
  String get suspectExpensesTitle => 'Gastos sospechosos';

  @override
  String get suspectExpensesScanned => 'Analizados';

  @override
  String get suspectExpensesCount => 'Sospechosos';

  @override
  String get suspectExpensesFilterResults => 'Resultados del filtro';

  @override
  String get suspectExpensesShown => 'Sospechosos mostrados';

  @override
  String get suspectExpensesEmpty =>
      'No hay gastos sospechosos para este filtro.';

  @override
  String get suspectExpensesEmptyUnreviewed =>
      'No hay gastos sospechosos sin revisar.';

  @override
  String get suspectExpensesEmptyConfirmedOk =>
      'No hay gastos marcados como confirmado correcto.';

  @override
  String get suspectExpensesEmptyNeedsFix =>
      'No hay gastos marcados como necesita corrección.';

  @override
  String get suspectExpensesFilterAll => 'Todos';

  @override
  String get suspectExpensesFilterUnreviewed => 'Sin revisar';

  @override
  String get suspectExpensesFilterConfirmedOk => 'Confirmado correcto';

  @override
  String get suspectExpensesFilterNeedsFix => 'Necesita corrección';

  @override
  String get suspectExpensesStatusUnreviewed => 'Sin revisar';

  @override
  String get suspectExpensesStatusConfirmedOk => 'Confirmado correcto';

  @override
  String get suspectExpensesStatusNeedsFix => 'Necesita corrección';

  @override
  String get suspectExpensesStoredLabel => 'Guardado';

  @override
  String get suspectExpensesDerivedLabel => 'Derivado';

  @override
  String get suspectExpensesStoredSubtotal => 'Subtotal guardado';

  @override
  String get suspectExpensesStoredTax => 'IVA guardado';

  @override
  String get suspectExpensesStoredTotal => 'Total guardado';

  @override
  String get suspectExpensesReasons => 'Motivos detectados';

  @override
  String get suspectExpensesActionConfirmOk => 'Marcar como correcto';

  @override
  String get suspectExpensesActionNeedsFix => 'Marcar para corregir';

  @override
  String get suspectExpensesActionReset => 'Restablecer revisión';

  @override
  String get suspectExpensesNotes => 'Notas';

  @override
  String get suspectExpensesNotesHint => 'Añade una nota antes de guardar…';

  @override
  String get suspectExpensesUploadedAt => 'Subido';

  @override
  String get notificationBankExpensesDetectedTitle =>
      'Gastos bancarios detectados';

  @override
  String notificationBankExpensesDetectedMessage(int count, String amount) {
    return 'Se detectaron $count gastos bancarios por un total de $amount.';
  }

  @override
  String get invoiceCreateMobileComingSoonSnack =>
      'Crear factura en móvil estará disponible pronto.';

  @override
  String get invoiceExportConceptsExcelFailed =>
      'No se pudo exportar los conceptos de facturas a Excel.';

  @override
  String get receiptJsonImportDraftOnlySnack =>
      'Solo se pueden actualizar recibos en borrador mediante importación JSON.';

  @override
  String receiptJsonImportSuccessSnack(Object count) {
    return 'Se importaron $count líneas.';
  }

  @override
  String get budgetDeletedSnack => 'Presupuesto eliminado.';

  @override
  String get budgetAdvanceInvoiceCreatedSnack =>
      'Factura de anticipo creada correctamente (70%).';

  @override
  String get budgetAdvanceInvoiceCreatedSimpleSnack =>
      'Factura de anticipo creada correctamente.';

  @override
  String get budgetFinalInvoiceCreatedSnack =>
      'Factura final creada correctamente.';

  @override
  String get budgetConvertedToInvoiceSnack =>
      'Factura creada desde presupuesto.';

  @override
  String get chatComposerHintMessage => 'Escribe un mensaje…';

  @override
  String get chatComposerHintReply => 'Escribe una respuesta…';

  @override
  String get chatComposerHintCaption => 'Añade un pie de foto…';

  @override
  String get chatComposerHintBody => 'Intro envía · Shift+Intro nueva línea';

  @override
  String get chatComposerHintAttachment =>
      'Adjunto listo · usa el texto como pie de foto';

  @override
  String get chatComposerAttachFile => 'Archivo local';

  @override
  String get chatComposerAttachClientPdf => 'PDF de cliente';

  @override
  String get chatComposerAttachWorkerPdf => 'PDF de horas trabajadas';

  @override
  String get chatComposerSend => 'Enviar';

  @override
  String get chatComposerSendFile => 'Enviar archivo';

  @override
  String get chatComposerSending => 'Enviando…';

  @override
  String get chatComposerUploading => 'Subiendo…';

  @override
  String get chatComposerRetry => 'Reintentar';

  @override
  String get telegramSearchChats => 'Buscar chats…';

  @override
  String get telegramMenuChats => 'Chats';

  @override
  String get telegramMenuExports => 'Exportaciones';

  @override
  String get telegramMenuAccount => 'Cuenta';

  @override
  String get telegramMenuDisconnect => 'Desconectar';

  @override
  String get telegramFilterAll => 'Todos';

  @override
  String get telegramFilterGroups => 'Grupos';

  @override
  String get telegramFilterChannels => 'Canales';

  @override
  String get telegramFilterPrivate => 'Privados';

  @override
  String telegramNoChatsMatch(String query) {
    return 'No hay chats que coincidan con \"$query\"';
  }

  @override
  String get telegramNoChatsAvailable => 'No hay chats de Telegram disponibles';

  @override
  String get telegramClearSearch => 'Borrar búsqueda';

  @override
  String get telegramMainChatsSection => 'Chats principales';

  @override
  String get telegramNoMainChatsInfo =>
      'No hay chats en la lista principal. Los archivados están abajo.';

  @override
  String get telegramArchivedChats => 'Chats archivados';

  @override
  String get telegramChatsLoadError => 'Error al cargar los chats';

  @override
  String get telegramRetry => 'Reintentar';

  @override
  String get telegramTopics => 'Temas';

  @override
  String telegramBrowseTopicsIn(String chat) {
    return 'Explora los temas del foro en $chat.';
  }

  @override
  String get telegramSearchTopics => 'Buscar temas…';

  @override
  String get telegramGeneralTopic => 'Tema general';

  @override
  String get telegramHiddenTopic => 'Tema oculto';

  @override
  String get telegramForumTopicLabel => 'Tema del foro';

  @override
  String get telegramNoTopicsMatch =>
      'No hay temas que coincidan con tu búsqueda';

  @override
  String get telegramNoTopicsFound => 'No se encontraron temas del foro';

  @override
  String get telegramNoTopicsMatchBody =>
      'Prueba con otro nombre o borra la búsqueda.';

  @override
  String get telegramNoTopicsFoundBody =>
      'Este foro aún no tiene temas visibles.';

  @override
  String get telegramToday => 'Hoy';

  @override
  String get telegramYesterday => 'Ayer';

  @override
  String get telegramLoadOlder => 'Cargar anteriores';

  @override
  String get telegramBeginningOfHistory => 'Inicio del historial';

  @override
  String get telegramNoMessagesYet => 'No se han cargado mensajes';

  @override
  String get telegramNoMessagesTip =>
      'Intenta actualizar este chat o cargar el historial anterior.';

  @override
  String get telegramSelectChatTitle => 'Selecciona un chat para empezar';

  @override
  String get telegramSelectChatBody =>
      'Elige un chat de Telegram de la lista para cargar mensajes recientes, ver el historial y exportarlo.';

  @override
  String get telegramFailedToLoadMessages => 'Error al cargar los mensajes';

  @override
  String get telegramRefresh => 'Actualizar';

  @override
  String get telegramExport => 'Exportar';

  @override
  String get telegramEdited => 'editado';

  @override
  String telegramForwardedFrom(String source) {
    return 'Reenviado de $source';
  }

  @override
  String get telegramForwardedMessage => 'Mensaje reenviado';

  @override
  String telegramReplyingTo(String sender) {
    return 'Respondiendo a $sender';
  }

  @override
  String telegramReplyTo(String id) {
    return 'Respuesta a #$id';
  }

  @override
  String get telegramClearReply => 'Cancelar respuesta';

  @override
  String get telegramRemoveAttachment => 'Eliminar adjunto';

  @override
  String get telegramReply => 'Responder';

  @override
  String get telegramReplying => 'Respondiendo';

  @override
  String get telegramPreviewPdf => 'Ver PDF';

  @override
  String get telegramDownloadDocument => 'Descargar documento';

  @override
  String get telegramClose => 'Cerrar';

  @override
  String telegramTopicSubtitle(String name) {
    return 'Tema · $name';
  }

  @override
  String get telegramCouldNotReadFile =>
      'No se pudo leer el archivo seleccionado.';

  @override
  String get telegramNeedGroupClientPdf =>
      'Debes seleccionar un grupo antes de adjuntar PDFs de cliente.';

  @override
  String get telegramNeedGroupWorkerPdf =>
      'Debes seleccionar un grupo antes de adjuntar PDFs de trabajadores.';

  @override
  String get telegramCouldNotOpenPdf =>
      'No se pudo abrir la vista previa del PDF.';

  @override
  String get telegramCouldNotDownload => 'No se pudo descargar este documento.';

  @override
  String get back => 'Atrás';

  @override
  String get issueInvoice => 'Emitir factura';

  @override
  String get invoiceActionsTitle => 'Acciones';

  @override
  String get invoicePdfPreviewTitle => 'Vista previa PDF';

  @override
  String get invoicePdfGenerated => 'Generado';

  @override
  String get invoicePdfReadyToPreview => 'El PDF está listo para previsualizar';

  @override
  String get invoiceSaveDraftToPreview =>
      'Guarda el borrador para generar una vista previa PDF';

  @override
  String get invoicePdfOpenPreview => 'Abrir vista previa';

  @override
  String get invoicePreviewTitle => 'Vista previa';

  @override
  String get invoicePreviewNoNotes => 'Sin notas';

  @override
  String invoicePreviewLinesCount(int count) {
    return 'Líneas: $count';
  }

  @override
  String invoicePreviewTotalLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get invoiceDraftPdfDialogTitle => 'Descargar PDF del borrador';

  @override
  String get invoiceDraftPdfDialogContent =>
      'Genera una vista previa PDF de este borrador de factura.';

  @override
  String get invoiceDraftPreviewInBrowser => 'Ver en navegador';

  @override
  String get invoiceDraftDownloadPdf => 'Descargar PDF';

  @override
  String get invoiceDeliveryStatusUpdated => 'Estado de envío actualizado';

  @override
  String get invoiceMarkedUnsent => 'Factura marcada como no enviada';

  @override
  String get invoiceDeliveryOnlyIssued =>
      'Solo se puede marcar envío en facturas emitidas.';

  @override
  String get invoiceDeliveryUpdateError =>
      'No se pudo actualizar el estado de envío.';

  @override
  String get invoiceReviewPdfBeforeDraft =>
      'Revisa la vista previa antes de guardar el borrador.';

  @override
  String get invoiceStepClientShort => 'Cliente';

  @override
  String get invoiceStepLinesShort => 'Líneas';

  @override
  String get invoiceStepDraftShort => 'Borrador';

  @override
  String get notificationRecurringDraftInvoiceCreatedTitle =>
      'Borrador de factura recurrente creado';

  @override
  String notificationRecurringDraftInvoiceCreatedMessage(
      String clientName, String recurrenceName, String amount) {
    return 'Se ha creado un borrador de factura para $clientName a partir de la recurrencia \"$recurrenceName\" por $amount.';
  }

  @override
  String notificationRecurringDraftInvoiceCreatedMessageNoAmount(
      String clientName, String recurrenceName) {
    return 'Se ha creado un borrador de factura para $clientName a partir de la recurrencia \"$recurrenceName\".';
  }

  @override
  String get notificationRecurringDraftInvoiceCreatedMessageFallback =>
      'Se ha creado un borrador de factura recurrente.';
}
