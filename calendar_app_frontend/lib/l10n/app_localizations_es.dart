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
  String get verifyEmailInfo =>
      'Te enviamos un enlace de verificación. Ábrelo desde tu correo para completar la verificación.';

  @override
  String get verifyingEmail => 'Verificando tu correo...';

  @override
  String get verifyEmailTryAgain => 'Intentar de nuevo';

  @override
  String get resendVerificationButton => 'Reenviar verificación';

  @override
  String get resendVerificationSending => 'Enviando...';

  @override
  String get resendVerificationInvalidEmail =>
      'Ingresa un correo válido para reenviar.';

  @override
  String resendVerificationSent(String email) {
    return 'Correo de verificación enviado a $email';
  }

  @override
  String resendVerificationFailed(String error) {
    return 'No se pudo reenviar la verificación: $error';
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
  String get billingProfileTitle => 'Perfil de facturación';

  @override
  String get billingProfileEmpty =>
      'Añade los datos del emisor (razón social, CIF, dirección, IVA, IBAN) para emitir facturas.';

  @override
  String get billingWebsite => 'Sitio web';

  @override
  String get billingIban => 'IBAN';

  @override
  String get billingTaxRate => 'IVA';

  @override
  String get billingCurrency => 'Moneda';

  @override
  String get billingLanguage => 'Idioma';

  @override
  String get billingAddress => 'Dirección';

  @override
  String get billingProfileSaved => 'Perfil de facturación guardado';

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
  String get clientsTitle => 'Clientes';

  @override
  String get selectClientFirst =>
      'Selecciona un cliente para ver facturación e invoices';
}
